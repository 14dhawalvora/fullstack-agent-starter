// Mirrors backend DTOs. Keep in sync with docs/API.md.

export interface Message {
  id: number;
  content: string;
  createdAt: string; // ISO-8601
}
