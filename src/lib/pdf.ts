import { PDFDocument } from "pdf-lib";
import * as pdfjsLib from "pdfjs-dist";

pdfjsLib.GlobalWorkerOptions.workerSrc = new URL(
  "pdfjs-dist/build/pdf.worker.mjs",
  import.meta.url
).toString();

export async function getPdfPageCount(file: Blob): Promise<number> {
  const bytes = await file.arrayBuffer();
  const pdf = await pdfjsLib.getDocument({ data: bytes }).promise;
  return pdf.numPages;
}

export async function createPreviewPdf(file: Blob, pageCount: number): Promise<Blob> {
  const source = await PDFDocument.load(await file.arrayBuffer());
  const count = Math.max(1, Math.min(pageCount, source.getPageCount()));
  const preview = await PDFDocument.create();
  const pages = await preview.copyPages(source, Array.from({ length: count }, (_, i) => i));
  pages.forEach(page => preview.addPage(page));
  const bytes = await preview.save();
  return new Blob([bytes as BlobPart], { type: "application/pdf" });
}

export async function renderPdfPage(
  source: Blob | ArrayBuffer,
  pageNumber: number,
  canvas: HTMLCanvasElement,
  scale = 1.35
) {
  const data = source instanceof Blob ? await source.arrayBuffer() : source;
  const pdf = await pdfjsLib.getDocument({ data }).promise;
  if (pageNumber < 1 || pageNumber > pdf.numPages) {
    throw new Error(`Page ${pageNumber} is outside the document range 1-${pdf.numPages}.`);
  }
  const page = await pdf.getPage(pageNumber);
  const viewport = page.getViewport({ scale });
  canvas.width = viewport.width;
  canvas.height = viewport.height;
  await page.render({ canvasContext: canvas.getContext("2d")!, viewport }).promise;
  return pdf.numPages;
}
