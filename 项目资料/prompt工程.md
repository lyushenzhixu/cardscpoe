# 球星卡识别 App — Prompt 工程完整手册

---

## 一、Prompt 体系总览

```
整个 App 需要的 Prompt 矩阵：

┌─────────────────────────────────────────────────────────┐
│                    Prompt 体系架构                        │
│                                                         │
│  Layer 1: 核心识别 Prompts                               │
│  ├── P1: 主识别 Prompt（图片 + OCR → 卡牌身份）            │
│  ├── P2: 平行版判断 Prompt（已知卡牌 → 哪个平行版）         │
│  ├── P3: OCR 结果结构化 Prompt（原始文字 → 结构化字段）     │
│  └── P4: 候选结果裁判 Prompt（多路候选 → 最终判定）         │
│                                                         │
│  Layer 2: 品相评估 Prompts                               │
│  ├── P5: 整体品相评估 Prompt                              │
│  ├── P6: 表面瑕疵检测 Prompt                              │
│  └── P7: PSA/BGS 等级预测 Prompt                         │
│                                                         │
│  Layer 3: 增值功能 Prompts                               │
│  ├── P8: 假卡鉴别 Prompt                                 │
│  ├── P9: 价格分析 & 投资建议 Prompt                       │
│  ├── P10: 卡牌百科生成 Prompt                             │
│  └── P11: 交易贴文案生成 Prompt                           │
│                                                         │
│  Layer 4: 兜底 & 交互 Prompts                            │
│  ├── P12: 低置信度追问 Prompt                             │
│  ├── P13: 无法识别兜底 Prompt                             │
│  └── P14: 多卡图片处理 Prompt                             │
└─────────────────────────────────────────────────────────┘
```

---

## 二、核心设计原则

```
Prompt 工程的 7 条铁律（球星卡场景专用）：

1. 🎯 结构化输出至上
   → 所有 Prompt 强制 JSON 输出
   → 字段名固定、类型固定
   → 下游代码才能可靠解析

2. 🔗 先描述再判断 (Chain-of-Thought)
   → 让模型先描述它看到了什么视觉特征
   → 再基于描述做出判断
   → 可以追溯错误原因，也更准确

3. 📋 提供候选范围
   → 不要让模型从"全世界所有卡牌"中猜
   → 先用 OCR + 数据库缩小范围，把候选列表给模型
   → 从500万选1 → 从20个选1

4. ⚠️ 强制表达不确定性
   → 必须输出 confidence 字段
   → 不确定时必须说"不确定"
   → 宁可返回 null 也不要编造

5. 🚫 防幻觉设计
   → 明确告诉模型"如果不确定就说不确定"
   → 提供"已知合法值"列表约束输出
   → 后处理验证模型输出是否在合法范围内

6. 📝 Few-shot 示例不可少
   → 至少提供 2-3 个完整的输入→输出示例
   → 示例覆盖常见case和边缘case

7. 🔄 版本化管理
   → 每个 Prompt 有版本号
   → A/B 测试不同版本
   → 记录每次修改的效果变化
```

---

## 三、Layer 1：核心识别 Prompts

### P1：主识别 Prompt（最重要⭐⭐⭐⭐⭐）

这是整个系统的核心 Prompt，负责综合多路信号给出最终识别结果。

```python
CARD_IDENTIFICATION_SYSTEM_PROMPT = """You are an elite sports trading card expert and authenticator with 20+ years of experience. You specialize in identifying cards from Panini, Topps, Upper Deck, and all major brands across NBA, NFL, MLB, and Soccer.

## YOUR TASK
Identify the exact card shown in the user's photo by combining:
1. The image itself (visual analysis)
2. OCR-extracted text (provided below)  
3. Database candidate matches (provided below)

## CRITICAL RULES
- You MUST identify the card down to the EXACT VARIANT/PARALLEL level
- If you cannot determine the parallel with certainty, set parallel to null and explain why
- NEVER fabricate card numbers, print runs, or parallel names that don't exist
- If the image is too blurry/dark/unclear, say so honestly
- Confidence MUST genuinely reflect your certainty (don't inflate it)

## IDENTIFICATION PROCESS (follow this step by step)
Step 1: Describe what you physically see on the card (colors, layout, design elements, textures, reflections)
Step 2: Read and interpret any visible text on the card
Step 3: Cross-reference with the OCR data and database candidates provided
Step 4: Determine the exact card identity
Step 5: Assess the parallel/variant based on visual characteristics (border color, background texture, refractor pattern, surface finish)

## PARALLEL IDENTIFICATION GUIDE
Pay special attention to these visual cues for parallel identification:
- **Base**: Standard design, no special effects
- **Silver Prizm**: Rainbow/prismatic refractor pattern across the entire card surface
- **Gold /10**: Gold-colored borders or gold tinting
- **Red /299**: Red-colored borders or red background elements  
- **Blue /199**: Blue-colored borders or blue background elements
- **Green**: Green-colored borders or green background elements
- **Pink Pulsar**: Pink/magenta pulsating wave pattern
- **Mojo**: Circular/swirl refractor pattern (differs from Silver's linear pattern)
- **Camo**: Camouflage-like fragmented pattern
- **Black 1/1**: Black borders, very dark overall appearance
- **Red White Blue**: Tri-color pattern with red, white, and blue elements
- **Hyper**: Extra glossy/chrome-like finish
- Note: These vary by product line. A "Silver" in Prizm looks different from a "Silver" in Select.

## OUTPUT FORMAT
Return ONLY a valid JSON object with this exact structure:
"""

CARD_IDENTIFICATION_USER_TEMPLATE = """## IMAGE
[The card photo is attached]

## OCR EXTRACTED TEXT
The following text was extracted from the card image via OCR:
```
Top area: {ocr_top}
Center area: {ocr_center}  
Bottom area: {ocr_bottom}
Back (if available): {ocr_back}
```

## DATABASE CANDIDATE MATCHES
Based on OCR text matching, these are the top candidates from our database:
{candidates_json}

## KNOWN PARALLEL OPTIONS FOR THIS PRODUCT
If the card matches a known product, these are the valid parallel variants:
{parallel_options_json}

Now identify this card. Think step by step, then output the final JSON result.

Return your response in this EXACT JSON format:
{{
    "visual_description": "Describe exactly what you see on the card - colors, textures, reflections, design elements",
    "text_visible": "List all text you can read directly from the image",
    
    "identification": {{
        "player_name": "Full player name",
        "brand": "Panini | Topps | Upper Deck | other",
        "product_line": "Prizm | Select | Mosaic | etc.",
        "year": "2023-24",
        "set_name": "Base | Rookie | Insert name | etc.",
        "card_number": "#1 or #RS-1 format",
        "parallel": "Silver | Gold | Base | etc. or null if uncertain",
        "print_run": null or number (e.g., 10, 25, 99, 299),
        "is_numbered": true/false,
        "is_autograph": true/false,
        "is_memorabilia": true/false,
        "is_rookie_card": true/false,
        "sport": "basketball | football | baseball | soccer"
    }},

    "confidence": {{
        "overall": 0.0 to 1.0,
        "player": 0.0 to 1.0,
        "product": 0.0 to 1.0,
        "parallel": 0.0 to 1.0,
        "reasoning": "Brief explanation of confidence level"
    }},

    "matched_candidate_id": "ID from the candidate list if matched, otherwise null",
    
    "needs_more_info": {{
        "needed": true/false,
        "what": "e.g., 'back of card photo needed to confirm print run' or null",
        "why": "explanation or null"
    }}
}}"""
```

