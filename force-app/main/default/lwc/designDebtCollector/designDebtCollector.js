import { LightningElement, track } from 'lwc';
import runAnalysis from '@salesforce/apex/DDC_AnalyzerService.runAnalysis';

export default class DesignDebtCollector extends LightningElement {
    @track results;
    @track error;
    running = false;

    get noResults() {
        return !this.results;
    }

    get hasFindings() {
        return this.results && this.results.findings && this.results.findings.length > 0;
    }

    async handleRun() {
        this.running = true;
        this.error = undefined;
        this.results = undefined;

        try {
            const res = await runAnalysis();
            this.results = res;
        } catch (e) {
            this.error = this.normalizeError(e);
        } finally {
            this.running = false;
        }
    }

    exportJson() {
        const payload = JSON.stringify(this.results, null, 2);
        this.download('design-debt-collector-export.json', payload, 'application/json');
    }

    exportCsv() {
        const rows = [];
        rows.push(['type','severity','category','title','target','detail'].join(','));
        for (const f of (this.results.findings || [])) {
            rows.push(this.csvRow(['finding', f.severity, f.category, f.title, f.target, f.detail]));
        }
        rows.push('');
        rows.push(['type','order','risk','title','rationale','actions'].join(','));
        for (const p of (this.results.plan || [])) {
            rows.push(this.csvRow(['plan', p.order, p.risk, p.title, p.rationale, (p.actions || []).join(' | ')]));
        }
        this.download('design-debt-collector-export.csv', rows.join('\n'), 'text/csv');
    }

    download(filename, content, mime) {
        const element = document.createElement('a');
        element.setAttribute('href', 'data:' + mime + ';charset=utf-8,' + encodeURIComponent(content));
        element.setAttribute('download', filename);
        element.style.display = 'none';
        document.body.appendChild(element);
        element.click();
        document.body.removeChild(element);
    }

    csvRow(cols) {
        return cols.map(v => {
            const s = (v === null || v === undefined) ? '' : String(v);
            const escaped = s.replace(/"/g, '""');
            return '"' + escaped + '"';
        }).join(',');
    }

    normalizeError(e) {
        if (!e) return 'Unknown error';
        if (typeof e === 'string') return e;
        if (e.body && e.body.message) return e.body.message;
        if (e.message) return e.message;
        return JSON.stringify(e);
    }
}
