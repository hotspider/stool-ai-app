export type AnalyzeResponse = {
  riskLevel: "low" | "medium" | "high";
  summary: string;
  bristolType: number;
  color: "brown" | "yellow" | "green" | "black" | "red" | "pale" | "mixed" | "unknown";
  texture: "watery" | "mushy" | "normal" | "hard" | "oily" | "foamy" | "unknown";
  suspiciousSignals: string[];
  qualityScore: number;
  qualityIssues: string[];
  analyzedAt: string;
};

export type AdviceResponse = {
  summary: string;
  next48hActions: string[];
  seekCareIf: string[];
  disclaimers: string[];
};

export type ValidateImageResponse = {
  is_stool: boolean;
  confidence: number;
  reason: string;
};