**调用示例：**

```python
import json
import openai

class CardIdentifier:
    
    def __init__(self):
        self.model = "gpt-4o"
        self.system_prompt = CARD_IDENTIFICATION_SYSTEM_PROMPT
    
    def identify(self, image_base64: str, ocr_results: dict, 
                 db_candidates: list, parallel_options: list) -> dict:
        
        # 构建用户消息
        user_text = CARD_IDENTIFICATION_USER_TEMPLATE.format(
            ocr_top=" | ".join(ocr_results.get("top_area", ["(none)"])),
            ocr_center=" | ".join(ocr_results.get("center_area", ["(none)"])),
            ocr_bottom=" | ".join(ocr_results.get("bottom_area", ["(none)"])),
            ocr_back=" | ".join(ocr_results.get("back_area", ["(not provided)"])),
            candidates_json=json.dumps(db_candidates[:10], indent=2),
            parallel_options_json=json.dumps(parallel_options, indent=2),
        )
        
        response = openai.ChatCompletion.create(
            model=self.model,
            messages=[
                {"role": "system", "content": self.system_prompt},
                {"role": "user", "content": [
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:image/jpeg;base64,{image_base64}",
                            "detail": "high"  # 高分辨率模式，关键！
                        }
                    },
                    {"type": "text", "text": user_text}
                ]}
            ],
            response_format={"type": "json_object"},
            temperature=0.1,     # 极低温度保证一致性
            max_tokens=1200,
            top_p=0.95,
        )
        
        result = json.loads(response.choices[0].message.content)
        
        # 后处理验证
        result = self.post_validate(result, db_candidates, parallel_options)
        
        return result
    
    def post_validate(self, result: dict, candidates: list, parallels: list) -> dict:
        """后处理：验证 LLM 输出的合法性"""
        
        identification = result.get("identification", {})
        
        # 1. 验证平行版是否在合法列表中
        if identification.get("parallel"):
            valid_parallels = [p["name"] for p in parallels]
            if identification["parallel"] not in valid_parallels:
                # LLM 幻觉了一个不存在的平行版
                best_match = fuzzy_match(identification["parallel"], valid_parallels)
                if best_match and best_match["score"] > 80:
                    identification["parallel"] = best_match["name"]
                else:
                    identification["parallel"] = None
                    result["confidence"]["parallel"] = 0.3
                    result["confidence"]["reasoning"] += " [Parallel auto-corrected: original value not in valid list]"
        
        # 2. 验证年份格式
        year = identification.get("year", "")
        if year and not re.match(r'^\d{4}(-\d{2})?$', year):
            identification["year"] = normalize_year(year)
        
        # 3. 验证 print_run 合理性
        if identification.get("print_run"):
            if identification["print_run"] > 1000 or identification["print_run"] < 1:
                identification["print_run"] = None
                identification["is_numbered"] = False
        
        result["identification"] = identification
        return result
```

---

### P2：平行版专项判断 Prompt

当 P1 的 parallel confidence < 0.7 时，触发这个专项 Prompt 做二次判断。

```python
PARALLEL_IDENTIFICATION_PROMPT = """You are a sports card parallel/variant identification specialist.

## CONTEXT
The card has already been identified as:
- Player: {player_name}
- Product: {year} {brand} {product_line}
- Card Number: {card_number}
- Set: {set_name}

Your ONLY job is to determine which parallel/variant this specific card is.

## AVAILABLE PARALLELS FOR THIS PRODUCT
The following are ALL valid parallel options (with their visual characteristics):
{parallel_details_json}

## VISUAL ANALYSIS CHECKLIST
Examine the card image carefully and answer each question:

1. **Border Color**: What color are the borders of the card? (silver, gold, red, blue, green, black, standard/white, other)
2. **Background Effect**: Is there a special background pattern? (prismatic/rainbow, swirl/mojo, camo, pulsar wave, none)
3. **Surface Finish**: How does the card surface appear? (matte, glossy, chrome/mirror-like, holographic)
4. **Refractor Pattern**: Is there a refractor/prizm pattern visible? (linear rainbow, circular, fragmented, none)
5. **Overall Tint**: Does the card have an overall color tint? (yes - what color, no)
6. **Numbering Visible**: Can you see a hand-written or stamped number like "XX/25" or "XX/99"? (yes - what, no)
7. **Special Markers**: Any special text like "MOJO", "CAMO", "HYPER" printed on the card?

## OUTPUT FORMAT
{{
    "visual_checklist": {{
        "border_color": "description",
        "background_effect": "description", 
        "surface_finish": "description",
        "refractor_pattern": "description",
        "overall_tint": "description",
        "numbering_visible": "description",
        "special_markers": "description"
    }},
    "analysis": "Based on the visual checklist, this card's characteristics match [X] because...",
    "parallel_determination": {{
        "primary_choice": "parallel name from the valid list",
        "primary_confidence": 0.0-1.0,
        "secondary_choice": "second most likely parallel or null",
        "secondary_confidence": 0.0-1.0
    }},
    "limitation_note": "Any reason you might be wrong (e.g., 'photo angle makes it hard to see refractor pattern')"
}}"""
```

**为什么需要单独的平行版 Prompt：**
```
1. P1 是综合识别，注意力分散在球员/品牌/年份等多个字段
2. 平行版是最容易出错的环节，需要集中全部注意力
3. 单独 Prompt 可以提供更详细的平行版视觉指南
4. Checklist 式提问迫使模型逐项检查视觉特征
5. 提供 primary + secondary 选择，应对不确定情况
```

---

### P3：OCR 结果结构化 Prompt

原始 OCR 文字往往是混乱的，需要 LLM 结构化。

