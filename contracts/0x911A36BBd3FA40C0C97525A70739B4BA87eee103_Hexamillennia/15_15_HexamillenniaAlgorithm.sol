// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

uint256 constant MASK_4 = 2 ** 4 - 1;
uint256 constant MASK_6 = 2 ** 6 - 1;
uint256 constant MASK_8 = 2 ** 8 - 1;
uint256 constant MASK_12 = 2 ** 12 - 1;
uint256 constant MASK_16 = 2 ** 16 - 1;
uint256 constant MASK_32 = 2 ** 32 - 1;

uint256 constant HEXAGON_PERP_WALK_MASK = 2 ** 6;
uint256 constant HEXAGON_PERP_2_WALK_MASK = 2 ** 8;
uint256 constant HEXAGON_PERP_3_WALK_MASK = 2 ** 9;

uint256 constant HEXAGON_PAINT_OFFSET = 12;
uint256 constant SQUARE_PAINT_OFFSET = 16;
uint256 constant SQUARE_2_PAINT_OFFSET = 24;
uint256 constant TRIANGLE_PAINT_OFFSET = 28;
uint256 constant TRIANGLE_1_PAINT_OFFSET = 32;
uint256 constant HEXAGON_PAINT_MASK = 0xf000;
uint256 constant SQUARE_PAINT_MASK = 0xf0000;
uint256 constant TRIANGLE_PAINT_MASK = 0xf0000000;
uint256 constant TRIANGLE_1_PAINT_MASK = 0xf00000000;
uint256 constant SQUARE_2_WALK_PAINT_MASK = 0xf000100;

uint256 constant HEXAGON_EXPAND_OFFSET = 36;
uint256 constant HEXAGON_PERP_EXPAND_OFFSET = 42;
uint256 constant HEXAGON_EXPAND_MASK = 0x1000000000;
uint256 constant HEXAGON_PERP_EXPAND_MASK = 0x40000000000;
uint256 constant HEXAGON_FULL_BOUNDARY_MASK = 0x3f000000000;
uint256 constant SQUARE_HALF_BOUNDARY_MASK = 0x41000000000;
uint256 constant VERTEX_013_EXPAND_MASK = 0x82143021810c086043;

uint256 constant EXPAND_ROOT_OFFSET = 48;
uint256 constant SELF_OFFSET = 52;
uint256 constant ROW_COL_OFFSET = 68;
uint256 constant STATE_OFFSET = 84;
uint256 constant STATE_1_OFFSET = 100;
uint256 constant STATE_3_OFFSET = 132;
uint256 constant STATE_5_OFFSET = 164;

uint256 constant ANGLE_TO_HEXAGON = 0x0100010100017f007f7f007f;
uint256 constant ANGLE_TO_HEXAGON_PLUS = 0x020102020102000100000100;
uint256 constant ANGLE_TO_VERTEX_X = 0x000003e8000007d0000003e8fffffc18fffff830fffffc18;
uint256 constant ANGLE_TO_VERTEX_Y = 0xfffff93c00000000000006c4000006c400000000fffff93c;

uint256 constant POPCOUNT_6 = 0x6554544354434332544343324332322154434332433232214332322132212110;

// These memory locations are above the area that Solidity allocates for the 3 string constants below, and this is the only area that Solidity
// allocates when this library is used as intended.
uint256 constant LOG2_DIM_M = 0x680;
uint256 constant DIM_M = 0x6a0;
uint256 constant UNROLLED_GRID_M = 0x6c0;
uint256 constant OPEN_M = 0x6e0;
uint256 constant MARGIN_M = 0x700;
uint256 constant UNROLLED_GRID_ROWS_M = 0x720;
uint256 constant UNROLLED_GRID_COLS_M = 0x740;
uint256 constant STACK_M = 0x760;
uint256 constant STACK_IDX_M = 0x780;
uint256 constant CACHE_M = 0x7a0;
uint256 constant CACHE_IDX_M = 0x7c0;
uint256 constant OUTPUT_M = 0x7e0;
uint256 constant OUTPUT_IDX_M = 0x800;
uint256 constant STATE_M_M = 0x820;
uint256 constant ANGLE_M = 0x840;
uint256 constant STEPS_IDX_M = 0x860;
uint256 constant STEPS_M = 0x880;
uint256 constant PALETTE_IDX_M = 0x8a0;
uint256 constant PALETTE_M = 0x8c0;
uint256 constant NUM_COLORS_M = 0x8e0;
uint256 constant COLOR_M = 0x900;
uint256 constant EDGE_COUNT_M = 0x920;
uint256 constant SVG_STRING_LOOKUP_M = 0x940;
uint256 constant OPEN_VIEW_BOX_X_DECIMAL_M = 0x960;
uint256 constant OPEN_VIEW_BOX_X_DECIMAL_LENGTH_M = 0x980;
uint256 constant OPEN_VIEW_BOX_Y_DECIMAL_M = 0x9a0;
uint256 constant OPEN_VIEW_BOX_Y_DECIMAL_LENGTH_M = 0x9c0;
uint256 constant OPEN_VIEW_BOX_WIDTH_DECIMAL_M = 0x9e0;
uint256 constant OPEN_VIEW_BOX_WIDTH_DECIMAL_LENGTH_M = 0xa00;
uint256 constant OPEN_VIEW_BOX_HEIGHT_DECIMAL_M = 0xa20;
uint256 constant OPEN_VIEW_BOX_HEIGHT_DECIMAL_LENGTH_M = 0xa40;
uint256 constant DOMAIN_WIDTH_DECIMAL_M = 0xa60;
uint256 constant DOMAIN_WIDTH_DECIMAL_LENGTH_M = 0xa80;
uint256 constant DOMAIN_HEIGHT_DECIMAL_M = 0xaa0;
uint256 constant DOMAIN_HEIGHT_DECIMAL_LENGTH_M = 0xac0;
uint256 constant SVG_START_M = 0xae0;
uint256 constant SVG_END_M = 0xb00;
uint256 constant JSON_STRING_LOOKUP_M = 0xb20;
uint256 constant TOKEN_ID_M = 0xb40;
uint256 constant TOKEN_ID_DECIMAL_M = 0xb60;
uint256 constant TOKEN_ID_DECIMAL_LENGTH_M = 0xb80;
uint256 constant DIM_DECIMAL_M = 0xba0;
uint256 constant DIM_DECIMAL_LENGTH_M = 0xbc0;
uint256 constant PALETTE_IDX_DECIMAL_M = 0xbe0;
uint256 constant PALETTE_IDX_DECIMAL_LENGTH_M = 0xc00;

uint256 constant ANGLE_EDGE_TO_VECTOR = 0xcc0;
uint256 constant ANGLE_EDGE_TO_VECTOR_OFFSET = 0xece4dcd1c7bbb0a69b90867f7770695e52483d31261b0f0700;
uint256 constant BASE64 = 0xda1;
uint256 constant RANDOM_SOURCE = 0xe00;
uint256 constant SHIFT_M = 0xe20;
uint256 constant GRID = 0xe40;

string constant PALETTES = 'FF87CA7FAEFAB07676FCDED4F7ABD4CCA3A3B8D1FFA555ECC47AFFFDFF00FFF8BC38E54DCFFF8DFF731DF7A76CE5DFD6FBF8F4807E7D633E35A27B5C9FC088F4DFBAFFFEA9379237BA3A33D85C2BF1F582FB6B337D3D443F2828FEE1830280C0253978B6E6FFD3E0EFA1F7FF84A1C9EDF5FC540375FF7000FF4949FFFD8C824C96F2D0A3D0A369B46F37A70A0D800004BF040AB51212EFEFEFDFDEDEFFFFFFFEFF9F393E465D697AF3CCFFF9DEFCD3B5F5F6EBFA012106210101200D073412115F3D36F4E1BCE3C69DB5918852230E864123F2BD77';
uint256 constant PALETTES_OFFSET = 0x473e3835312b261f18130d0700;
uint256 constant NUM_PALETTES = 12;
string constant SVG_STRING_LOOKUP = '<svg xmlns="http://www.w3.org/2000/svg" viewBox=""><rect x="-2732" y="-2732" width="" height="" fill="white"/><g stroke="black" stroke-width="100" stroke-linejoin="round" stroke-linecap="round" fill-rule="evenodd"><path d="" fill="#"/></g></svg> 0 0 -2732 -2732 M-2732 -2732l0 ';
string constant JSON_STRING_LOOKUP = 'data:application/json,%7B%22name%22:%22Tiling%20%22,%22description%22:%22Hexamillennia%20is%20generated%20entirely%20on%20the%20EVM.%20Released%20under%20CC0.%22,%22attributes%22:%5B%7B%22trait_type%22:%22%22,%22value%22:%22%22%7D,%7B%22trait_type%22:%22%22,%22value%22:%22%22%7D%5D,%22image%22:%22data:image/svg+xml;base64,%22%7DSizeFormStepsPaletteClosedOpenLowMediumHigh';

