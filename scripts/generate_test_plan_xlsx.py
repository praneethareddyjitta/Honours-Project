#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
generate_test_plan_xlsx.py
Generates doc/SoC_UVM_Test_Plan.xlsx matching the reference format with 14 comprehensive sheets.
"""

import zipfile
import io
import os
import xml.sax.saxutils as saxutils

def escape(s):
    if s is None:
        return ""
    return saxutils.escape(str(s))

def col_name(col_idx):
    """Convert 1-based column index to Excel column string (e.g. 1->A, 2->B, 27->AA)"""
    result = ""
    while col_idx > 0:
        col_idx, remainder = divmod(col_idx - 1, 26)
        result = chr(65 + remainder) + result
    return result

class WorkbookBuilder:
    def __init__(self):
        self.sheets = [] # (name, rows)
        
    def add_sheet(self, name, rows):
        self.sheets.append((name, rows))

    def build_zip(self, filepath):
        buf = io.BytesIO()
        with zipfile.ZipFile(buf, 'w', zipfile.ZIP_DEFLATED) as z:
            # 1. [Content_Types].xml
            ct_lines = [
                '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
                '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">',
                '  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>',
                '  <Default Extension="xml" ContentType="application/xml"/>',
                '  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>',
                '  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
            ]
            for i in range(1, len(self.sheets) + 1):
                ct_lines.append(f'  <Override PartName="/xl/worksheets/sheet{i}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>')
            ct_lines.append('</Types>')
            z.writestr('[Content_Types].xml', '\n'.join(ct_lines))

            # 2. _rels/.rels
            z.writestr('_rels/.rels', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>''')

            # 3. xl/_rels/workbook.xml.rels
            wb_rels = [
                '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
                '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            ]
            for i in range(1, len(self.sheets) + 1):
                wb_rels.append(f'  <Relationship Id="rId{i}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet{i}.xml"/>')
            wb_rels.append(f'  <Relationship Id="rId{len(self.sheets)+1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>')
            wb_rels.append('</Relationships>')
            z.writestr('xl/_rels/workbook.xml.rels', '\n'.join(wb_rels))

            # 4. xl/workbook.xml
            wb_xml = [
                '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
                '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">',
                '  <sheets>'
            ]
            for i, (name, _) in enumerate(self.sheets, 1):
                wb_xml.append(f'    <sheet name="{escape(name)}" sheetId="{i}" r:id="rId{i}"/>')
            wb_xml.append('  </sheets>')
            wb_xml.append('</workbook>')
            z.writestr('xl/workbook.xml', '\n'.join(wb_xml))

            # 5. xl/styles.xml (Simple styles)
            z.writestr('xl/styles.xml', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="3">
    <font><sz val="10"/><name val="Calibri"/></font>
    <font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/></font>
    <font><b/><sz val="10"/><name val="Calibri"/></font>
  </fonts>
  <fills count="4">
    <fill><patternFill patternType="none"/></fill>
    <fill><patternFill patternType="gray125"/></fill>
    <fill><patternFill patternType="solid"><fgColor rgb="FF1F497D"/></patternFill></fill>
    <fill><patternFill patternType="solid"><fgColor rgb="FFEAECEE"/></patternFill></fill>
  </fills>
  <borders count="2">
    <border><left/><right/><top/><bottom/><diagonal/></border>
    <border>
      <left style="thin"><color rgb="FFD3D3D3"/></left>
      <right style="thin"><color rgb="FFD3D3D3"/></right>
      <top style="thin"><color rgb="FFD3D3D3"/></top>
      <bottom style="thin"><color rgb="FFD3D3D3"/></bottom>
    </border>
  </borders>
  <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
  <cellXfs count="4">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0"/>
    <xf numFmtId="0" fontId="1" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment horizontal="center" vertical="center" wrapText="1"/></xf>
    <xf numFmtId="0" fontId="2" fillId="3" borderId="1" xfId="0" applyFont="1" applyFill="1"/>
    <xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>
  </cellXfs>
</styleSheet>''')

            # 6. Worksheets
            for i, (name, rows) in enumerate(self.sheets, 1):
                ws_lines = [
                    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
                    '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">',
                    '  <sheetData>'
                ]
                for r_idx, row in enumerate(rows, 1):
                    # Header row style vs data style
                    is_header = (r_idx == 1 or (len(row) == 1 and str(row[0]).startswith("---")))
                    ws_lines.append(f'    <row r="{r_idx}">')
                    for c_idx, val in enumerate(row, 1):
                        cell_ref = f"{col_name(c_idx)}{r_idx}"
                        val_str = str(val) if val is not None else ""
                        s_attr = ' s="1"' if r_idx == 1 else (' s="2"' if is_header else ' s="3"')
                        ws_lines.append(f'      <c r="{cell_ref}" t="inlineStr"{s_attr}><is><t>{escape(val_str)}</t></is></c>')
                    ws_lines.append('    </row>')
                ws_lines.append('  </sheetData>')
                ws_lines.append('</worksheet>')
                z.writestr(f'xl/worksheets/sheet{i}.xml', '\n'.join(ws_lines))

        with open(filepath, 'wb') as f:
            f.write(buf.getvalue())
        print(f"Generated {filepath} successfully ({os.path.getsize(filepath)} bytes).")

print("WorkbookBuilder ready.")