```python
OCR_STRUCTURING_PROMPT = """You are an OCR post-processor specialized in sports trading cards.

## TASK
The following raw text was extracted from a sports card via OCR. The text may contain:
- Recognition errors (0 vs O, 1 vs I, 5 vs S, etc.)
- Fragmented or out-of-order text
- Decorative/artistic fonts that confused the OCR
- Text from both front and back of the card

Your job: Extract and structure the card information from this messy text.

## RAW OCR OUTPUT
Position-tagged text blocks from the card:
```
{raw_ocr_text}
```

## EXTRACTION RULES
1. Player names: Fix obvious OCR errors. "VICTAR WENBANYAMA" → "Victor Wembanyama"
2. Years: Normalize to "YYYY-YY" format. "23-24" → "2023-24", "2024" → "2023-24" (basketball season)
3. Card numbers: Look for patterns like #XX, No.XX, #XX-XX. Keep the prefix letters (RS, AU, etc.)
4. Brand clues: Look for "PANINI", "TOPPS", "PRIZM", "SELECT", etc.
5. Team names: Fix abbreviations and OCR errors
6. If text is too garbled to interpret, mark as null with low confidence

## OUTPUT FORMAT
{{
    "player_name": {{
        "value": "Corrected full name or null",
        "raw": "Original OCR text that was interpreted",
        "confidence": 0.0-1.0
    }},
    "year": {{
        "value": "YYYY-YY format or null",
        "raw": "Original OCR text",
        "confidence": 0.0-1.0
    }},
    "brand": {{
        "value": "Brand name or null",
        "raw": "Original OCR text",  
        "confidence": 0.0-1.0
    }},
    "product_line": {{
        "value": "Product line name or null",
        "raw": "Original OCR text",
        "confidence": 0.0-1.0
    }},
    "card_number": {{
        "value": "Normalized card number or null",
        "raw": "Original OCR text",
        "confidence": 0.0-1.0
    }},
    "team": {{
        "value": "Team name or null",
        "raw": "Original OCR text",
        "confidence": 0.0-1.0
    }},
    "set_name": {{
        "value": "Set/subset name or null",
        "raw": "Original OCR text",
        "confidence": 0.0-1.0
    }},
    "additional_text": ["any other notable text found on the card"],
    "print_number": {{
        "value": "e.g., '15/25' or null",
        "raw": "Original text",
        "confidence": 0.0-1.0
    }}
}}"""

# 注意：这个 Prompt 使用 gpt-4o-mini 即可，不需要图片输入
# 成本更低，速度更快
```

---

### P4：多路候选裁判 Prompt

当多路信号（OCR匹配、向量检索、视觉识别）给出不同候选时，用这个 Prompt 做最终裁判。

```python
CANDIDATE_JUDGE_PROMPT = """You are a senior card authentication judge making a final identification decision.

## SITUATION
Three different identification methods have produced different candidate results for the same card. You must determine which is correct (or if none are correct).

## METHOD RESULTS

### Method A: OCR + Database Match
Matched based on text extracted from the card:
{ocr_candidates_json}

### Method B: Visual Similarity Search  
Matched based on image feature similarity:
{visual_candidates_json}

### Method C: Direct Visual Recognition (your own analysis of the image)
You are also looking at the card image directly.

## DECISION RULES
1. If all three methods agree → HIGH confidence, go with the consensus
2. If two methods agree and one disagrees → MEDIUM-HIGH confidence, go with the majority, note the disagreement
3. If all three disagree → LOW confidence, rely most on your own visual analysis, but flag uncertainty
4. OCR-based matching is most reliable for player name, year, card number
5. Visual similarity is most reliable for product line and parallel identification
6. Your direct analysis is the tiebreaker

## SPECIAL ATTENTION
- OCR can misread text but the DATABASE it matches against is reliable
- Visual similarity can match wrong cards that just LOOK similar
- Your own analysis can hallucinate details — be honest about what you can/cannot see

## OUTPUT FORMAT
{{
    "decision": {{
        "chosen_method": "A | B | C | combined",
        "card_identity": {{
            "player_name": "...",
            "brand": "...",
            "product_line": "...",
            "year": "...",
            "card_number": "...",
            "parallel": "... or null",
            "set_name": "..."
        }},
        "confidence": 0.0-1.0
    }},
    "reasoning": {{
        "agreement_level": "full | partial | none",
        "method_a_assessment": "Why OCR result is trusted/not trusted",
        "method_b_assessment": "Why visual search result is trusted/not trusted",  
        "method_c_assessment": "What you see directly in the image",
        "conflicts_resolved": "How you resolved any disagreements"
    }},
    "risk_factors": ["list any reasons the identification might be wrong"]
}}"""
```

---

## 四、Layer 2：品相评估 Prompts

### P5：整体品相评估 Prompt

```python
CONDITION_ASSESSMENT_PROMPT = """You are a professional sports card grader with expertise equivalent to a PSA/BGS senior grader. You have examined over 100,000 cards in your career.

## TASK
Evaluate the physical condition of this card based on the photo provided. Assess each of the four standard grading criteria.

## IMPORTANT LIMITATIONS
- You are working from a PHOTO, not holding the physical card
- Lighting, camera quality, and angle will affect your assessment
- Always note when a photo limitation prevents accurate evaluation
- Your assessment is an ESTIMATE, not a certified grade

## GRADING CRITERIA (PSA Standard)

### 1. CENTERING
- Measure the border widths: left vs right, top vs bottom (front), and back centering
- PSA 10: 60/40 or better on front, 75/25 or better on back
- PSA 9: 65/35 or better on front, 90/10 or better on back
- PSA 8: 70/30 or better on front, 90/10 or better on back

### 2. CORNERS
- Examine all four corners at the highest zoom level possible
- Look for: fuzzy corners, dings, bends, whitening, rounding
- PSA 10: All four corners must be sharp and clean
- PSA 9: One corner may have a very minor imperfection
- PSA 8: Minor corner wear on 1-2 corners

### 3. EDGES
- Examine all four edges
- Look for: chipping, rough cuts, whitening, nicks, dents
- PSA 10: Pristine edges with no imperfections
- PSA 9: Very minor edge wear may be present
- PSA 8: Minor edge wear visible

### 4. SURFACE
- Examine the card surface for any defects
- Look for: scratches, print defects, staining, fingerprints, wax marks, dents/indentations
- PSA 10: No surface defects visible under magnification
- PSA 9: One very minor surface flaw
- PSA 8: Minor surface wear or one moderate flaw

## PROVIDE HIGH-RESOLUTION ANALYSIS
For each criterion, I want you to describe EXACTLY what you observe, like a grader writing notes.

## OUTPUT FORMAT
{{
    "photo_quality_assessment": {{
        "sufficient_for_grading": true/false,
        "limitations": ["list any photo issues that affect your assessment"],
        "recommendation": "e.g., 'Retake with better lighting for more accurate assessment'"
    }},
    
    "centering": {{
        "front_left_right": "estimated ratio, e.g., '55/45'",
        "front_top_bottom": "estimated ratio, e.g., '60/40'",
        "back_assessment": "if back photo provided, otherwise 'not available'",
        "observations": "Detailed description of centering",
        "sub_grade": 9.5,
        "confidence": 0.0-1.0
    }},
    
    "corners": {{
        "top_left": "sharp/minor wear/moderate wear/heavy wear + description",
        "top_right": "same format",
        "bottom_left": "same format",
        "bottom_right": "same format",
        "observations": "Overall corner assessment",
        "sub_grade": 9.0,
        "confidence": 0.0-1.0
    }},
    
    "edges": {{
        "top": "clean/minor wear/chipping + description",
        "bottom": "same format",
        "left": "same format",
        "right": "same format",
        "observations": "Overall edge assessment",
        "sub_grade": 9.0,
        "confidence": 0.0-1.0
    }},
    
    "surface": {{
        "scratches": "none/minor/moderate/heavy + description",
        "print_quality": "excellent/good/fair/poor + description",
        "staining": "none/minor/moderate + description",
        "other_defects": "description or 'none observed'",
        "observations": "Overall surface assessment",
        "sub_grade": 9.5,
        "confidence": 0.0-1.0
    }},
    
    "overall": {{
        "predicted_psa_grade": "PSA 9",
        "predicted_grade_numeric": 9.0,
        "grade_range": "PSA 8.5 - PSA 9.5",
        "key_factors": "What's most affecting the grade",
        "overall_confidence": 0.0-1.0,
        "disclaimer": "This is an AI estimate based on photos and should not replace professional grading."
    }}
}}"""
```

