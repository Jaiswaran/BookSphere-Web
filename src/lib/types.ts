export type Role = "READER" | "AUTHOR";
export type BookStatus = "DRAFT" | "UPLOADING" | "PUBLISHED" | "FAILED" | "ARCHIVED";

export interface Profile {
  id: string;
  email: string | null;
  name: string | null;
  role: Role;
  bio: string | null;
  photo_url: string | null;
  created_at?: string;
}

export interface Book {
  id: string;
  author_id: string;
  title: string;
  author_name: string;
  description: string;
  genre: string;
  language: string;
  price: number;
  is_free: boolean;
  total_pages: number;
  preview_pages: number;
  cover_path: string | null;
  manuscript_path: string | null;
  preview_path: string | null;
  status: BookStatus;
  copies_sold: number;
  rating: number;
  created_at?: string;
}

export interface LibraryEntry {
  id: string;
  book_id: string;
  progress: number;
  last_page: number;
  completed: boolean;
  book: Book;
}
