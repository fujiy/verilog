### 概要

8bit プロセッサ

8bit固定長命令，アドレス9bit

## レジスタ

| Register | Size | Name                 | 目的               |
|----------|------|----------------------|--------------------|
| AX       | 8bit | Accumulator Register | 演算               |
| DX       | 8bit | Data Register        | 汎用，即値         |
| IX       | 4bit | Index Register       | インデックス       |
| SX       | 4bit | Status Register      | フラグ             |
| SB       | 8bit | Stack Base Pointer   | フレーム開始位置   |
| SP       | 8bit | Stack Pointer        | スタックオフセット |
| IP       | 8bit | Instruction Pointer  | プログラム位置     |

Stack[i] = SM[SB+i]

### フラグ

| Flag | Name          | 条件           |
|------|---------------|----------------|
| CF   | Carry Flag    | キャリー       |
| ZF   | Zero Flag     | ゼロ           |
| NF   | Negative Flag | ネガティブ     |
| VF   | Overflow Flag | オーバーフロー |

## メモリ

| Memory | Size     | Name           |
|--------|----------|----------------|
| SM     | 2^8 byte | Stack Memory   |
| PM     | 2^8 byte | Program Memory |

## 命令

### 算術演算

| Instruction | Meaning             | Opcode   |
|-------------|---------------------|----------|
| ADD         | AX = AX + DX        | 00001000 |
| ADD         | AX = AX + Stack[IX] | 00001001 |
| SUB         | AX = AX - DX        | 00001010 |
| SUB         | AX = AX - Stack[IX] | 00001011 |
| INC         | AX = AX + 1         | 0000110x |
| DEC         | AX = AX + 1         | 0000111x |

### データ転送

| Instruction | Meaning        | Opcode   | 備考                  |
|-------------|----------------|----------|-----------------------|
| INDEX i     | IX = i         | 001iiiii | インデックス指定      |
| MOV         | AX = DX        | 00010000 |                       |
| MOV         | DX = AX        | 00010001 |                       |
| LOAD        | AX = Stack[IX] | 00010010 | ローカル変数ロード    |
| LOAD        | DX = Stack[IX] | 00010011 | 〃                    |
| STORE       | Stack[IX] = AX | 000101x0 | ローカル変数ストア    |
| STORE       | Stack[IX] = DX | 000101x1 | 〃                    |
| IM n        | AX = {0000, i} | 100iiii0 | 即値ロード（下位4bit) |
| IM n        | DX = {0000, i} | 100iiii1 | 〃                    |
| IM n        | AX = {i, xxxx} | 101iiii0 | 即値ロード（上位4bit) |
| IM n        | DX = {i, xxxx} | 101iiii1 | 〃                    |

### 関数

| Instruction | Meaning                         | Opcode   | 備考                                        |
|-------------|---------------------------------|----------|---------------------------------------------|
| ENTER i     | SB += SP, Stack[1] = SP, SP = i | 010iiiii | SP 退避，フレーム移動，ローカル変数領域確保 |
| LEAVE       | SP = Stack[1], SB -= SP         | 00000010 | BP, SP 復元                                 |
| CALL i      | IP ±= i << 2, Stack[SP] = i     | 11iiiiii | 関数 call                                   |
| RETURN      | IP ∓= Stack[SP] << 2,           | 00000011 | 関数 return                                 |

### ジャンプ，分岐，フラグ

| Instruction | Meaning             | Opcode   |
|-------------|---------------------|----------|
| JUMP i      | IP ±= i             | 011iiiii |
| BRANCH C    | if CF  then IP += 1 | 00011000 |
| BRANCH NC   | if ~CF then IP += 1 | 00011001 |
| BRANCH Z    | if ZF  then IP += 1 | 00011010 |
| BRANCH NZ   | if ~ZF then IP += 1 | 00011011 |
| BRANCH N    | if NF  then IP += 1 | 00011100 |
| BRANCH NN   | if ~NF then IP += 1 | 00011101 |
| BRANCH V    | if VF  then IP += 1 | 00011110 |
| BRANCH NV   | if ~VF then IP += 1 | 00011111 |
| CLEAR C     | CF = 0              | 00000100 |
| SET C       | CF = 1              | 00000101 |

### その他

| Instruction | Meaning | Opcode   |
|-------------|---------|----------|
| NOP         | nop     | 00000000 |
| HALT        | stop    | 00000001 |

### 命令構造

| Kind       | 7 | 6 | 5   | 4  | 3  | 2     | 1     | 0   |
|------------|---|---|-----|----|----|-------|-------|-----|
| Nop        | 0 | 0 | 0   | 0  | 0  | 0     | 0     | 0   |
| Halt       | 0 | 0 | 0   | 0  | 0  | 0     | 0     | 1   |
| Leave      | 0 | 0 | 0   | 0  | 0  | 0     | 1     | 0   |
| Return     | 0 | 0 | 0   | 0  | 0  | 0     | 1     | 1   |
| Flag       | 0 | 0 | 0   | 0  | 0  | 1     | 0     | C/S |
| Arithmetic | 0 | 0 | 0   | 0  | 1  | k1    | k0    | D/S |
| Move       | 0 | 0 | 0   | 1  | 0  | L R/S | R R/S | A/D |
| Branch     | 0 | 0 | 0   | 1  | 1  | k1    | k0    | P/N |
| Index      | 0 | 0 | 1   | i4 | i3 | i2    | i1    | i0  |
| Enter      | 0 | 1 | 0   | i4 | i3 | i2    | i1    | i0  |
| Jump       | 0 | 1 | 1   | i4 | i3 | i2    | i1    | i0  |
| Immediate  | 1 | 0 | L/M | i3 | i2 | i1    | i0    | A/D |
| Call       | 1 | 1 | i5  | i4 | i3 | i2    | i1    | i0  |

### 呼び出し規約

1. 引数格納・・・Stack[フレームサイズ+2+i] = 引数i
2. 呼び出し・・・CALL i
3. 退避・・・Enter i
4. 引数取り出し・・・引数i = Stack[2+i]
5. 処理
6. 戻り値格納・・・AX = 戻り値
7. 回復・・・Leave
8. 復帰・・・Retuen
9. 戻り値取り出し・・・戻り値 = AX

### クロック

1. 命令フェッチ，デコード
2. データロード，処理
3. レジスタ更新，データストア