**关键设计要点：**
```
1. 明确告知"照片评估"的局限性 → 降低用户不合理预期
2. 提供具体的 PSA 标准 → 让模型有参考基准而非凭空猜测
3. 要求描述"看到了什么"而非直接给分 → Chain-of-Thought
4. 给出 grade_range 而非单一分数 → 更诚实
5. 强制 disclaimer → 法律保护
```

---

## 五、Layer 3：增值功能 Prompts

### P8：假卡鉴别 Prompt

```python
FAKE_DETECTION_PROMPT = """You are a sports card fraud detection expert. You investigate counterfeit, trimmed, and altered cards.

## TASK
Examine this card photo for signs of being:
1. **Counterfeit** (completely fake, reprinted)
2. **Trimmed** (edges cut to improve centering/remove damage)  
3. **Altered** (color altered, autograph added, patch swapped)
4. **Re-colored/Re-backed** (back replaced or colors chemically altered)

## KNOWN CARD IDENTITY
This card is claimed to be: {card_identity_json}

## REFERENCE INFORMATION
Authentic characteristics for this card:
- Expected dimensions: 2.5" × 3.5" (standard) 
- Known print patterns: {reference_print_info}
- Expected card stock: {reference_stock_info}
- Known security features: {security_features}

## WHAT TO EXAMINE

### Counterfeit Signs:
- Print dot pattern (authentic cards use specific print methods; fakes often have visible dot matrix patterns)
- Color saturation (fakes are often over/under saturated)
- Card stock thickness (visible from edge-on photos)
- Font consistency (fake cards often have slightly wrong fonts)
- Logo quality (blurry or slightly off logos)
- Hologram/foil quality (fakes often have dull or wrong hologram patterns)
- Edge cut quality (factory cuts are extremely precise)

### Trimming Signs:
- Edges appear too clean/sharp compared to corners
- Card dimensions appear smaller than standard
- Border widths are suspiciously perfect/even
- Corner rounding doesn't match edge sharpness
- You can sometimes see slight angle inconsistencies

### Alteration Signs:
- Color bleeding or unnatural color boundaries
- Autograph ink inconsistencies (wrong pen type, placement)
- Patch/memorabilia looks added or replaced
- Surface texture inconsistencies under different lighting

## OUTPUT FORMAT
{{
    "overall_verdict": "AUTHENTIC | SUSPICIOUS | LIKELY_FAKE",
    "risk_score": 0.0-1.0 (0 = definitely authentic, 1 = definitely fake),
    
    "counterfeit_analysis": {{
        "risk": "low | medium | high",
        "findings": ["list of specific observations"],
        "red_flags": ["specific concerning elements"],
        "confidence": 0.0-1.0
    }},
    
    "trimming_analysis": {{
        "risk": "low | medium | high",
        "findings": ["list of specific observations"],
        "red_flags": ["specific concerning elements"],
        "confidence": 0.0-1.0
    }},
    
    "alteration_analysis": {{
        "risk": "low | medium | high",
        "findings": ["list of specific observations"],
        "red_flags": ["specific concerning elements"],
        "confidence": 0.0-1.0
    }},
    
    "photo_limitations": ["What couldn't be properly assessed from this photo"],
    
    "recommendation": "e.g., 'Card appears authentic' or 'Recommend professional authentication before purchase' or 'Several red flags detected - proceed with extreme caution'",
    
    "suggested_next_steps": ["e.g., 'Request edge-on photo', 'Compare with known authentic under UV light'"]
}}"""
```

---

### P9：价格分析 & 投资建议 Prompt

```python
PRICE_ANALYSIS_PROMPT = """You are a sports card market analyst and investment advisor.

## CARD IDENTIFIED
{card_identity_json}

## PRICE DATA
Recent sales history from eBay and auction houses:
{price_history_json}

## MARKET CONTEXT
- Player's current status: {player_status} (e.g., "Active - averaging 25 PPG this season")
- Recent news: {recent_news}
- Overall market trend: {market_trend}

## TASK
Provide a comprehensive price analysis and market outlook.

## OUTPUT FORMAT
{{
    "current_valuation": {{
        "raw_card": {{
            "low": 0.00,
            "mid": 0.00,
            "high": 0.00,
            "data_points": 0
        }},
        "psa_10": {{
            "low": 0.00,
            "mid": 0.00, 
            "high": 0.00,
            "data_points": 0
        }},
        "psa_9": {{
            "low": 0.00,
            "mid": 0.00,
            "high": 0.00,
            "data_points": 0
        }}
    }},
    
    "trend_analysis": {{
        "30_day_trend": "up X% | down X% | stable",
        "90_day_trend": "up X% | down X% | stable",
        "trend_explanation": "Why the price has moved this way"
    }},
    
    "market_factors": {{
        "positive": ["factors that could increase value"],
        "negative": ["factors that could decrease value"],
        "upcoming_catalysts": ["events that could impact price - playoffs, trades, etc."]
    }},
    
    "grading_roi": {{
        "should_grade": true/false,
        "reasoning": "Is it worth the $20-50 grading cost?",
        "estimated_grade_bump_value": "How much more a PSA 10 is worth vs raw"
    }},
    
    "comparable_cards": [
        {{
            "card_name": "Similar card for comparison",
            "price": 0.00,
            "relevance": "Why this comp matters"
        }}
    ],
    
    "summary": "2-3 sentence plain English summary for the user",
    "disclaimer": "Prices fluctuate. This analysis is informational only, not financial advice."
}}"""
```

---

### P11：交易贴文案生成 Prompt

```python
LISTING_GENERATOR_PROMPT = """You are an expert eBay/marketplace listing copywriter for sports cards.

## CARD INFORMATION
{card_identity_json}

## CONDITION ASSESSMENT
{condition_json}

## USER PREFERENCES
- Platform: {platform} (eBay / Facebook Marketplace / Reddit / Instagram)
- Tone: {tone} (professional / casual / hype)
- Include price suggestion: {include_price}

## TASK
Generate a ready-to-post listing for this card.

## RULES
- Be accurate — never overstate the condition
- Include all relevant keywords for searchability (SEO)
- Mention any notable attributes (rookie, numbered, auto, etc.)
- If platform is eBay, format for eBay title (max 80 chars) + description
- If platform is social media, format as a post with relevant hashtags

## OUTPUT FORMAT
{{
    "title": "Optimized listing title (max 80 chars for eBay)",
    "subtitle": "Optional subtitle",
    "description": "Full listing description (formatted with line breaks)",
    "hashtags": ["relevant", "hashtags", "for", "social"],
    "suggested_price": {{
        "buy_now": 0.00,
        "auction_start": 0.00,
        "reasoning": "Why this price"
    }},
    "seo_keywords": ["keywords for search visibility"],
    "shipping_suggestion": "PWE / BMWT / Priority recommendation"
}}"""
```

