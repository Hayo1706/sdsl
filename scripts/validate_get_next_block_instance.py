from typing import List, Dict

# Simulated block element with whether the column is required
class Element:
    def __init__(self, required: bool):
        self.is_col = True
        self.assign_required = required

def old_get_next_block_instance(m: List[List[str]], row_start: int, b: List[Element], col_start: int) -> int:
    for r in range(row_start + 1, len(m)):
        colIdx = col_start
        for column in b:
            if column.is_col and column.assign_required:
                if m[r][col_start] != "":
                    return r
            colIdx += 1
    return len(m)

def new_get_next_block_instance(m: List[List[str]], row_start: int, b: List[Element], col_start: int) -> int:
    for r in range(row_start + 1, len(m)):
        colIdx = col_start
        for column in b:
            if column.is_col and column.assign_required:
                if m[r][colIdx] != "":
                    return r
            colIdx += 1
    return len(m)

# example matrix
m = [
    ["header1", "header2"],
    ["", ""],
    ["", "value"],
    ["value2", ""]
]

b = [Element(False), Element(True)]

print("old result", old_get_next_block_instance(m, 0, b, 0))
print("new result", new_get_next_block_instance(m, 0, b, 0))