library HexamillenniaAlgorithm {
    function tokenURI(uint256 tokenId, uint256 randomSource) internal pure returns (string memory) {
        generateSVG(tokenId, randomSource);
        resetOutput();
        writeJSON();
        returnOutput();
    }

    function tokenSVG(uint256 tokenId, uint256 randomSource) internal pure returns (string memory) {
        generateSVG(tokenId, randomSource);
        returnOutput();
    }

    function generateSVG(uint256 tokenId, uint256 randomSource) internal pure {
        initializeKnownData(tokenId, randomSource);
        chooseAttributes();
        initializeVariables();
        prepareGrid();
        walk();
        paint();
        prepareUnrolledGrid();
        writeDecimalLookup();
        resetOutput();
        writePreExpand();
        expand();
        writePostExpand();
    }

    function initializeKnownData(uint256 tokenId, uint256 randomSource) internal pure {
        string memory palettes = PALETTES;
        string memory svgStringLookup = SVG_STRING_LOOKUP;
        string memory jsonStringLookup = JSON_STRING_LOOKUP;
        assembly {
            mstore(TOKEN_ID_M, tokenId)
            mstore(RANDOM_SOURCE, randomSource)
            mstore(PALETTE_M, add(palettes, 0x20))
            mstore(SVG_STRING_LOOKUP_M, add(svgStringLookup, 0x20))
            mstore(JSON_STRING_LOOKUP_M, add(jsonStringLookup, 0x20))
            mstore(0xcc0, ' 2000 0 0 -2000 -1732 -1000 -100')
            mstore(0xce0, '0 1732 1000 -1732 -1732 -1000 -1')
            mstore(0xd00, '732 1000 1000 1732 -1000 -1732 -')
            mstore(0xd20, '1732 1000 0 2000 2000 0 -2000 0 ')
            mstore(0xd40, '0 2000 1732 1000 1000 -1732 -100')
            mstore(0xd60, '0 1732 1732 1000 1732 -1000 -100')
            mstore(0xd80, '0 -1732 1000 1732 1732 -1000 0 -')
            mstore(0xda0, '2000 -2000 0')
            mstore(0xdc0, 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef')
            mstore(0xde0, 'ghijklmnopqrstuvwxyz0123456789+/')
        }
    }

    function chooseAttributes() internal pure {
        assembly {
            function updateRandomSource() {
                let shift := mload(SHIFT_M)
                shift := add(shift, 8)
                if eq(shift, 256) {
                    mstore(RANDOM_SOURCE, keccak256(RANDOM_SOURCE, 0x20))
                    shift := 0
                }
                mstore(SHIFT_M, shift)
            }
            // log2Dim can be at most 4 in this implementation
            let log2Dim := add(shr(6, and(shr(mload(SHIFT_M), mload(RANDOM_SOURCE)), MASK_8)), 1)
            let dim := shl(log2Dim, 1)
            mstore(LOG2_DIM_M, log2Dim)
            mstore(DIM_M, dim)
            updateRandomSource()
            mstore(OPEN_M, shr(7, and(shr(mload(SHIFT_M), mload(RANDOM_SOURCE)), MASK_8)))
            updateRandomSource()
            mstore(STATE_M_M, add(GRID, shl(5, shr(8, mul(mul(dim, dim), and(shr(mload(SHIFT_M), mload(RANDOM_SOURCE)), MASK_8))))))
            updateRandomSource()
            mstore(ANGLE_M, shr(8, mul(6, and(shr(mload(SHIFT_M), mload(RANDOM_SOURCE)), MASK_8))))
            updateRandomSource()
            let stepsIdx := shr(8, mul(3, and(shr(mload(SHIFT_M), mload(RANDOM_SOURCE)), MASK_8)))
            mstore(STEPS_IDX_M, stepsIdx)
            mstore(STEPS_M, shl(add(add(stepsIdx, 4), shl(1, log2Dim)), 1))
            updateRandomSource()
            let paletteIdx := shr(8, mul(NUM_PALETTES, and(shr(mload(SHIFT_M), mload(RANDOM_SOURCE)), MASK_8)))
            mstore(PALETTE_IDX_M, paletteIdx)
            let adjusted := shr(shl(3, paletteIdx), PALETTES_OFFSET)
            let offset := and(adjusted, MASK_8)
            mstore(PALETTE_M, add(mload(PALETTE_M), mul(offset, 0x6)))
            mstore(NUM_COLORS_M, sub(and(shr(8, adjusted), MASK_8), offset))
            updateRandomSource()
        }
    }

    function initializeVariables() internal pure {
        assembly {
            let dim := mload(DIM_M)
            let open := mload(OPEN_M)
            let margin := mul(sub(mload(LOG2_DIM_M), 1), open)
            let hexagonCount
            switch open
            case 0 {
                hexagonCount := mul(shr(1, add(dim, 2)), add(shl(1, dim), 3))
            }
            case 1 {
                hexagonCount := mul(dim, dim)
            }
            mstore(UNROLLED_GRID_M, add(GRID, shl(5, mul(dim, dim))))
            mstore(MARGIN_M, margin)
            mstore(UNROLLED_GRID_ROWS_M, add(add(add(dim, shr(1, dim)), 4), shl(1, margin)))
            mstore(UNROLLED_GRID_COLS_M, add(add(dim, 4), shl(1, margin)))
            mstore(STACK_M, add(mload(UNROLLED_GRID_M), shl(5, mul(mload(UNROLLED_GRID_ROWS_M), mload(UNROLLED_GRID_COLS_M)))))
            mstore(STACK_IDX_M, mload(STACK_M))
            mstore(CACHE_M, add(mload(STACK_M), add(mul(hexagonCount, 18), 0x20)))
            mstore(CACHE_IDX_M, mload(CACHE_M))
            mstore(OUTPUT_M, add(mload(CACHE_M), add(mul(hexagonCount, 39), 0x20)))
            mstore(OUTPUT_IDX_M, mload(OUTPUT_M))
        }
    }

    function prepareGrid() internal pure {
        assembly {
            let log2Dim := mload(LOG2_DIM_M)
            let dim := mload(DIM_M)
            let gridCount := mul(dim, dim)
            for {
                let gridIdx
            } lt(gridIdx, gridCount) {
                gridIdx := add(gridIdx, 1)
            } {
                let stateM := add(GRID, shl(5, gridIdx))
                mstore(stateM, shl(SELF_OFFSET, stateM))
                let row := shr(log2Dim, gridIdx)
                let col := and(gridIdx, sub(dim, 1))
                switch and(and(and(gt(row, 0), lt(row, sub(dim, 1))), gt(col, 0)), lt(col, sub(dim, 1)))
                case 0 {
                    for {
                        let angle
                    } lt(angle, 6) {
                        angle := add(angle, 1)
                    } {
                        let hexagonR0 := add(or(shl(8, col), row), shr(shl(4, angle), ANGLE_TO_HEXAGON))
                        let col0 := shr(8, hexagonR0)
                        mstore(
                            stateM,
                            or(
                                mload(stateM),
                                shl(
                                    add(shl(4, angle), STATE_OFFSET),
                                    add(
                                        add(GRID, shl(add(log2Dim, 5), and(sub(hexagonR0, mul(shr(log2Dim, col0), shr(1, dim))), sub(dim, 1)))),
                                        shl(5, and(col0, sub(dim, 1)))
                                    )
                                )
                            )
                        )
                    }
                }
                case 1 {
                    mstore(
                        stateM,
                        or(
                            mload(stateM),
                            shl(
                                STATE_OFFSET,
                                or(
                                    or(
                                        or(
                                            or(
                                                or(
                                                    shl(80, add(add(GRID, shl(add(log2Dim, 5), row)), shl(5, add(col, 1)))),
                                                    shl(64, add(add(GRID, shl(add(log2Dim, 5), add(row, 1))), shl(5, add(col, 1))))
                                                ),
                                                shl(48, add(add(GRID, shl(add(log2Dim, 5), add(row, 1))), shl(5, col)))
                                            ),
                                            shl(32, add(add(GRID, shl(add(log2Dim, 5), row)), shl(5, sub(col, 1))))
                                        ),
                                        shl(16, add(add(GRID, shl(add(log2Dim, 5), sub(row, 1))), shl(5, sub(col, 1))))
                                    ),
                                    add(add(GRID, shl(add(log2Dim, 5), sub(row, 1))), shl(5, col))
                                )
                            )
                        )
                    )
                }
            }
        }
    }

    function walk() internal pure {
        assembly {
            let stateM := mload(STATE_M_M)
            let angle := mload(ANGLE_M)
            let steps := mload(STEPS_M)
            for {
                let i
            } lt(i, steps) {
                i := add(i, 1)
            } {
                let shift := mload(add(RANDOM_SOURCE, 0x20))
                switch shr(6, and(shr(shift, mload(RANDOM_SOURCE)), MASK_8))
                case 0 {
                    mstore(stateM, or(mload(stateM), shl(angle, 1)))
                    angle := addmod(angle, 5, 6)
                }
                case 1 {
                    mstore(stateM, or(mload(stateM), shl(angle, HEXAGON_PERP_WALK_MASK)))
                    stateM := and(shr(add(shl(4, angle), STATE_OFFSET), mload(stateM)), MASK_16)
                    angle := addmod(angle, 2, 6)
                }
                case 2 {
                    stateM := and(shr(add(shl(4, addmod(angle, 1, 6)), STATE_OFFSET), mload(stateM)), MASK_16)
                    angle := addmod(angle, 4, 6)
                    mstore(stateM, or(mload(stateM), shl(angle, HEXAGON_PERP_WALK_MASK)))
                }
                case 3 {
                    angle := addmod(angle, 1, 6)
                    mstore(stateM, or(mload(stateM), shl(angle, 1)))
                }
                if eq(shift, 248) {
                    mstore(RANDOM_SOURCE, keccak256(RANDOM_SOURCE, 0x20))
                    mstore(SHIFT_M, 0)
                    continue
                }
                mstore(SHIFT_M, add(shift, 8))
            }
        }
    }

    function paint() internal pure {
        assembly {
            function paintDF() {
                for {

                } gt(mload(STACK_IDX_M), mload(STACK_M)) {

                } {
                    mstore(STACK_IDX_M, sub(mload(STACK_IDX_M), 0x3))
                    let top := shr(232, mload(mload(STACK_IDX_M)))
                    switch shr(20, top)
                    case 0 {
                        for {
                            let angle
                        } lt(angle, 3) {
                            angle := add(angle, 1)
                        } {
                            if iszero(and(mload(top), or(shl(angle, 1), shl(shl(2, angle), SQUARE_PAINT_MASK)))) {
                                mstore(top, or(mload(top), shl(add(shl(2, angle), SQUARE_PAINT_OFFSET), mload(COLOR_M))))
                                mstore(mload(STACK_IDX_M), shl(232, or(or(0x100000, shl(16, angle)), top)))
                                mstore(STACK_IDX_M, add(mload(STACK_IDX_M), 0x3))
                            }
                            let stateR3M := and(shr(add(shl(4, add(angle, 3)), STATE_OFFSET), mload(top)), MASK_16)
                            if iszero(or(and(mload(top), shl(add(angle, 3), 1)), and(mload(stateR3M), shl(shl(2, angle), SQUARE_PAINT_MASK)))) {
                                mstore(stateR3M, or(mload(stateR3M), shl(add(shl(2, angle), SQUARE_PAINT_OFFSET), mload(COLOR_M))))
                                mstore(mload(STACK_IDX_M), shl(232, or(or(0x100000, shl(16, angle)), stateR3M)))
                                mstore(STACK_IDX_M, add(mload(STACK_IDX_M), 0x3))
                            }
                        }
                    }
                    case 1 {
                        let angle := and(shr(16, top), MASK_4)
                        let stateM := and(top, MASK_16)
                        if iszero(and(mload(stateM), or(shl(angle, 1), HEXAGON_PAINT_MASK))) {
                            mstore(stateM, or(mload(stateM), shl(HEXAGON_PAINT_OFFSET, mload(COLOR_M))))
                            mstore(mload(STACK_IDX_M), shl(232, stateM))
                            mstore(STACK_IDX_M, add(mload(STACK_IDX_M), 0x3))
                        }
                        let stateR0M := and(shr(add(shl(4, angle), STATE_OFFSET), mload(stateM)), MASK_16)
                        if iszero(and(mload(stateR0M), or(shl(add(angle, 3), 1), HEXAGON_PAINT_MASK))) {
                            mstore(stateR0M, or(mload(stateR0M), shl(HEXAGON_PAINT_OFFSET, mload(COLOR_M))))
                            mstore(mload(STACK_IDX_M), shl(232, stateR0M))
                            mstore(STACK_IDX_M, add(mload(STACK_IDX_M), 0x3))
                        }
                        switch eq(angle, 2)
                        case 0 {
                            if iszero(and(mload(stateM), or(shl(angle, HEXAGON_PERP_WALK_MASK), shl(shl(2, angle), TRIANGLE_PAINT_MASK)))) {
                                mstore(stateM, or(mload(stateM), shl(add(shl(2, angle), TRIANGLE_PAINT_OFFSET), mload(COLOR_M))))
                                mstore(mload(STACK_IDX_M), shl(232, or(or(0x200000, shl(16, angle)), stateM)))
                                mstore(STACK_IDX_M, add(mload(STACK_IDX_M), 0x3))
                            }
                        }
                        case 1 {
                            let state3M := and(shr(STATE_3_OFFSET, mload(stateM)), MASK_16)
                            if iszero(or(and(mload(stateM), HEXAGON_PERP_2_WALK_MASK), and(mload(state3M), TRIANGLE_PAINT_MASK))) {
                                mstore(state3M, or(mload(state3M), shl(TRIANGLE_PAINT_OFFSET, mload(COLOR_M))))
                                mstore(mload(STACK_IDX_M), shl(232, or(0x200000, state3M)))
                                mstore(STACK_IDX_M, add(mload(STACK_IDX_M), 0x3))
                            }
                        }
                        switch eq(angle, 0)
                        case 0 {
                            if iszero(
                                or(
                                    and(mload(stateR0M), shl(add(angle, 3), HEXAGON_PERP_WALK_MASK)),
                                    and(mload(stateM), shl(shl(2, sub(angle, 1)), TRIANGLE_PAINT_MASK))
                                )
                            ) {
                                mstore(stateM, or(mload(stateM), shl(add(shl(2, sub(angle, 1)), TRIANGLE_PAINT_OFFSET), mload(COLOR_M))))
                                mstore(mload(STACK_IDX_M), shl(232, or(or(0x200000, shl(16, sub(angle, 1))), stateM)))
                                mstore(STACK_IDX_M, add(mload(STACK_IDX_M), 0x3))
                            }
                        }
                        case 1 {
                            let state5M := and(shr(STATE_5_OFFSET, mload(stateM)), MASK_16)
                            if iszero(or(and(mload(stateR0M), HEXAGON_PERP_3_WALK_MASK), and(mload(state5M), TRIANGLE_1_PAINT_MASK))) {
                                mstore(state5M, or(mload(state5M), shl(TRIANGLE_1_PAINT_OFFSET, mload(COLOR_M))))
                                mstore(mload(STACK_IDX_M), shl(232, or(0x210000, state5M)))
                                mstore(STACK_IDX_M, add(mload(STACK_IDX_M), 0x3))
                            }
                        }
                    }
                    case 2 {
                        let angle := and(shr(16, top), MASK_4)
                        let stateM := and(top, MASK_16)
                        let stateR1M := and(shr(add(shl(4, add(angle, 1)), STATE_OFFSET), mload(stateM)), MASK_16)
                        if iszero(and(mload(stateM), or(shl(angle, HEXAGON_PERP_WALK_MASK), shl(shl(2, angle), SQUARE_PAINT_MASK)))) {
                            mstore(stateM, or(mload(stateM), shl(add(shl(2, angle), SQUARE_PAINT_OFFSET), mload(COLOR_M))))
                            mstore(mload(STACK_IDX_M), shl(232, or(or(0x100000, shl(16, angle)), stateM)))
                            mstore(STACK_IDX_M, add(mload(STACK_IDX_M), 0x3))
                        }
                        if iszero(
                            or(
                                and(mload(stateR1M), shl(add(angle, 4), HEXAGON_PERP_WALK_MASK)),
                                and(mload(stateM), shl(shl(2, add(angle, 1)), SQUARE_PAINT_MASK))
                            )
                        ) {
                            mstore(stateM, or(mload(stateM), shl(add(shl(2, add(angle, 1)), SQUARE_PAINT_OFFSET), mload(COLOR_M))))
                            mstore(mload(STACK_IDX_M), shl(232, or(or(0x100000, shl(16, add(angle, 1))), stateM)))
                            mstore(STACK_IDX_M, add(mload(STACK_IDX_M), 0x3))
                        }
                        switch angle
                        case 0 {
                            let state0M := and(shr(STATE_OFFSET, mload(stateM)), MASK_16)
                            if iszero(and(mload(state0M), SQUARE_2_WALK_PAINT_MASK)) {
                                mstore(state0M, or(mload(state0M), shl(SQUARE_2_PAINT_OFFSET, mload(COLOR_M))))
                                mstore(mload(STACK_IDX_M), shl(232, or(0x120000, state0M)))
                                mstore(STACK_IDX_M, add(mload(STACK_IDX_M), 0x3))
                            }
                        }
                        case 1 {
                            if iszero(
                                or(
                                    and(mload(and(shr(STATE_1_OFFSET, mload(stateM)), MASK_16)), HEXAGON_PERP_3_WALK_MASK),
                                    and(mload(stateR1M), SQUARE_PAINT_MASK)
                                )
                            ) {
                                mstore(stateR1M, or(mload(stateR1M), shl(SQUARE_PAINT_OFFSET, mload(COLOR_M))))
                                mstore(mload(STACK_IDX_M), shl(232, or(0x100000, stateR1M)))
                                mstore(STACK_IDX_M, add(mload(STACK_IDX_M), 0x3))
                            }
                        }
                    }
                }
            }
            function chooseColor() {
                let shift := mload(SHIFT_M)
                mstore(COLOR_M, add(shr(8, mul(mload(NUM_COLORS_M), and(shr(shift, mload(RANDOM_SOURCE)), MASK_8))), 1))
                shift := add(shift, 8)
                if eq(shift, 256) {
                    mstore(RANDOM_SOURCE, keccak256(RANDOM_SOURCE, 0x20))
                    shift := 0
                }
                mstore(SHIFT_M, shift)
            }
            let gridEnd := mload(UNROLLED_GRID_M)
            for {
                let stateM := GRID
            } lt(stateM, gridEnd) {
                stateM := add(stateM, 0x20)
            } {
                if iszero(and(mload(stateM), HEXAGON_PAINT_MASK)) {
                    chooseColor()
                    mstore(stateM, or(mload(stateM), shl(HEXAGON_PAINT_OFFSET, mload(COLOR_M))))
                    mstore(mload(STACK_IDX_M), shl(232, stateM))
                    mstore(STACK_IDX_M, add(mload(STACK_IDX_M), 0x3))
                    paintDF()
                }
                for {
                    let angle
                } lt(angle, 3) {
                    angle := add(angle, 1)
                } {
                    if iszero(and(mload(stateM), shl(shl(2, angle), SQUARE_PAINT_MASK))) {
                        chooseColor()
                        mstore(stateM, or(mload(stateM), shl(add(shl(2, angle), SQUARE_PAINT_OFFSET), mload(COLOR_M))))
                        mstore(mload(STACK_IDX_M), shl(232, or(or(0x100000, shl(16, angle)), stateM)))
                        mstore(STACK_IDX_M, add(mload(STACK_IDX_M), 0x3))
                        paintDF()
                    }
                    if and(lt(angle, 2), iszero(and(mload(stateM), shl(shl(2, angle), TRIANGLE_PAINT_MASK)))) {
                        chooseColor()
                        mstore(stateM, or(mload(stateM), shl(add(shl(2, angle), TRIANGLE_PAINT_OFFSET), mload(COLOR_M))))
                        mstore(mload(STACK_IDX_M), shl(232, or(or(0x200000, shl(16, angle)), stateM)))
                        mstore(STACK_IDX_M, add(mload(STACK_IDX_M), 0x3))
                        paintDF()
                    }
                }
            }
        }
    }

    function prepareUnrolledGrid() internal pure {
        assembly {
            let dim := mload(DIM_M)
            let unrolledGrid := mload(UNROLLED_GRID_M)
            let margin := mload(MARGIN_M)
            let cols := mload(UNROLLED_GRID_COLS_M)
            let gridCount := mul(mload(UNROLLED_GRID_ROWS_M), cols)
            for {
                let gridIdx
            } lt(gridIdx, gridCount) {
                gridIdx := add(gridIdx, 1)
            } {
                let stateM := add(unrolledGrid, shl(5, gridIdx))
                let row := div(gridIdx, cols)
                let col := mod(gridIdx, cols)
                if and(
                    and(and(gt(col, 0), lt(col, add(add(shl(1, margin), 3), dim))), gt(add(shl(1, row), 1), col)),
                    lt(shl(1, row), add(add(add(shl(1, margin), 3), shl(1, dim)), col))
                ) {
                    let colN := sub(col, add(margin, 2))
                    mstore(
                        stateM,
                        or(
                            and(
                                mload(
                                    add(
                                        add(
                                            GRID,
                                            shl(
                                                add(mload(LOG2_DIM_M), 5),
                                                and(sub(sub(row, add(margin, 2)), mul(shr(mload(LOG2_DIM_M), colN), shr(1, dim))), sub(dim, 1))
                                            )
                                        ),
                                        shl(5, and(colN, sub(dim, 1)))
                                    )
                                ),
                                0xfffffffffffffffff
                            ),
                            shl(
                                EXPAND_ROOT_OFFSET,
                                or(
                                    iszero(mload(OPEN_M)),
                                    and(
                                        and(
                                            and(gt(col, add(margin, 1)), lt(col, add(add(margin, 2), dim))),
                                            gt(shl(1, row), add(add(margin, 1), col))
                                        ),
                                        lt(shl(1, row), add(add(add(margin, 2), shl(1, dim)), col))
                                    )
                                )
                            )
                        )
                    )
                    if iszero(mload(OPEN_M)) {
                        mstore(stateM, or(and(mload(stateM), 0xfffffffffffff), shl(SELF_OFFSET, stateM)))
                    }
                }
                mstore(stateM, or(mload(stateM), shl(ROW_COL_OFFSET, or(shl(8, col), row))))
                for {
                    let angle
                } lt(angle, 6) {
                    angle := add(angle, 1)
                } {
                    let hexagonR0Plus := and(add(or(shl(8, col), row), shr(shl(4, angle), ANGLE_TO_HEXAGON_PLUS)), MASK_16)
                    mstore(
                        stateM,
                        or(
                            mload(stateM),
                            shl(
                                add(shl(4, angle), STATE_OFFSET),
                                add(add(unrolledGrid, mul(cols, shl(5, sub(and(hexagonR0Plus, MASK_8), 1)))), shl(5, sub(shr(8, hexagonR0Plus), 1)))
                            )
                        )
                    )
                }
            }
        }
    }

    function expand() internal pure {
        assembly {
            function expandDF() {
                for {

                } gt(mload(STACK_IDX_M), mload(STACK_M)) {

                } {
                    mstore(STACK_IDX_M, sub(mload(STACK_IDX_M), 0x3))
                    let top := shr(232, mload(mload(STACK_IDX_M)))
                    switch shr(20, top)
                    case 0 {
                        let colorStateM := and(shr(SELF_OFFSET, mload(top)), MASK_16)
                        for {
                            let angle
                        } lt(angle, 3) {
                            angle := add(angle, 1)
                        } {
                            if eq(and(shr(add(shl(2, angle), SQUARE_PAINT_OFFSET), mload(colorStateM)), MASK_4), mload(COLOR_M)) {
                                mstore(colorStateM, xor(mload(colorStateM), shl(add(shl(2, angle), SQUARE_PAINT_OFFSET), mload(COLOR_M))))
                                mstore(mload(STACK_IDX_M), shl(232, or(or(0x100000, shl(16, angle)), top)))
                                mstore(STACK_IDX_M, add(mload(STACK_IDX_M), 0x3))
                            }
                            let stateR3M := and(shr(add(shl(4, add(angle, 3)), STATE_OFFSET), mload(top)), MASK_16)
                            let colorStateR3M := and(shr(SELF_OFFSET, mload(stateR3M)), MASK_16)
                            if and(
                                gt(colorStateR3M, 0),
                                eq(and(shr(add(shl(2, angle), SQUARE_PAINT_OFFSET), mload(colorStateR3M)), MASK_4), mload(COLOR_M))
                            ) {
                                mstore(colorStateR3M, xor(mload(colorStateR3M), shl(add(shl(2, angle), SQUARE_PAINT_OFFSET), mload(COLOR_M))))
                                mstore(mload(STACK_IDX_M), shl(232, or(or(0x100000, shl(16, angle)), stateR3M)))
                                mstore(STACK_IDX_M, add(mload(STACK_IDX_M), 0x3))
                            }
                        }
                        mstore(top, xor(mload(top), HEXAGON_FULL_BOUNDARY_MASK))
                        mstore(
                            EDGE_COUNT_M,
                            sub(
                                add(
                                    mload(EDGE_COUNT_M),
                                    shl(1, and(shr(shl(2, and(shr(HEXAGON_EXPAND_OFFSET, mload(top)), MASK_6)), POPCOUNT_6), MASK_4))
                                ),
                                6
                            )
                        )
                        mstore(mload(CACHE_IDX_M), shl(232, top))
                        mstore(CACHE_IDX_M, add(mload(CACHE_IDX_M), 0x3))
                        mstore(mload(CACHE_IDX_M), shl(232, or(0x20000, top)))
                        mstore(CACHE_IDX_M, add(mload(CACHE_IDX_M), 0x3))
                        mstore(mload(CACHE_IDX_M), shl(232, or(0x40000, top)))
                        mstore(CACHE_IDX_M, add(mload(CACHE_IDX_M), 0x3))
                    }
                    case 1 {
                        let angle := and(shr(16, top), MASK_4)
                        let stateM := and(top, MASK_16)
                        let colorStateM := and(shr(SELF_OFFSET, mload(stateM)), MASK_16)
                        if eq(and(shr(HEXAGON_PAINT_OFFSET, mload(colorStateM)), MASK_4), mload(COLOR_M)) {
                            mstore(colorStateM, xor(mload(colorStateM), shl(HEXAGON_PAINT_OFFSET, mload(COLOR_M))))
                            mstore(mload(STACK_IDX_M), shl(232, stateM))
                            mstore(STACK_IDX_M, add(mload(STACK_IDX_M), 0x3))
                        }
                        let stateR0M := and(shr(add(shl(4, angle), STATE_OFFSET), mload(stateM)), MASK_16)
                        let colorStateR0M := and(shr(SELF_OFFSET, mload(stateR0M)), MASK_16)
                        if and(gt(colorStateR0M, 0), eq(and(shr(HEXAGON_PAINT_OFFSET, mload(colorStateR0M)), MASK_4), mload(COLOR_M))) {
                            mstore(colorStateR0M, xor(mload(colorStateR0M), shl(HEXAGON_PAINT_OFFSET, mload(COLOR_M))))
                            mstore(mload(STACK_IDX_M), shl(232, stateR0M))
                            mstore(STACK_IDX_M, add(mload(STACK_IDX_M), 0x3))
                        }
                        switch eq(angle, 2)
                        case 0 {
                            if eq(and(shr(add(shl(2, angle), TRIANGLE_PAINT_OFFSET), mload(colorStateM)), MASK_4), mload(COLOR_M)) {
                                mstore(colorStateM, xor(mload(colorStateM), shl(add(shl(2, angle), TRIANGLE_PAINT_OFFSET), mload(COLOR_M))))
                                mstore(mload(STACK_IDX_M), shl(232, or(or(0x200000, shl(16, angle)), stateM)))
                                mstore(STACK_IDX_M, add(mload(STACK_IDX_M), 0x3))
                            }
                        }
                        case 1 {
                            let state3M := and(shr(STATE_3_OFFSET, mload(stateM)), MASK_16)
                            let colorState3M := and(shr(SELF_OFFSET, mload(state3M)), MASK_16)
                            if and(gt(colorState3M, 0), eq(and(shr(TRIANGLE_PAINT_OFFSET, mload(colorState3M)), MASK_4), mload(COLOR_M))) {
                                mstore(colorState3M, xor(mload(colorState3M), shl(TRIANGLE_PAINT_OFFSET, mload(COLOR_M))))
                                mstore(mload(STACK_IDX_M), shl(232, or(0x200000, state3M)))
                                mstore(STACK_IDX_M, add(mload(STACK_IDX_M), 0x3))
                            }
                        }
                        switch eq(angle, 0)
                        case 0 {
                            if eq(and(shr(add(shl(2, sub(angle, 1)), TRIANGLE_PAINT_OFFSET), mload(colorStateM)), MASK_4), mload(COLOR_M)) {
                                mstore(colorStateM, xor(mload(colorStateM), shl(add(shl(2, sub(angle, 1)), TRIANGLE_PAINT_OFFSET), mload(COLOR_M))))
                                mstore(mload(STACK_IDX_M), shl(232, or(or(0x200000, shl(16, sub(angle, 1))), stateM)))
                                mstore(STACK_IDX_M, add(mload(STACK_IDX_M), 0x3))
                            }
                        }
                        case 1 {
                            let state5M := and(shr(STATE_5_OFFSET, mload(stateM)), MASK_16)
                            let colorState5M := and(shr(SELF_OFFSET, mload(state5M)), MASK_16)
                            if and(gt(colorState5M, 0), eq(and(shr(TRIANGLE_1_PAINT_OFFSET, mload(colorState5M)), MASK_4), mload(COLOR_M))) {
                                mstore(colorState5M, xor(mload(colorState5M), shl(TRIANGLE_1_PAINT_OFFSET, mload(COLOR_M))))
                                mstore(mload(STACK_IDX_M), shl(232, or(0x210000, state5M)))
                                mstore(STACK_IDX_M, add(mload(STACK_IDX_M), 0x3))
                            }
                        }
                        let angle3 := add(angle, 3)
                        mstore(stateM, xor(mload(stateM), shl(angle, SQUARE_HALF_BOUNDARY_MASK)))
                        mstore(stateR0M, xor(mload(stateR0M), shl(angle3, SQUARE_HALF_BOUNDARY_MASK)))
                        mstore(
                            EDGE_COUNT_M,
                            sub(
                                add(
                                    mload(EDGE_COUNT_M),
                                    shl(
                                        1,
                                        add(
                                            add(
                                                add(
                                                    and(shr(add(angle, HEXAGON_EXPAND_OFFSET), mload(stateM)), 1),
                                                    and(shr(add(angle, HEXAGON_PERP_EXPAND_OFFSET), mload(stateM)), 1)
                                                ),
                                                and(shr(add(angle3, HEXAGON_EXPAND_OFFSET), mload(stateR0M)), 1)
                                            ),
                                            and(shr(add(angle3, HEXAGON_PERP_EXPAND_OFFSET), mload(stateR0M)), 1)
                                        )
                                    )
                                ),
                                4
                            )
                        )
                        mstore(mload(CACHE_IDX_M), shl(232, or(shl(16, angle), stateM)))
                        mstore(CACHE_IDX_M, add(mload(CACHE_IDX_M), 0x3))
                        mstore(mload(CACHE_IDX_M), shl(232, or(shl(16, angle3), stateR0M)))
                        mstore(CACHE_IDX_M, add(mload(CACHE_IDX_M), 0x3))
                    }
                    case 2 {
                        let angle := and(shr(16, top), MASK_4)
                        let stateM := and(top, MASK_16)
                        let stateR0M := and(shr(add(shl(4, angle), STATE_OFFSET), mload(stateM)), MASK_16)
                        let stateR1M := and(shr(add(shl(4, add(angle, 1)), STATE_OFFSET), mload(stateM)), MASK_16)
                        let colorStateM := and(shr(SELF_OFFSET, mload(stateM)), MASK_16)
                        if eq(and(shr(add(shl(2, angle), SQUARE_PAINT_OFFSET), mload(colorStateM)), MASK_4), mload(COLOR_M)) {
                            mstore(colorStateM, xor(mload(colorStateM), shl(add(shl(2, angle), SQUARE_PAINT_OFFSET), mload(COLOR_M))))
                            mstore(mload(STACK_IDX_M), shl(232, or(or(0x100000, shl(16, angle)), stateM)))
                            mstore(STACK_IDX_M, add(mload(STACK_IDX_M), 0x3))
                        }
                        if eq(and(shr(add(shl(2, add(angle, 1)), SQUARE_PAINT_OFFSET), mload(colorStateM)), MASK_4), mload(COLOR_M)) {
                            mstore(colorStateM, xor(mload(colorStateM), shl(add(shl(2, add(angle, 1)), SQUARE_PAINT_OFFSET), mload(COLOR_M))))
                            mstore(mload(STACK_IDX_M), shl(232, or(or(0x100000, shl(16, add(angle, 1))), stateM)))
                            mstore(STACK_IDX_M, add(mload(STACK_IDX_M), 0x3))
                        }
                        switch angle
                        case 0 {
                            let colorStateR0M := and(shr(SELF_OFFSET, mload(stateR0M)), MASK_16)
                            if and(gt(colorStateR0M, 0), eq(and(shr(SQUARE_2_PAINT_OFFSET, mload(colorStateR0M)), MASK_4), mload(COLOR_M))) {
                                mstore(colorStateR0M, xor(mload(colorStateR0M), shl(SQUARE_2_PAINT_OFFSET, mload(COLOR_M))))
                                mstore(mload(STACK_IDX_M), shl(232, or(0x120000, stateR0M)))
                                mstore(STACK_IDX_M, add(mload(STACK_IDX_M), 0x3))
                            }
                        }
                        case 1 {
                            let colorStateR1M := and(shr(SELF_OFFSET, mload(stateR1M)), MASK_16)
                            if and(gt(colorStateR1M, 0), eq(and(shr(SQUARE_PAINT_OFFSET, mload(colorStateR1M)), MASK_4), mload(COLOR_M))) {
                                mstore(colorStateR1M, xor(mload(colorStateR1M), shl(SQUARE_PAINT_OFFSET, mload(COLOR_M))))
                                mstore(mload(STACK_IDX_M), shl(232, or(0x100000, stateR1M)))
                                mstore(STACK_IDX_M, add(mload(STACK_IDX_M), 0x3))
                            }
                        }
                        let angle2 := add(angle, 2)
                        let angle4 := add(angle, 4)
                        mstore(stateM, xor(mload(stateM), shl(angle, HEXAGON_PERP_EXPAND_MASK)))
                        mstore(stateR0M, xor(mload(stateR0M), shl(angle2, HEXAGON_PERP_EXPAND_MASK)))
                        mstore(stateR1M, xor(mload(stateR1M), shl(angle4, HEXAGON_PERP_EXPAND_MASK)))
                        mstore(
                            EDGE_COUNT_M,
                            sub(
                                add(
                                    mload(EDGE_COUNT_M),
                                    shl(
                                        1,
                                        add(
                                            add(
                                                and(shr(add(angle, HEXAGON_PERP_EXPAND_OFFSET), mload(stateM)), 1),
                                                and(shr(add(angle2, HEXAGON_PERP_EXPAND_OFFSET), mload(stateR0M)), 1)
                                            ),
                                            and(shr(add(angle4, HEXAGON_PERP_EXPAND_OFFSET), mload(stateR1M)), 1)
                                        )
                                    )
                                ),
                                3
                            )
                        )
                        mstore(mload(CACHE_IDX_M), shl(232, or(shl(16, angle), stateM)))
                        mstore(CACHE_IDX_M, add(mload(CACHE_IDX_M), 0x3))
                        mstore(mload(CACHE_IDX_M), shl(232, or(shl(16, angle2), stateR0M)))
                        mstore(CACHE_IDX_M, add(mload(CACHE_IDX_M), 0x3))
                    }
                }
            }
            function writeBoundary() {
                let outputIdx := mload(OUTPUT_IDX_M)
                mstore(outputIdx, '<path d="')
                outputIdx := add(outputIdx, 0x9)
                let cacheEnd := mload(CACHE_IDX_M)
                for {
                    let cacheIdx := mload(CACHE_M)
                } lt(cacheIdx, cacheEnd) {
                    cacheIdx := add(cacheIdx, 0x3)
                } {
                    let vertex := shr(232, mload(cacheIdx))
                    let stateM := and(vertex, MASK_16)
                    let angle := and(shr(16, vertex), MASK_4)
                    if iszero(and(mload(stateM), shl(HEXAGON_EXPAND_OFFSET, and(shr(mul(angle, 12), VERTEX_013_EXPAND_MASK), MASK_12)))) {
                        continue
                    }
                    mstore8(outputIdx, 0x4d)
                    outputIdx := add(outputIdx, 0x1)
                    let hexagon := and(shr(ROW_COL_OFFSET, mload(stateM)), MASK_16)
                    {
                        let vx := and(add(mul(sub(shr(8, hexagon), add(mload(MARGIN_M), 2)), 4732), shr(shl(5, angle), ANGLE_TO_VERTEX_X)), MASK_32)
                        if shr(31, vx) {
                            vx := and(add(not(vx), 1), MASK_32)
                            mstore8(outputIdx, 0x2d)
                            outputIdx := add(outputIdx, 0x1)
                        }
                        let length := 1
                        let a := vx
                        if gt(a, 9999) {
                            length := add(length, 4)
                            a := div(a, 10000)
                        }
                        if gt(a, 99) {
                            length := add(length, 2)
                            a := div(a, 100)
                        }
                        if gt(a, 9) {
                            length := add(length, 1)
                        }
                        let p := add(outputIdx, length)
                        for {

                        } gt(p, outputIdx) {

                        } {
                            p := sub(p, 0x1)
                            mstore8(p, add(mod(vx, 10), 48))
                            vx := div(vx, 10)
                        }
                        outputIdx := add(outputIdx, length)
                    }
                    mstore8(outputIdx, 0x20)
                    outputIdx := add(outputIdx, 0x1)
                    {
                        let vy := and(
                            add(
                                mul(sub(sub(shl(1, and(hexagon, MASK_8)), shr(8, hexagon)), add(mload(MARGIN_M), 2)), 2732),
                                shr(shl(5, angle), ANGLE_TO_VERTEX_Y)
                            ),
                            MASK_32
                        )
                        if shr(31, vy) {
                            vy := and(add(not(vy), 1), MASK_32)
                            mstore8(outputIdx, 0x2d)
                            outputIdx := add(outputIdx, 0x1)
                        }
                        let length := 1
                        let a := vy
                        if gt(a, 9999) {
                            length := add(length, 4)
                            a := div(a, 10000)
                        }
                        if gt(a, 99) {
                            length := add(length, 2)
                            a := div(a, 100)
                        }
                        if gt(a, 9) {
                            length := add(length, 1)
                        }
                        let p := add(outputIdx, length)
                        for {

                        } gt(p, outputIdx) {

                        } {
                            p := sub(p, 0x1)
                            mstore8(p, add(mod(vy, 10), 48))
                            vy := div(vy, 10)
                        }
                        outputIdx := add(outputIdx, length)
                    }
                    mstore8(outputIdx, 0x6c)
                    outputIdx := add(outputIdx, 0x1)
                    let edgeCount := mload(EDGE_COUNT_M)
                    for {

                    } 1 {

                    } {
                        if and(mload(stateM), shl(angle, HEXAGON_EXPAND_MASK)) {
                            let adjusted := shr(shl(5, angle), ANGLE_EDGE_TO_VECTOR_OFFSET)
                            let offset := and(adjusted, MASK_8)
                            mstore(outputIdx, mload(add(ANGLE_EDGE_TO_VECTOR, offset)))
                            outputIdx := add(outputIdx, sub(and(shr(8, adjusted), MASK_8), offset))
                            mstore(stateM, xor(mload(stateM), shl(angle, HEXAGON_EXPAND_MASK)))
                            angle := addmod(angle, 5, 6)
                            edgeCount := sub(edgeCount, 1)
                            continue
                        }
                        if and(mload(stateM), shl(angle, HEXAGON_PERP_EXPAND_MASK)) {
                            let adjusted := shr(add(shl(5, angle), 8), ANGLE_EDGE_TO_VECTOR_OFFSET)
                            let offset := and(adjusted, MASK_8)
                            mstore(outputIdx, mload(add(ANGLE_EDGE_TO_VECTOR, offset)))
                            outputIdx := add(outputIdx, sub(and(shr(8, adjusted), MASK_8), offset))
                            mstore(stateM, xor(mload(stateM), shl(angle, HEXAGON_PERP_EXPAND_MASK)))
                            stateM := and(shr(add(shl(4, angle), STATE_OFFSET), mload(stateM)), MASK_16)
                            angle := addmod(angle, 2, 6)
                            edgeCount := sub(edgeCount, 1)
                            continue
                        }
                        let stateR1M := and(shr(add(shl(4, addmod(angle, 1, 6)), STATE_OFFSET), mload(stateM)), MASK_16)
                        if and(mload(stateR1M), shl(addmod(angle, 4, 6), HEXAGON_PERP_EXPAND_MASK)) {
                            let adjusted := shr(add(shl(5, angle), 16), ANGLE_EDGE_TO_VECTOR_OFFSET)
                            let offset := and(adjusted, MASK_8)
                            mstore(outputIdx, mload(add(ANGLE_EDGE_TO_VECTOR, offset)))
                            outputIdx := add(outputIdx, sub(and(shr(8, adjusted), MASK_8), offset))
                            stateM := stateR1M
                            angle := addmod(angle, 4, 6)
                            mstore(stateM, xor(mload(stateM), shl(angle, HEXAGON_PERP_EXPAND_MASK)))
                            edgeCount := sub(edgeCount, 1)
                            continue
                        }
                        if and(mload(stateM), shl(addmod(angle, 1, 6), HEXAGON_EXPAND_MASK)) {
                            let adjusted := shr(add(shl(5, angle), 24), ANGLE_EDGE_TO_VECTOR_OFFSET)
                            let offset := and(adjusted, MASK_8)
                            mstore(outputIdx, mload(add(ANGLE_EDGE_TO_VECTOR, offset)))
                            outputIdx := add(outputIdx, sub(and(shr(8, adjusted), MASK_8), offset))
                            angle := addmod(angle, 1, 6)
                            mstore(stateM, xor(mload(stateM), shl(angle, HEXAGON_EXPAND_MASK)))
                            edgeCount := sub(edgeCount, 1)
                            continue
                        }
                        break
                    }
                    mstore(EDGE_COUNT_M, edgeCount)
                    if iszero(edgeCount) {
                        break
                    }
                }
                mstore(outputIdx, '" fill="#')
                outputIdx := add(outputIdx, 0x9)
                mstore(outputIdx, mload(add(mload(PALETTE_M), mul(sub(mload(COLOR_M), 1), 0x6))))
                outputIdx := add(outputIdx, 0x6)
                mstore(outputIdx, '"/>')
                outputIdx := add(outputIdx, 0x3)
                mstore(OUTPUT_IDX_M, outputIdx)
            }
            if mload(OPEN_M) {
                mstore(RANDOM_SOURCE, keccak256(RANDOM_SOURCE, 0x20))
                mstore(SHIFT_M, 0)
                let sampleCount := mul(mload(DIM_M), mload(DIM_M))
                for {
                    let i
                } lt(i, sampleCount) {
                    i := add(i, 1)
                } {
                    let shift := mload(SHIFT_M)
                    let stateM := add(
                        mload(UNROLLED_GRID_M),
                        shl(
                            5,
                            shr(
                                16,
                                mul(mul(mload(UNROLLED_GRID_ROWS_M), mload(UNROLLED_GRID_COLS_M)), and(shr(shift, mload(RANDOM_SOURCE)), MASK_16))
                            )
                        )
                    )
                    shift := add(shift, 16)
                    if eq(shift, 256) {
                        mstore(RANDOM_SOURCE, keccak256(RANDOM_SOURCE, 0x20))
                        shift := 0
                    }
                    mstore(SHIFT_M, shift)
                    let colorStateM := and(shr(SELF_OFFSET, mload(stateM)), MASK_16)
                    if and(gt(colorStateM, 0), gt(and(mload(colorStateM), HEXAGON_PAINT_MASK), 0)) {
                        mstore(COLOR_M, and(shr(HEXAGON_PAINT_OFFSET, mload(colorStateM)), MASK_4))
                        mstore(colorStateM, xor(mload(colorStateM), shl(HEXAGON_PAINT_OFFSET, mload(COLOR_M))))
                        mstore(mload(STACK_IDX_M), shl(232, stateM))
                        mstore(STACK_IDX_M, add(mload(STACK_IDX_M), 0x3))
                        mstore(CACHE_IDX_M, mload(CACHE_M))
                        expandDF()
                        writeBoundary()
                    }
                }
            }
            let unrolledGridEnd := mload(STACK_M)
            for {
                let stateM := mload(UNROLLED_GRID_M)
            } lt(stateM, unrolledGridEnd) {
                stateM := add(stateM, 0x20)
            } {
                if iszero(and(mload(stateM), shl(EXPAND_ROOT_OFFSET, 1))) {
                    continue
                }
                let colorStateM := and(shr(SELF_OFFSET, mload(stateM)), MASK_16)
                if and(mload(colorStateM), HEXAGON_PAINT_MASK) {
                    mstore(COLOR_M, and(shr(HEXAGON_PAINT_OFFSET, mload(colorStateM)), MASK_4))
                    mstore(colorStateM, xor(mload(colorStateM), shl(HEXAGON_PAINT_OFFSET, mload(COLOR_M))))
                    mstore(mload(STACK_IDX_M), shl(232, stateM))
                    mstore(STACK_IDX_M, add(mload(STACK_IDX_M), 0x3))
                    mstore(CACHE_IDX_M, mload(CACHE_M))
                    expandDF()
                    writeBoundary()
                }
                for {
                    let angle
                } lt(angle, 3) {
                    angle := add(angle, 1)
                } {
                    if and(mload(colorStateM), shl(shl(2, angle), SQUARE_PAINT_MASK)) {
                        mstore(COLOR_M, and(shr(add(shl(2, angle), SQUARE_PAINT_OFFSET), mload(colorStateM)), MASK_4))
                        mstore(colorStateM, xor(mload(colorStateM), shl(add(shl(2, angle), SQUARE_PAINT_OFFSET), mload(COLOR_M))))
                        mstore(mload(STACK_IDX_M), shl(232, or(or(0x100000, shl(16, angle)), stateM)))
                        mstore(STACK_IDX_M, add(mload(STACK_IDX_M), 0x3))
                        mstore(CACHE_IDX_M, mload(CACHE_M))
                        expandDF()
                        writeBoundary()
                    }
                    if and(lt(angle, 2), gt(and(mload(colorStateM), shl(shl(2, angle), TRIANGLE_PAINT_MASK)), 0)) {
                        mstore(COLOR_M, and(shr(add(shl(2, angle), TRIANGLE_PAINT_OFFSET), mload(colorStateM)), MASK_4))
                        mstore(colorStateM, xor(mload(colorStateM), shl(add(shl(2, angle), TRIANGLE_PAINT_OFFSET), mload(COLOR_M))))
                        mstore(mload(STACK_IDX_M), shl(232, or(or(0x200000, shl(16, angle)), stateM)))
                        mstore(STACK_IDX_M, add(mload(STACK_IDX_M), 0x3))
                        mstore(CACHE_IDX_M, mload(CACHE_M))
                        expandDF()
                        writeBoundary()
                    }
                }
            }
        }
    }

    function writeDecimalLookup() internal pure {
        assembly {
            // Assume z is signed 32-bit and |z| < 10 ** 8
            function writeDecimal(z, decimalM, decimalLengthM) {
                let outputIdx := mload(OUTPUT_IDX_M)
                mstore(decimalM, outputIdx)
                if shr(31, z) {
                    z := and(add(not(z), 1), MASK_32)
                    mstore8(outputIdx, 0x2d)
                    outputIdx := add(outputIdx, 0x1)
                }
                let length := 1
                let a := z
                if gt(a, 9999) {
                    length := add(length, 4)
                    a := div(a, 10000)
                }
                if gt(a, 99) {
                    length := add(length, 2)
                    a := div(a, 100)
                }
                if gt(a, 9) {
                    length := add(length, 1)
                }
                let p := add(outputIdx, length)
                for {

                } gt(p, outputIdx) {

                } {
                    p := sub(p, 0x1)
                    mstore8(p, add(mod(z, 10), 48))
                    z := div(z, 10)
                }
                outputIdx := add(outputIdx, length)
                mstore(decimalLengthM, sub(outputIdx, mload(decimalM)))
                mstore(OUTPUT_IDX_M, outputIdx)
            }
            writeDecimal(mul(sub(0, add(mload(MARGIN_M), 2)), 4732), OPEN_VIEW_BOX_X_DECIMAL_M, OPEN_VIEW_BOX_X_DECIMAL_LENGTH_M)
            writeDecimal(mul(sub(0, add(mload(MARGIN_M), 4)), 2732), OPEN_VIEW_BOX_Y_DECIMAL_M, OPEN_VIEW_BOX_Y_DECIMAL_LENGTH_M)
            writeDecimal(
                mul(add(add(mload(DIM_M), 3), shl(1, mload(MARGIN_M))), 4732),
                OPEN_VIEW_BOX_WIDTH_DECIMAL_M,
                OPEN_VIEW_BOX_WIDTH_DECIMAL_LENGTH_M
            )
            writeDecimal(mul(add(add(mload(DIM_M), 3), mload(MARGIN_M)), 5464), OPEN_VIEW_BOX_HEIGHT_DECIMAL_M, OPEN_VIEW_BOX_HEIGHT_DECIMAL_LENGTH_M)
            writeDecimal(mul(mload(DIM_M), 4732), DOMAIN_WIDTH_DECIMAL_M, DOMAIN_WIDTH_DECIMAL_LENGTH_M)
            writeDecimal(mul(mload(DIM_M), 5464), DOMAIN_HEIGHT_DECIMAL_M, DOMAIN_HEIGHT_DECIMAL_LENGTH_M)
            writeDecimal(mload(TOKEN_ID_M), TOKEN_ID_DECIMAL_M, TOKEN_ID_DECIMAL_LENGTH_M)
            writeDecimal(mload(DIM_M), DIM_DECIMAL_M, DIM_DECIMAL_LENGTH_M)
            writeDecimal(mload(PALETTE_IDX_M), PALETTE_IDX_DECIMAL_M, PALETTE_IDX_DECIMAL_LENGTH_M)
        }
    }

    function writePreExpand() internal pure {
        assembly {
            let outputIdx := mload(OUTPUT_IDX_M)
            // '<svg xmlns="http://www.w3.org/2000/svg" viewBox="'
            mstore(outputIdx, mload(mload(SVG_STRING_LOOKUP_M)))
            outputIdx := add(outputIdx, 0x20)
            mstore(outputIdx, mload(add(mload(SVG_STRING_LOOKUP_M), 0x20)))
            outputIdx := add(outputIdx, 0x11)
            switch mload(OPEN_M)
            case 0 {
                // '-2732 -2732 '
                mstore(outputIdx, mload(add(mload(SVG_STRING_LOOKUP_M), 0xfa)))
                outputIdx := add(outputIdx, 0xc)
                mstore(outputIdx, mload(mload(DOMAIN_WIDTH_DECIMAL_M)))
                outputIdx := add(outputIdx, mload(DOMAIN_WIDTH_DECIMAL_LENGTH_M))
                mstore8(outputIdx, 0x20)
                outputIdx := add(outputIdx, 0x1)
                mstore(outputIdx, mload(mload(DOMAIN_HEIGHT_DECIMAL_M)))
                outputIdx := add(outputIdx, mload(DOMAIN_HEIGHT_DECIMAL_LENGTH_M))
                // '">'
                mstore(outputIdx, mload(add(mload(SVG_STRING_LOOKUP_M), 0x31)))
                outputIdx := add(outputIdx, 0x2)
            }
            case 1 {
                mstore(outputIdx, mload(mload(OPEN_VIEW_BOX_X_DECIMAL_M)))
                outputIdx := add(outputIdx, mload(OPEN_VIEW_BOX_X_DECIMAL_LENGTH_M))
                mstore8(outputIdx, 0x20)
                outputIdx := add(outputIdx, 0x1)
                mstore(outputIdx, mload(mload(OPEN_VIEW_BOX_Y_DECIMAL_M)))
                outputIdx := add(outputIdx, mload(OPEN_VIEW_BOX_Y_DECIMAL_LENGTH_M))
                mstore8(outputIdx, 0x20)
                outputIdx := add(outputIdx, 0x1)
                mstore(outputIdx, mload(mload(OPEN_VIEW_BOX_WIDTH_DECIMAL_M)))
                outputIdx := add(outputIdx, mload(OPEN_VIEW_BOX_WIDTH_DECIMAL_LENGTH_M))
                mstore8(outputIdx, 0x20)
                outputIdx := add(outputIdx, 0x1)
                mstore(outputIdx, mload(mload(OPEN_VIEW_BOX_HEIGHT_DECIMAL_M)))
                outputIdx := add(outputIdx, mload(OPEN_VIEW_BOX_HEIGHT_DECIMAL_LENGTH_M))
                // '"><rect x="'
                mstore(outputIdx, mload(add(mload(SVG_STRING_LOOKUP_M), 0x31)))
                outputIdx := add(outputIdx, 0xb)
                mstore(outputIdx, mload(mload(OPEN_VIEW_BOX_X_DECIMAL_M)))
                outputIdx := add(outputIdx, mload(OPEN_VIEW_BOX_X_DECIMAL_LENGTH_M))
                // '" y="'
                mstore(outputIdx, mload(add(mload(SVG_STRING_LOOKUP_M), 0x41)))
                outputIdx := add(outputIdx, 0x5)
                mstore(outputIdx, mload(mload(OPEN_VIEW_BOX_Y_DECIMAL_M)))
                outputIdx := add(outputIdx, mload(OPEN_VIEW_BOX_Y_DECIMAL_LENGTH_M))
                // '" width="'
                mstore(outputIdx, mload(add(mload(SVG_STRING_LOOKUP_M), 0x4b)))
                outputIdx := add(outputIdx, 0x9)
                mstore(outputIdx, mload(mload(OPEN_VIEW_BOX_WIDTH_DECIMAL_M)))
                outputIdx := add(outputIdx, mload(OPEN_VIEW_BOX_WIDTH_DECIMAL_LENGTH_M))
                // '" height="'
                mstore(outputIdx, mload(add(mload(SVG_STRING_LOOKUP_M), 0x54)))
                outputIdx := add(outputIdx, 0xa)
                mstore(outputIdx, mload(mload(OPEN_VIEW_BOX_HEIGHT_DECIMAL_M)))
                outputIdx := add(outputIdx, mload(OPEN_VIEW_BOX_HEIGHT_DECIMAL_LENGTH_M))
                // '" fill="white"/>'
                mstore(outputIdx, mload(add(mload(SVG_STRING_LOOKUP_M), 0x5e)))
                outputIdx := add(outputIdx, 0x10)
                // '<rect x="-2732" y="-2732" width='
                mstore(outputIdx, mload(add(mload(SVG_STRING_LOOKUP_M), 0x33)))
                outputIdx := add(outputIdx, 0x20)
                mstore8(outputIdx, 0x22)
                outputIdx := add(outputIdx, 0x1)
                mstore(outputIdx, mload(mload(DOMAIN_WIDTH_DECIMAL_M)))
                outputIdx := add(outputIdx, mload(DOMAIN_WIDTH_DECIMAL_LENGTH_M))
                // '" height="'
                mstore(outputIdx, mload(add(mload(SVG_STRING_LOOKUP_M), 0x54)))
                outputIdx := add(outputIdx, 0xa)
                mstore(outputIdx, mload(mload(DOMAIN_HEIGHT_DECIMAL_M)))
                outputIdx := add(outputIdx, mload(DOMAIN_HEIGHT_DECIMAL_LENGTH_M))
                // '" '
                mstore(outputIdx, mload(add(mload(SVG_STRING_LOOKUP_M), 0x5e)))
                outputIdx := add(outputIdx, 0x2)
                // 'stroke="black" stroke-width="100'
                mstore(outputIdx, mload(add(mload(SVG_STRING_LOOKUP_M), 0x71)))
                outputIdx := add(outputIdx, 0x20)
                // '" fill="white"/>'
                mstore(outputIdx, mload(add(mload(SVG_STRING_LOOKUP_M), 0x5e)))
                outputIdx := add(outputIdx, 0x10)
            }
            // '<g stroke="black" stroke-width="100" stroke-linejoin="round" stroke-linecap="round" fill-rule="evenodd">'
            mstore(outputIdx, mload(add(mload(SVG_STRING_LOOKUP_M), 0x6e)))
            outputIdx := add(outputIdx, 0x20)
            mstore(outputIdx, mload(add(mload(SVG_STRING_LOOKUP_M), 0x8e)))
            outputIdx := add(outputIdx, 0x20)
            mstore(outputIdx, mload(add(mload(SVG_STRING_LOOKUP_M), 0xae)))
            outputIdx := add(outputIdx, 0x20)
            mstore(outputIdx, mload(add(mload(SVG_STRING_LOOKUP_M), 0xce)))
            outputIdx := add(outputIdx, 0x8)
            mstore(OUTPUT_IDX_M, outputIdx)
        }
    }

    function writePostExpand() internal pure {
        assembly {
            let outputIdx := mload(OUTPUT_IDX_M)
            // '</g>'
            mstore(outputIdx, mload(add(mload(SVG_STRING_LOOKUP_M), 0xeb)))
            outputIdx := add(outputIdx, 0x4)
            if iszero(mload(OPEN_M)) {
                // '<path d="'
                mstore(outputIdx, mload(add(mload(SVG_STRING_LOOKUP_M), 0xd6)))
                outputIdx := add(outputIdx, 0x9)
                mstore8(outputIdx, 0x4d)
                outputIdx := add(outputIdx, 0x1)
                mstore(outputIdx, mload(mload(OPEN_VIEW_BOX_X_DECIMAL_M)))
                outputIdx := add(outputIdx, mload(OPEN_VIEW_BOX_X_DECIMAL_LENGTH_M))
                mstore8(outputIdx, 0x20)
                outputIdx := add(outputIdx, 0x1)
                mstore(outputIdx, mload(mload(OPEN_VIEW_BOX_Y_DECIMAL_M)))
                outputIdx := add(outputIdx, mload(OPEN_VIEW_BOX_Y_DECIMAL_LENGTH_M))
                mstore8(outputIdx, 0x6c)
                outputIdx := add(outputIdx, 0x1)
                mstore(outputIdx, mload(mload(OPEN_VIEW_BOX_WIDTH_DECIMAL_M)))
                outputIdx := add(outputIdx, mload(OPEN_VIEW_BOX_WIDTH_DECIMAL_LENGTH_M))
                // ' 0 0 '
                mstore(outputIdx, mload(add(mload(SVG_STRING_LOOKUP_M), 0xf5)))
                outputIdx := add(outputIdx, 0x5)
                mstore(outputIdx, mload(mload(OPEN_VIEW_BOX_HEIGHT_DECIMAL_M)))
                outputIdx := add(outputIdx, mload(OPEN_VIEW_BOX_HEIGHT_DECIMAL_LENGTH_M))
                // ' -'
                mstore(outputIdx, mload(add(mload(SVG_STRING_LOOKUP_M), 0xf9)))
                outputIdx := add(outputIdx, 0x2)
                mstore(outputIdx, mload(mload(OPEN_VIEW_BOX_WIDTH_DECIMAL_M)))
                outputIdx := add(outputIdx, mload(OPEN_VIEW_BOX_WIDTH_DECIMAL_LENGTH_M))
                // ' 0 0 -'
                mstore(outputIdx, mload(add(mload(SVG_STRING_LOOKUP_M), 0xf5)))
                outputIdx := add(outputIdx, 0x6)
                mstore(outputIdx, mload(mload(OPEN_VIEW_BOX_HEIGHT_DECIMAL_M)))
                outputIdx := add(outputIdx, mload(OPEN_VIEW_BOX_HEIGHT_DECIMAL_LENGTH_M))
                // 'M-2732 -2732l0 '
                mstore(outputIdx, mload(add(mload(SVG_STRING_LOOKUP_M), 0x106)))
                outputIdx := add(outputIdx, 0xf)
                mstore(outputIdx, mload(mload(DOMAIN_HEIGHT_DECIMAL_M)))
                outputIdx := add(outputIdx, mload(DOMAIN_HEIGHT_DECIMAL_LENGTH_M))
                mstore8(outputIdx, 0x20)
                outputIdx := add(outputIdx, 0x1)
                mstore(outputIdx, mload(mload(DOMAIN_WIDTH_DECIMAL_M)))
                outputIdx := add(outputIdx, mload(DOMAIN_WIDTH_DECIMAL_LENGTH_M))
                // ' 0 0 -'
                mstore(outputIdx, mload(add(mload(SVG_STRING_LOOKUP_M), 0xf5)))
                outputIdx := add(outputIdx, 0x6)
                mstore(outputIdx, mload(mload(DOMAIN_HEIGHT_DECIMAL_M)))
                outputIdx := add(outputIdx, mload(DOMAIN_HEIGHT_DECIMAL_LENGTH_M))
                // ' -'
                mstore(outputIdx, mload(add(mload(SVG_STRING_LOOKUP_M), 0xf9)))
                outputIdx := add(outputIdx, 0x2)
                mstore(outputIdx, mload(mload(DOMAIN_WIDTH_DECIMAL_M)))
                outputIdx := add(outputIdx, mload(DOMAIN_WIDTH_DECIMAL_LENGTH_M))
                // ' 0'
                mstore(outputIdx, mload(add(mload(SVG_STRING_LOOKUP_M), 0xf5)))
                outputIdx := add(outputIdx, 0x2)
                // '" fill="white"/>'
                mstore(outputIdx, mload(add(mload(SVG_STRING_LOOKUP_M), 0x5e)))
                outputIdx := add(outputIdx, 0x10)
            }
            // '</svg>'
            mstore(outputIdx, mload(add(mload(SVG_STRING_LOOKUP_M), 0xef)))
            outputIdx := add(outputIdx, 0x6)
            mstore(outputIdx, 0)
            mstore(OUTPUT_IDX_M, outputIdx)
            mstore(SVG_START_M, mload(OUTPUT_M))
            mstore(SVG_END_M, outputIdx)
        }
    }

    function writeJSON() internal pure {
        assembly {
            let outputIdx := mload(OUTPUT_IDX_M)
            // 'data:application/json,%7B%22name%22:%22Tiling%20'
            mstore(outputIdx, mload(mload(JSON_STRING_LOOKUP_M)))
            outputIdx := add(outputIdx, 0x20)
            mstore(outputIdx, mload(add(mload(JSON_STRING_LOOKUP_M), 0x20)))
            outputIdx := add(outputIdx, 0x10)
            mstore(outputIdx, mload(mload(TOKEN_ID_DECIMAL_M)))
            outputIdx := add(outputIdx, mload(TOKEN_ID_DECIMAL_LENGTH_M))
            // '%22,%22description%22:%22Hexamillennia%20is%20generated%20entirely%20on%20the%20EVM.%20Released%20under%20CC0.%22,%22attributes%22:%5B%7B%22trait_type%22:%22'
            mstore(outputIdx, mload(add(mload(JSON_STRING_LOOKUP_M), 0x30)))
            outputIdx := add(outputIdx, 0x20)
            mstore(outputIdx, mload(add(mload(JSON_STRING_LOOKUP_M), 0x50)))
            outputIdx := add(outputIdx, 0x20)
            mstore(outputIdx, mload(add(mload(JSON_STRING_LOOKUP_M), 0x70)))
            outputIdx := add(outputIdx, 0x20)
            mstore(outputIdx, mload(add(mload(JSON_STRING_LOOKUP_M), 0x90)))
            outputIdx := add(outputIdx, 0x20)
            mstore(outputIdx, mload(add(mload(JSON_STRING_LOOKUP_M), 0xb0)))
            outputIdx := add(outputIdx, 0x1d)
            // 'Size'
            mstore(outputIdx, mload(add(mload(JSON_STRING_LOOKUP_M), 0x14a)))
            outputIdx := add(outputIdx, 0x4)
            // '%22,%22value%22:%22'
            mstore(outputIdx, mload(add(mload(JSON_STRING_LOOKUP_M), 0xcd)))
            outputIdx := add(outputIdx, 0x13)
            mstore(outputIdx, mload(mload(DIM_DECIMAL_M)))
            outputIdx := add(outputIdx, mload(DIM_DECIMAL_LENGTH_M))
            // '%22%7D,%7B%22trait_type%22:%22'
            mstore(outputIdx, mload(add(mload(JSON_STRING_LOOKUP_M), 0xe0)))
            outputIdx := add(outputIdx, 0x1e)
            // 'Form'
            mstore(outputIdx, mload(add(mload(JSON_STRING_LOOKUP_M), 0x14e)))
            outputIdx := add(outputIdx, 0x4)
            // '%22,%22value%22:%22'
            mstore(outputIdx, mload(add(mload(JSON_STRING_LOOKUP_M), 0xcd)))
            outputIdx := add(outputIdx, 0x13)
            switch mload(OPEN_M)
            case 0 {
                // 'Closed'
                mstore(outputIdx, mload(add(mload(JSON_STRING_LOOKUP_M), 0x15e)))
                outputIdx := add(outputIdx, 0x6)
            }
            case 1 {
                // 'Open'
                mstore(outputIdx, mload(add(mload(JSON_STRING_LOOKUP_M), 0x164)))
                outputIdx := add(outputIdx, 0x4)
            }
            // '%22%7D,%7B%22trait_type%22:%22'
            mstore(outputIdx, mload(add(mload(JSON_STRING_LOOKUP_M), 0xe0)))
            outputIdx := add(outputIdx, 0x1e)
            // 'Steps'
            mstore(outputIdx, mload(add(mload(JSON_STRING_LOOKUP_M), 0x152)))
            outputIdx := add(outputIdx, 0x5)
            // '%22,%22value%22:%22'
            mstore(outputIdx, mload(add(mload(JSON_STRING_LOOKUP_M), 0xcd)))
            outputIdx := add(outputIdx, 0x13)
            switch mload(STEPS_IDX_M)
            case 0 {
                // 'Low'
                mstore(outputIdx, mload(add(mload(JSON_STRING_LOOKUP_M), 0x168)))
                outputIdx := add(outputIdx, 0x3)
            }
            case 1 {
                // 'Medium'
                mstore(outputIdx, mload(add(mload(JSON_STRING_LOOKUP_M), 0x16b)))
                outputIdx := add(outputIdx, 0x6)
            }
            case 2 {
                // 'High'
                mstore(outputIdx, mload(add(mload(JSON_STRING_LOOKUP_M), 0x171)))
                outputIdx := add(outputIdx, 0x4)
            }
            // '%22%7D,%7B%22trait_type%22:%22'
            mstore(outputIdx, mload(add(mload(JSON_STRING_LOOKUP_M), 0xe0)))
            outputIdx := add(outputIdx, 0x1e)
            // 'Palette'
            mstore(outputIdx, mload(add(mload(JSON_STRING_LOOKUP_M), 0x157)))
            outputIdx := add(outputIdx, 0x7)
            // '%22,%22value%22:%22'
            mstore(outputIdx, mload(add(mload(JSON_STRING_LOOKUP_M), 0xcd)))
            outputIdx := add(outputIdx, 0x13)
            mstore(outputIdx, mload(mload(PALETTE_IDX_DECIMAL_M)))
            outputIdx := add(outputIdx, mload(PALETTE_IDX_DECIMAL_LENGTH_M))
            // '%22%7D%5D,%22image%22:%22data:image/svg+xml;base64,'
            mstore(outputIdx, mload(add(mload(JSON_STRING_LOOKUP_M), 0x111)))
            outputIdx := add(outputIdx, 0x20)
            mstore(outputIdx, mload(add(mload(JSON_STRING_LOOKUP_M), 0x131)))
            outputIdx := add(outputIdx, 0x13)
            // Base64 encode
            //
            // Adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Base64.sol
            let end := sub(mload(SVG_END_M), 0x20)
            for {
                let svgIdx := sub(mload(SVG_START_M), 0x20)
            } lt(svgIdx, end) {

            } {
                svgIdx := add(svgIdx, 0x3)
                let input := mload(svgIdx)
                mstore8(outputIdx, mload(add(BASE64, and(shr(18, input), MASK_6))))
                mstore8(add(outputIdx, 0x1), mload(add(BASE64, and(shr(12, input), MASK_6))))
                mstore8(add(outputIdx, 0x2), mload(add(BASE64, and(shr(6, input), MASK_6))))
                mstore8(add(outputIdx, 0x3), mload(add(BASE64, and(input, MASK_6))))
                outputIdx := add(outputIdx, 0x4)
            }
            switch mod(sub(mload(SVG_END_M), mload(SVG_START_M)), 3)
            case 1 {
                mstore8(sub(outputIdx, 0x1), 0x3d)
                mstore8(sub(outputIdx, 0x2), 0x3d)
            }
            case 2 {
                mstore8(sub(outputIdx, 0x1), 0x3d)
            }
            // '%22%7D'
            mstore(outputIdx, mload(add(mload(JSON_STRING_LOOKUP_M), 0x144)))
            outputIdx := add(outputIdx, 0x6)
            mstore(outputIdx, 0)
            mstore(OUTPUT_IDX_M, outputIdx)
        }
    }

    function resetOutput() internal pure {
        assembly {
            mstore(OUTPUT_M, add(mload(OUTPUT_IDX_M), 0x40))
            mstore(OUTPUT_IDX_M, mload(OUTPUT_M))
        }
    }

    function returnOutput() internal pure {
        assembly {
            let output := mload(OUTPUT_M)
            let length := sub(mload(OUTPUT_IDX_M), output)
            mstore(sub(output, 0x40), 0x20)
            mstore(sub(output, 0x20), length)
            return(sub(output, 0x40), add(shl(5, shr(5, add(length, 31))), 0x40))
        }
    }
}