---

## 六、Layer 4：兜底 & 交互 Prompts

### P12：低置信度追问 Prompt

```python
FOLLOWUP_QUESTION_PROMPT = """You are helping a user identify their sports card. The initial identification was uncertain.

## INITIAL RESULT
{initial_result_json}

## UNCERTAINTY REASON
{uncertainty_reason}

## TASK
Generate a natural, helpful follow-up question to get the information needed for a more accurate identification.

## RULES
- Be specific about what you need (don't just say "send a better photo")
- Explain WHY you need it (so the user understands)
- Keep it conversational and friendly
- If you need a photo of the back, explain what to look for
- Suggest practical tips (e.g., "try tilting the card under a light to see the refractor pattern")

## COMMON FOLLOW-UP SCENARIOS

Scenario 1: Can't determine parallel
→ "I can see this is a {year} {product} {player} #{number}, but I'm having trouble determining the exact parallel version. Could you try tilting the card under a light at different angles? I'm looking for whether the surface has a rainbow/prismatic effect (Silver Prizm), a swirl pattern (Mojo), or no special effect (Base). A short video clip would be even more helpful!"

Scenario 2: Need back of card
→ "Great card! I've identified the front. Could you flip it over and take a photo of the back? I'm looking for: (1) any hand-written numbering like 'XX/25' which tells us the print run, and (2) the card back design which helps confirm the exact product line."

Scenario 3: OCR couldn't read text clearly
→ "The text on this card is a bit hard to read from the photo. Could you retake the photo with: (1) better lighting (natural daylight works best), (2) the card flat on a surface, and (3) focusing on the [top/bottom] where the [player name/card number] should be?"

## OUTPUT FORMAT
{{
    "follow_up_message": "The natural language message to show the user",
    "specific_request": "What exactly you need (photo of back / angled photo / better lighting / etc.)",
    "tips": ["Practical tips for the user"],
    "partial_result": {{
        "what_we_know": "Fields we've already identified",
        "what_we_need": "Fields that are still uncertain"
    }}
}}"""
```

### P13：无法识别兜底 Prompt

```python
FALLBACK_IDENTIFICATION_PROMPT = """You are a sports card expert looking at a card that couldn't be automatically identified by our database.

## CONTEXT
- Our OCR system extracted: {ocr_text}
- Our database search returned: NO MATCHES
- This means the card is likely: a rare/uncommon product, a very old card, a non-US card, or our database doesn't cover it yet

## TASK
Using ONLY what you can see in the image and your knowledge, provide your best identification attempt. Be especially careful about accuracy since we have no database confirmation.

## RULES
- Be honest about your confidence level
- Distinguish between what you can SEE vs what you're GUESSING
- If this looks like a custom/fan-made card, say so
- If you genuinely cannot identify it, that's OK — say so clearly

## OUTPUT FORMAT
{{
    "identification_attempt": {{
        "player_name": "name or null",
        "brand": "brand or null",
        "product_line": "product or null",
        "year": "year or null",
        "confidence": 0.0-1.0,
        "basis": "What visual evidence you're basing this on"
    }},
    "possible_reasons_not_in_db": [
        "e.g., 'This appears to be a regional release not in our database'",
        "e.g., 'This might be a promotional card or sample'"
    ],
    "user_message": "A helpful message explaining the situation and asking for their help",
    "request_user_input": {{
        "ask_for": ["What information to ask the user to provide manually"],
        "will_add_to_db": true
    }}
}}"""
```

### P14：多卡图片处理 Prompt

```python
MULTI_CARD_DETECTION_PROMPT = """You are examining a photo that may contain multiple sports cards.

## TASK  
1. Determine how many cards are visible in this image
2. For each card, describe its approximate position in the image
3. Indicate which card(s) are suitable for identification (clear enough, fully visible)

## OUTPUT FORMAT
{{
    "card_count": 3,
    "cards": [
        {{
            "position": "top-left",
            "bounding_box_estimate": {{"x_pct": 5, "y_pct": 5, "width_pct": 45, "height_pct": 45}},
            "visibility": "full | partial | obstructed",
            "quality": "good | fair | poor",
            "identifiable": true,
            "brief_description": "Basketball card, appears to be Prizm product"
        }},
        ...
    ],
    "recommendation": "e.g., 'I can identify 2 of the 3 cards. The third is partially covered.'"
}}"""
```

---

## 七、Prompt 优化技巧（实战经验）

### 7.1 温度参数策略

```python
TEMPERATURE_STRATEGY = {
    # 识别类 Prompt → 极低温度，要求一致性
    "P1_identification": 0.1,
    "P2_parallel": 0.1,
    "P3_ocr_structure": 0.05,   # OCR 结构化几乎是确定性任务
    "P4_judge": 0.15,
    
    # 评估类 Prompt → 低温度，但允许一点灵活性
    "P5_condition": 0.2,
    "P8_fake_detection": 0.15,
    
    # 生成类 Prompt → 中等温度，需要创造力
    "P9_price_analysis": 0.3,
    "P10_encyclopedia": 0.4,
    "P11_listing": 0.5,
    
    # 交互类 Prompt → 稍高温度，需要自然对话
    "P12_followup": 0.5,
    "P13_fallback": 0.4,
}
```

### 7.2 模型选择策略

```python
MODEL_STRATEGY = {
    # 需要看图 + 高精度 → GPT-4o（贵但准）
    "P1_identification": "gpt-4o",
    "P2_parallel": "gpt-4o",
    "P5_condition": "gpt-4o",
    "P8_fake_detection": "gpt-4o",
    
    # 纯文字处理 → GPT-4o-mini（便宜 20 倍）
    "P3_ocr_structure": "gpt-4o-mini",
    "P9_price_analysis": "gpt-4o-mini",
    "P10_encyclopedia": "gpt-4o-mini",
    "P11_listing": "gpt-4o-mini",
    "P12_followup": "gpt-4o-mini",
    
    # 多路裁判（需要看图）→ GPT-4o
    "P4_judge": "gpt-4o",
    
    # 兜底识别（需要看图）→ GPT-4o
    "P13_fallback": "gpt-4o",
    "P14_multi_card": "gpt-4o",
}

# 成本估算（每次识别）：
# 纯 GPT-4o 方案：~$0.03-0.05/次
# 混合方案：~$0.01-0.02/次
# 节省约 60%
```

### 7.3 image detail 参数

```python
# GPT-4o 的 image detail 参数对识别效果影响巨大

IMAGE_DETAIL_STRATEGY = {
    # 需要看清文字和细节 → high（消耗更多 token 但更准确）
    "P1_identification": "high",
    "P5_condition": "high",      # 品相评估必须高分辨率
    "P8_fake_detection": "high", # 假卡鉴别必须高分辨率
    
    # 只需要大致视觉特征 → low（节省 token）
    "P14_multi_card": "low",     # 只需要数有几张卡
    
    # 需要看清纹理/反光 → high
    "P2_parallel": "high",      # 平行版判断需要看清纹理
}

# "high" 模式下图片消耗约 1000-2000 tokens
# "low" 模式下图片消耗约 85 tokens
# 差异巨大！合理选择可以节省大量成本
```

