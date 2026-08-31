import sys
from pathlib import Path

def get_code_characters(code: str) -> list[tuple[str, int, int]]:
    """
    Scans the source code and returns a list of (char, line, col) tuples
    for bracket characters, excluding those inside comments and strings.
    """
    result = []
    i = 0
    n = len(code)
    
    # Calculate line and column numbers
    lines = [1] * n
    cols = [1] * n
    current_line = 1
    current_col = 1
    for idx, ch in enumerate(code):
        lines[idx] = current_line
        cols[idx] = current_col
        if ch == '\n':
            current_line += 1
            current_col = 1
        else:
            current_col += 1

    state = 'code' # 'code', 'string', 'raw_string', 'triple_string', 'triple_raw_string', 'line_comment', 'block_comment'
    string_quote = ''
    string_stack = [] # stack of (state, string_quote, brace_depth)
    brace_depth = 0
    
    while i < n:
        if state == 'code':
            # Block comment
            if i + 1 < n and code[i:i+2] == '/*':
                state = 'block_comment'
                i += 2
            # Line comment
            elif i + 1 < n and code[i:i+2] == '//':
                state = 'line_comment'
                i += 2
            # Raw triple-quoted string
            elif i + 3 < n and code[i] == 'r' and code[i+1:i+4] in ('"""', "'''"):
                state = 'triple_raw_string'
                string_quote = code[i+1:i+4]
                i += 4
            # Raw single-quoted string
            elif i + 1 < n and code[i] == 'r' and code[i+1] in ('"', "'"):
                state = 'raw_string'
                string_quote = code[i+1]
                i += 2
            # Standard triple-quoted string
            elif i + 2 < n and code[i:i+3] in ('"""', "'''"):
                state = 'triple_string'
                string_quote = code[i:i+3]
                i += 3
            # Standard single-quoted string
            elif code[i] in ('"', "'"):
                state = 'string'
                string_quote = code[i]
                i += 1
            else:
                ch = code[i]
                if ch in '({[':
                    if ch == '{':
                        brace_depth += 1
                    result.append((ch, lines[i], cols[i]))
                elif ch in ')}]':
                    if ch == '}':
                        if brace_depth > 0:
                            brace_depth -= 1
                        elif string_stack:
                            # We were inside an interpolation and reached the closing '}'
                            prev_state, prev_quote, prev_depth = string_stack.pop()
                            state = prev_state
                            string_quote = prev_quote
                            brace_depth = prev_depth
                            i += 1
                            continue
                    result.append((ch, lines[i], cols[i]))
                i += 1
                
        elif state == 'block_comment':
            if i + 1 < n and code[i:i+2] == '*/':
                state = 'code'
                i += 2
            else:
                i += 1
                
        elif state == 'line_comment':
            if code[i] == '\n':
                state = 'code'
                i += 1
            else:
                i += 1
                
        elif state == 'string':
            if code[i] == '\\':
                i += 2
            elif code[i] == string_quote:
                state = 'code'
                i += 1
            elif i + 1 < n and code[i:i+2] == '${':
                # Dart string interpolation: suspend string state, enter code state
                string_stack.append(('string', string_quote, brace_depth))
                state = 'code'
                brace_depth = 0
                i += 2
            elif code[i] == '$' and i + 1 < n and code[i+1].isalpha():
                # simple $var interpolation
                i += 1
                while i < n and (code[i].isalnum() or code[i] == '_'):
                    i += 1
            else:
                i += 1
                
        elif state == 'triple_string':
            if code[i] == '\\':
                i += 2
            elif i + len(string_quote) - 1 < n and code[i:i+len(string_quote)] == string_quote:
                state = 'code'
                i += len(string_quote)
            elif i + 1 < n and code[i:i+2] == '${':
                string_stack.append(('triple_string', string_quote, brace_depth))
                state = 'code'
                brace_depth = 0
                i += 2
            elif code[i] == '$' and i + 1 < n and code[i+1].isalpha():
                i += 1
                while i < n and (code[i].isalnum() or code[i] == '_'):
                    i += 1
            else:
                i += 1
                
        elif state == 'raw_string':
            if code[i] == string_quote:
                state = 'code'
                i += 1
            else:
                i += 1
                
        elif state == 'triple_raw_string':
            if i + len(string_quote) - 1 < n and code[i:i+len(string_quote)] == string_quote:
                state = 'code'
                i += len(string_quote)
            else:
                i += 1
                
    return result

def check_brackets(file_path: Path):
    try:
        content = file_path.read_text(encoding='utf-8', errors='ignore')
    except Exception as e:
        print(f"Error reading file: {e}")
        return False

    code_chars = get_code_characters(content)
    
    # Calculate counts
    counts = {'(': 0, ')': 0, '{': 0, '}': 0, '[': 0, ']': 0}
    for ch, _, _ in code_chars:
        if ch in counts:
            counts[ch] += 1
            
    print(f"File: {file_path}")
    print(f"Counts: {counts}")
    
    # Find mismatch
    stack = []
    pairs = {'(': ')', '{': '}', '[': ']'}
    mismatch = False
    
    for ch, line, col in code_chars:
        if ch in '({[':
            stack.append((ch, line, col))
        elif ch in ')}]':
            if not stack:
                print(f"Unmatched closing '{ch}' at Line {line}, Column {col}")
                mismatch = True
                break
            last, o_line, o_col = stack.pop()
            if pairs[last] != ch:
                print(f"Mismatched closing '{ch}' at Line {line}, Column {col} with opening '{last}' from Line {o_line}, Column {o_col}")
                mismatch = True
                break
                
    if not mismatch:
        if stack:
            last, o_line, o_col = stack[-1]
            print(f"Unclosed opening '{last}' from Line {o_line}, Column {o_col}")
        else:
            print("All brackets match perfectly!")
            return True
            
    return False

if __name__ == '__main__':
    default_path = r'c:/xampp/htdocs/FOMS/foms_app/lib/screens/customer/customer_dashboard.dart'
    target_path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(default_path)
    
    if not target_path.exists():
        print(f"File not found: {target_path}")
        sys.exit(1)
        
    success = check_brackets(target_path)
    sys.exit(0 if success else 1)