### 7.4 Few-shot 示例库

```python
# 为核心 Prompt 维护 Few-shot 示例库
# 每个示例 = 一张真实卡牌的输入 + 正确输出

FEW_SHOT_EXAMPLES = {
    "P1_identification": [
        {
            "description": "Standard Prizm Base card",
            "ocr_input": {
                "top_area": ["PANINI PRIZM"],
                "center_area": ["VICTOR WEMBANYAMA"],
                "bottom_area": ["#RS-1", "SAN ANTONIO SPURS", "2023-24"]
            },
            "expected_output": {
                "identification": {
                    "player_name": "Victor Wembanyama",
                    "brand": "Panini",
                    "product_line": "Prizm",
                    "year": "2023-24",
                    "set_name": "Rookie Signatures",
                    "card_number": "#RS-1",
                    "parallel": "Base",
                    "print_run": None,
                    "is_rookie_card": True
                },
                "confidence": {"overall": 0.95}
            }
        },
        {
            "description": "Numbered Gold parallel - harder case",
            "ocr_input": {
                "top_area": ["SELECT"],
                "center_area": ["LUKA DONCIC"],
                "bottom_area": ["#55", "DALLAS MAVERICKS", "3/10"]
            },
            "expected_output": {
                "identification": {
                    "player_name": "Luka Doncic",  
                    "brand": "Panini",
                    "product_line": "Select",
                    "year": "2023-24",
                    "set_name": "Base",
                    "card_number": "#55",
                    "parallel": "Gold",
                    "print_run": 10,
                    "is_numbered": True,
                    "is_rookie_card": False
                },
                "confidence": {"overall": 0.88, "parallel": 0.75}
            }
        },
        {
            "description": "Unclear parallel - showing uncertainty",
            "ocr_input": {
                "top_area": ["PRIZM"],
                "center_area": ["JAYSON TATUM"],
                "bottom_area": ["#1"]
            },
            "expected_output": {
                "identification": {
                    "player_name": "Jayson Tatum",
                    "brand": "Panini",
                    "product_line": "Prizm",
                    "year": "2023-24",
                    "set_name": "Base",
                    "card_number": "#1",
                    "parallel": None,
                    "print_run": None
                },
                "confidence": {"overall": 0.7, "parallel": 0.3},
                "needs_more_info": {
                    "needed": True,
                    "what": "Angled photo to check for refractor pattern",
                    "why": "Cannot determine if Base or Silver from this angle"
                }
            }
        }
    ]
}

def build_few_shot_section(prompt_key: str, num_examples: int = 2) -> str:
    """构建 Few-shot 示例文本"""
    examples = FEW_SHOT_EXAMPLES.get(prompt_key, [])[:num_examples]
    
    if not examples:
        return ""
    
    section = "\n## EXAMPLES\nHere are examples of correct identifications:\n\n"
    
    for i, ex in enumerate(examples):
        section += f"### Example {i+1}: {ex['description']}\n"
        section += f"OCR Input: {json.dumps(ex['ocr_input'], indent=2)}\n"
        section += f"Correct Output: {json.dumps(ex['expected_output'], indent=2)}\n\n"
    
    return section
```

---

## 八、Prompt 版本管理 & A/B 测试

### 8.1 版本管理系统

```python
class PromptManager:
    """Prompt 版本管理器"""
    
    def __init__(self, db):
        self.db = db
    
    def get_prompt(self, prompt_key: str, version: str = "latest") -> dict:
        """获取指定版本的 Prompt"""
        
        if version == "latest":
            query = """
                SELECT * FROM prompt_versions 
                WHERE prompt_key = %s AND is_active = true
                ORDER BY version DESC LIMIT 1
            """
        else:
            query = """
                SELECT * FROM prompt_versions 
                WHERE prompt_key = %s AND version = %s
            """
        
        return self.db.fetchone(query, [prompt_key, version] if version != "latest" else [prompt_key])
    
    def get_ab_test_prompt(self, prompt_key: str, user_id: str) -> dict:
        """A/B 测试：根据用户 ID 分流"""
        
        # 获取当前活跃的 A/B 测试
        test = self.db.fetchone("""
            SELECT * FROM prompt_ab_tests
            WHERE prompt_key = %s AND status = 'active'
        """, [prompt_key])
        
        if not test:
            return self.get_prompt(prompt_key)
        
        # 根据用户 ID hash 分流
        bucket = hash(user_id) % 100
        
        if bucket < test["traffic_split"]:  # e.g., 50
            return self.get_prompt(prompt_key, test["version_a"])
        else:
            return self.get_prompt(prompt_key, test["version_b"])

# Prompt 版本表
"""
CREATE TABLE prompt_versions (
    id              SERIAL PRIMARY KEY,
    prompt_key      VARCHAR(50),         -- "P1_identification"
    version         VARCHAR(20),         -- "v1.0", "v1.1", "v2.0"
    system_prompt   TEXT,
    user_template   TEXT,
    model           VARCHAR(50),         -- "gpt-4o"
    temperature     DECIMAL(2,1),
    max_tokens      INT,
    is_active       BOOLEAN DEFAULT false,
    
    -- 性能指标
    avg_accuracy    DECIMAL(4,3),        -- 通过测试集衡量
    avg_latency_ms  INT,
    avg_cost_usd    DECIMAL(6,4),
    sample_size     INT,                 -- 测试样本量
    
    created_at      TIMESTAMP DEFAULT NOW(),
    notes           TEXT                 -- 改了什么、为什么改
);

CREATE TABLE prompt_ab_tests (
    id              SERIAL PRIMARY KEY,
    prompt_key      VARCHAR(50),
    version_a       VARCHAR(20),
    version_b       VARCHAR(20),
    traffic_split   INT DEFAULT 50,      -- version_a 的流量百分比
    status          VARCHAR(20),         -- active / completed / paused
    start_date      TIMESTAMP,
    end_date        TIMESTAMP,
    winner          VARCHAR(20)          -- 最终胜出版本
);
"""
```

### 8.2 评估测试集

```python
# 黄金测试集：用于评估每个 Prompt 版本的准确率

EVALUATION_TEST_SET = [
    {
        "id": "test_001",
        "image_path": "test_images/prizm_silver_wemby.jpg",
        "difficulty": "easy",
        "ground_truth": {
            "player_name": "Victor Wembanyama",
            "brand": "Panini",
            "product_line": "Prizm",
            "year": "2023-24",
            "card_number": "#RS-1",
            "parallel": "Silver",
            "is_rookie_card": True
        }
    },
    {
        "id": "test_002",
        "image_path": "test_images/select_gold_luka_numbered.jpg",
        "difficulty": "medium",
        "ground_truth": {
            "player_name": "Luka Doncic",
            "brand": "Panini",
            "product_line": "Select",
            "year": "2023-24",
            "card_number": "#55",
            "parallel": "Gold",
            "print_run": 10,
            "is_numbered": True
        }
    },
    {
        "id": "test_003",
        "image_path": "test_images/mosaic_red_camo_unclear.jpg",
        "difficulty": "hard",
        "ground_truth": {
            "player_name": "Anthony Edwards",
            "brand": "Panini",
            "product_line": "Mosaic",
            "year": "2023-24",
            "card_number": "#15",
            "parallel": "Red Camo"
        }
    },
    # ... 至少 100-200 个测试样本，覆盖不同难度、品牌、年份
]

def evaluate_prompt_version(prompt_key: str, version: str, test_set: list) -> dict:
    """评估 Prompt 版本在测试集上的表现"""
    
    prompt_config = prompt_manager.get_prompt(prompt_key, version)
    
    results = {
        "total": len(test_set),
        "correct_player": 0,
        "correct_product": 0,
        "correct_year": 0,
        "correct_card_number": 0,
        "correct_parallel": 0,
        "correct_all_fields": 0,  # 全部字段都对
        "avg_confidence": 0,
        "avg_latency_ms": 0,
        "total_cost_usd": 0,
        "errors": [],
    }
    
    for test_case in test_set:
        start_time = time.time()
        
        # 运行识别
        prediction = run_identification(
            image_path=test_case["image_path"],
            prompt_config=prompt_config
        )
        
        latency = (time.time() - start_time) * 1000
        results["avg_latency_ms"] += latency
        results["total_cost_usd"] += prediction.get("cost", 0)
        
        # 对比 ground truth
        gt = test_case["ground_truth"]
        pred = prediction.get("identification", {})
        
        field_checks = {
            "player": pred.get("player_name", "").lower() == gt.get("player_name", "").lower(),
            "product": pred.get("product_line", "").lower() == gt.get("product_line", "").lower(),
            "year": pred.get("year") == gt.get("year"),
            "card_number": normalize_card_number(pred.get("card_number")) == normalize_card_number(gt.get("card_number")),
            "parallel": (pred.get("parallel") or "").lower() == (gt.get("parallel") or "").lower(),
        }
        
        if field_checks["player"]: results["correct_player"] += 1
        if field_checks["product"]: results["correct_product"] += 1
        if field_checks["year"]: results["correct_year"] += 1
        if field_checks["card_number"]: results["correct_card_number"] += 1
        if field_checks["parallel"]: results["correct_parallel"] += 1
        if all(field_checks.values()): results["correct_all_fields"] += 1
        
        if not all(field_checks.values()):
            results["errors"].append({
                "test_id": test_case["id"],
                "difficulty": test_case["difficulty"],
                "expected": gt,
                "predicted": pred,
                "field_results": field_checks
            })
    
    # 计算最终指标
    n = results["total"]
    results["accuracy"] = {
        "player": results["correct_player"] / n,
        "product": results["correct_product"] / n,
        "year": results["correct_year"] / n,
        "card_number": results["correct_card_number"] / n,
        "parallel": results["correct_parallel"] / n,
        "all_fields": results["correct_all_fields"] / n,
    }
    results["avg_latency_ms"] /= n
    
    return results
```

---

## 九、Prompt 调优实战经验

### 9.1 常见失败模式与修复

```
❌ 失败模式 1：平行版幻觉
   症状：模型编造不存在的平行版名称（如 "Diamond Prizm"）
   原因：模型的训练数据中有混淆信息
   修复：
   ├── 在 Prompt 中提供 EXACT 合法平行版列表
   ├── 添加规则："ONLY use parallel names from the provided list"
   ├── 后处理验证：检查输出是否在合法列表中
   └── 效果：幻觉率从 15% → 2%

❌ 失败模式 2：年份张冠李戴
   症状：把 2022-23 的卡识别成 2023-24（因为设计类似）
   原因：不同年份的 Prizm 设计可能很相似
   修复：
   ├── 强调 OCR 提取的年份信息优先级最高
   ├── 添加规则："If OCR clearly shows a year, trust it over visual similarity"
   ├── 在候选列表中包含年份信息
   └── 效果：年份错误率从 8% → 1%

❌ 失败模式 3：高置信度但错误
   症状：模型输出 confidence: 0.95 但答案完全错误
   原因：模型对自信度的校准(calibration)很差
   修复：
   ├── 添加规则："Rate your confidence honestly. 
   │   0.9+ means you would bet money on it.
   │   0.7-0.9 means you're fairly sure but could be wrong.
   │   Below 0.7 means there's significant uncertainty."
   ├── Few-shot 示例中包含低置信度的案例
   ├── 后处理：如果多路信号不一致，强制降低 confidence
   └── 效果：过度自信率从 30% → 8%

❌ 失败模式 4：忽略 OCR 数据直接看图猜
   症状：OCR 明确提取出了卡号和年份，模型却给出不同答案
   原因：Prompt 中 OCR 数据的权重不够
   修复：
   ├── 在 Prompt 中显式说明优先级：
   │   "OCR text > Visual similarity candidates > Your visual analysis"
   ├── 添加规则："If OCR clearly reads '#RS-1', the card number IS #RS-1, 
   │   do not override this with your visual guess"
   └── 效果：OCR 覆盖率从 60% → 90%

❌ 失败模式 5：Base 和 Silver 混淆
   症状：最常见的平行版误判
   原因：在某些光照条件下 Base 卡可能看起来有反光
   修复：
   ├── 专项 Prompt P2 单独处理
   ├── 添加详细的视觉 Checklist
   ├── 规则："When in doubt between Base and Silver, look for 
   │   CONSISTENT prismatic pattern across the ENTIRE card surface. 
   │   Random reflections from photo flash ≠ Silver Prizm"
   ├── 置信度低时触发追问（P12）
   └── 效果：Base/Silver 混淆率从 25% → 8%
```

### 9.2 逐步优化记录模板

```markdown
## Prompt 优化日志

### 2024-XX-XX: P1 v1.0 → v1.1
**问题**: 平行版判断幻觉率 15%
**假设**: 缺少合法值列表约束
**修改**: 
  - 添加 "KNOWN PARALLEL OPTIONS" 部分
  - 添加规则 "ONLY choose from the provided list"
**结果**: 
  - 幻觉率: 15% → 5%
  - 整体准确率: 72% → 78%
  - 延迟变化: +100ms（Prompt 更长）
  - 成本变化: +$0.002/次
**结论**: ✅ 采纳，幻觉问题大幅改善

### 2024-XX-XX: P1 v1.1 → v1.2
**问题**: 年份误判率 8%
**假设**: 模型没有充分利用 OCR 数据
**修改**:
  - 增加 OCR 优先级声明
  - 添加 Few-shot 示例（OCR年份覆盖视觉判断）
**结果**:
  - 年份准确率: 92% → 99%
  - 其他字段无退化
**结论**: ✅ 采纳
```

---

## 十、完整调用 Pipeline 代码

```python
class CardRecognitionPipeline:
    """完整的卡牌识别 Pipeline"""
    
    def __init__(self):
        self.ocr_engine = PaddleOCR(lang='en')
        self.card_matcher = CardMatcher(db)
        self.prompt_manager = PromptManager(db)
        self.vector_search = VectorSearchEngine()
    
    async def identify_card(self, image: bytes, user_id: str) -> dict:
        """主识别流程"""
        
        # Step 0: 图像预处理
        processed_image = preprocess_card_image(image)
        image_base64 = encode_to_base64(processed_image)
        
        # Step 1: OCR 提取（并行执行）
        # Step 2: 向量检索（并行执行）
        ocr_task = asyncio.create_task(self.run_ocr(processed_image))
        vector_task = asyncio.create_task(self.run_vector_search(processed_image))
        
        ocr_raw = await ocr_task
        vector_candidates = await vector_task
        
        # Step 3: OCR 结构化（P3 Prompt，用 gpt-4o-mini）
        ocr_structured = await self.structure_ocr(ocr_raw)
        
        # Step 4: 数据库匹配
        db_candidates = self.card_matcher.match_from_ocr(ocr_structured)
        
        # 获取候选卡牌的平行版列表
        parallel_options = self.get_parallel_options(db_candidates)
        
        # Step 5: 主识别（P1 Prompt，用 gpt-4o）
        prompt_config = self.prompt_manager.get_ab_test_prompt("P1_identification", user_id)
        
        identification = await self.run_main_identification(
            image_base64=image_base64,
            ocr_structured=ocr_structured,
            db_candidates=db_candidates,
            vector_candidates=vector_candidates,
            parallel_options=parallel_options,
            prompt_config=prompt_config
        )
        
        # Step 6: 后处理验证
        identification = self.post_validate(identification, db_candidates, parallel_options)
        
        # Step 7: 置信度检查 → 决定是否追问
        if identification["confidence"]["overall"] < 0.7:
            # 低置信度 → 尝试平行版专项判断
            if identification["confidence"]["parallel"] < 0.5:
                parallel_result = await self.run_parallel_identification(
                    image_base64, identification
                )
                identification = self.merge_parallel_result(identification, parallel_result)
        
        # Step 8: 如果还是不确定，走裁判 Prompt
        if identification["confidence"]["overall"] < 0.6:
            identification = await self.run_judge(
                image_base64, ocr_structured, db_candidates, 
                vector_candidates, identification
            )
        
        # Step 9: 匹配数据库获取价格
        if identification.get("matched_candidate_id"):
            price_data = self.get_price_data(identification["matched_candidate_id"])
            identification["price_data"] = price_data
        
        # Step 10: 记录结果用于后续优化
        await self.log_identification(user_id, image_base64, identification)
        
        return identification
    
    async def structure_ocr(self, ocr_raw: dict) -> dict:
        """OCR 结构化 (P3, gpt-4o-mini)"""
        
        response = await openai.ChatCompletion.acreate(
            model="gpt-4o-mini",  # 便宜！
            messages=[
                {"role": "system", "content": OCR_STRUCTURING_PROMPT},
                {"role": "user", "content": format_ocr_for_prompt(ocr_raw)}
            ],
            response_format={"type": "json_object"},
            temperature=0.05,
            max_tokens=500,
        )
        
        return json.loads(response.choices[0].message.content)
    
    async def run_main_identification(self, image_base64, ocr_structured,
                                       db_candidates, vector_candidates,
                                       parallel_options, prompt_config) -> dict:
        """主识别 (P1, gpt-4o)"""
        
        user_message = CARD_IDENTIFICATION_USER_TEMPLATE.format(
            ocr_top=ocr_structured.get("top_text", "(none)"),
            ocr_center=ocr_structured.get("center_text", "(none)"),
            ocr_bottom=ocr_structured.get("bottom_text", "(none)"),
            ocr_back=ocr_structured.get("back_text", "(not available)"),
            candidates_json=json.dumps(self.format_candidates(db_candidates[:10]), indent=2),
            parallel_options_json=json.dumps(parallel_options, indent=2),
        )
        
        # 添加 Few-shot 示例
        few_shot = build_few_shot_section("P1_identification", num_examples=2)
        system_prompt = prompt_config["system_prompt"] + few_shot
        
        response = await openai.ChatCompletion.acreate(
            model=prompt_config.get("model", "gpt-4o"),
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": [
                    {"type": "image_url", "image_url": {
                        "url": f"data:image/jpeg;base64,{image_base64}",
                        "detail": "high"
                    }},
                    {"type": "text", "text": user_message}
                ]}
            ],
            response_format={"type": "json_object"},
            temperature=prompt_config.get("temperature", 0.1),
            max_tokens=prompt_config.get("max_tokens", 1200),
        )
        
        return json.loads(response.choices[0].message.content)
    
    async def run_parallel_identification(self, image_base64, current_result) -> dict:
        """平行版专项判断 (P2, gpt-4o)"""
        
        ident = current_result["identification"]
        parallel_details = self.get_detailed_parallel_info(
            ident["brand"], ident["product_line"], ident["year"]
        )
        
        prompt = PARALLEL_IDENTIFICATION_PROMPT.format(
            player_name=ident["player_name"],
            year=ident["year"],
            brand=ident["brand"],
            product_line=ident["product_line"],
            card_number=ident["card_number"],
            set_name=ident["set_name"],
            parallel_details_json=json.dumps(parallel_details, indent=2)
        )
        
        response = await openai.ChatCompletion.acreate(
            model="gpt-4o",
            messages=[
                {"role": "system", "content": prompt},
                {"role": "user", "content": [
                    {"type": "image_url", "image_url": {
                        "url": f"data:image/jpeg;base64,{image_base64}",
                        "detail": "high"
                    }},
                    {"type": "text", "text": "Determine the parallel variant of this card."}
                ]}
            ],
            response_format={"type": "json_object"},
            temperature=0.1,
            max_tokens=800,
        )
        
        return json.loads(response.choices[0].message.content)
```

---

## 十一、成本估算

```
每次完整识别的 API 调用成本：

最佳路径（高置信度，占比约 60%）：
├── P3 OCR 结构化 (gpt-4o-mini): ~$0.001
├── P1 主识别 (gpt-4o, high detail): ~$0.02
└── 总计: ~$0.021

标准路径（需要平行版二次判断，占比约 25%）：
├── P3 OCR 结构化 (gpt-4o-mini): ~$0.001
├── P1 主识别 (gpt-4o): ~$0.02
├── P2 平行版判断 (gpt-4o): ~$0.02
└── 总计: ~$0.041

困难路径（需要裁判，占比约 15%）：
├── P3 OCR 结构化 (gpt-4o-mini): ~$0.001
├── P1 主识别 (gpt-4o): ~$0.02
├── P2 平行版判断 (gpt-4o): ~$0.02
├── P4 裁判 (gpt-4o): ~$0.025
└── 总计: ~$0.066

加权平均每次识别成本：
= 0.6 × $0.021 + 0.25 × $0.041 + 0.15 × $0.066
= $0.0126 + $0.01025 + $0.0099
= ~$0.032/次

月度成本（50,000 次识别/月）：
= 50,000 × $0.032 = ~$1,600/月 (纯 LLM API 成本)
```