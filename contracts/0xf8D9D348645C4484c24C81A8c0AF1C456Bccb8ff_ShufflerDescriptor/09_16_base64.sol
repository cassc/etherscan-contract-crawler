// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**************************************************************************
...........................................................................
...........................................................................
...........................................................................
...........................................................................
.....................     ...............      .......      ...............
...................  .?5?:  ........... .::::::. ... .:::::.  .............
.................  :?B&@&B?:  ....... .^7??????!:. .~7??????~: ............
...............  :J#&&&&&&&#J:  .....^7??????JJJ?!!7????JJJ?J?!............
.............  ^Y#&&&&&&&&&&&#Y^  .. !J??YGGP^^~?JJ?5GGJ^^~????: ..........
...........  ^5&@&&&&&&&&&&&&&@&5~   [email protected]@B. [email protected]@Y  :????:...........
.......... :5&&BBB###&&&&#BBB###&&P: [email protected]@B. [email protected]@Y  :???7............
......... ^P&&#:..7J?G&&&5..:??J#&&G~ ~??J55Y!!!????Y5PJ!!!??7.............
......... [email protected]&&#.  7??G&&&5  :??J#&&@7  ^?????JJJ????????JJJ?7..............
......... [email protected]&&#~^^JYJB&&&P^^~JYY#&&@7 ..:~?J??????????????7^...............
......... :JB&&&&&&&&B#&#B&&&&&&&&#J: ..  .~?J????????J?!:. ...............
..........  :?BBBBBB5YB&BY5BBBBBB?:  .....  .~77???J?7!:. .................
............  ....^Y#@@&@@#Y^....  .......... ..^!7~:.. ...................
..............   .!777???777!.   ............   :^^^.   ...................
..................  .^7?7^.  .............. .~Y5#&&&G57: ..................
................  :~???????~:  .............!&&&&&&&&@@5:..................
.............. .:!?J???????J?!:  ......... ~&&&&&&&&&&&@5 .................
............ .:!??JJJ????????J?!:. ......  ^B&&&&&&&&&&&J  ................
............^!JGBG!^^7???YBBP^^~?!^. .   .^^~YG&&&&&&#57^^:   .............
......... :7??J&&&^  [email protected]@B. .?J?7: :?5G&&&#PY#&&&P5B&&&#5Y^ ............
...........~7?J&&&^  [email protected]@B. .?J?~.:Y&@G77?555#&&&Y!7J55P&&#~............
........... .^75557!!7???J55Y!!!7~.  [email protected]&&5  .???#&&&7  ^??Y&&&&: ..........
............. .^7?JJ?????????J7^. .. J&&&5  .??J#&&&7  ^??Y&&&G: ..........
............... .^7?J???????7^. ..... ?#@#55PBG5#&&&5J5PBBB&&P: ...........
................. .:!?JJJ?!:. ........ ^!JBBBGYP&&&&B5PBBBP!!. ............
................... .:!7!:. ...........   ..:JGBGGGGBG5~ ..   .............
..................... ... ................. ............ ..................
...........................................................................
...........................................................................
...........................................................................
...........................................................................
***************************************************************************/

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }

    // optimized decoder, one pass base64 decode and json string retrieval
    // target: chainrunner
    // input: base64 encoded json with format
    //        {"name":"Runner #0", "description":"Chain Runners", "image_data": "<begin></end>"}
    // output: base64 string from the "image_data" field, i.e. "<begin></end>"
    function decodeGetJsonImageData(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes((data.length / 4) * 3 + 32);

        assembly {
            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            let state := 0 // FSM state
            let resultLen := 0
            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                let threeChar := shl(232, output)

                for { let i := 0 } lt(i, 3) { i := add(i, 1) } {
                    let b := byte(i, threeChar)

                    switch state
                        // "
                        case 0 { switch eq(and(b, 0xFF), 0x22) case 1 { state := add(state, 1) } }
                        // i
                        case 1 { switch eq(and(b, 0xFF), 0x69) case 1 { state := add(state, 1) } case 0 { state := 0 } }
                        // m
                        case 2 { switch eq(and(b, 0xFF), 0x6d) case 1 { state := add(state, 1) } case 0 { state := 0 } }
                        // a
                        case 3 { switch eq(and(b, 0xFF), 0x61) case 1 { state := add(state, 1) } case 0 { state := 0 } }
                        // g
                        case 4 { switch eq(and(b, 0xFF), 0x67) case 1 { state := add(state, 1) } case 0 { state := 0 } }
                        // e
                        case 5 { switch eq(and(b, 0xFF), 0x65) case 1 { state := add(state, 1) } case 0 { state := 0 } }
                        // _
                        case 6 { switch eq(and(b, 0xFF), 0x5f) case 1 { state := add(state, 1) } case 0 { state := 0 } }
                        // d
                        case 7 { switch eq(and(b, 0xFF), 0x64) case 1 { state := add(state, 1) } case 0 { state := 0 } }
                        // a
                        case 8 { switch eq(and(b, 0xFF), 0x61) case 1 { state := add(state, 1) } case 0 { state := 0 } }
                        // t
                        case 9 { switch eq(and(b, 0xFF), 0x74) case 1 { state := add(state, 1) } case 0 { state := 0 } }
                        // a
                        case 10 { switch eq(and(b, 0xFF), 0x61) case 1 { state := add(state, 1) } case 0 { state := 0 } }
                        // "
                        case 11 { switch eq(and(b, 0xFF), 0x22) case 1 { state := add(state, 1) } case 0 { state := 0 } }
                        // until "
                        case 12 { switch eq(and(b, 0xFF), 0x22) case 1 { state := add(state, 1) } case 0 {  } }
                        // store char string until "
                        case 13 { switch eq(and(b, 0xFF), 0x22) case 1 { state := add(state, 1) } case 0 {
                            mstore(resultPtr, shl(248, b)) resultPtr := add(resultPtr, 1) resultLen := add(resultLen, 1) }
                        }
                        default { }
                }
            }
            mstore(result, resultLen)
        }
        return result;
    }

    // optimized decoder: one pass decode, string slicing and decode
    // input: base64 encoded json with format
    //        {"name":"Noun 0", "description":"Nouns DAO", "image": "data:image/svg+xml;base64,aGVsbG8="}
    // output: decoded base64 string from the "image" field, i.e. "hello"
    //
    // NOTE: current implementation assume "=" padding at the end
    // ref: Decoding Base64 with padding, https://en.wikipedia.org/wiki/Base64
    function decodeGetJsonImgDecoded(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes((data.length / 4) * 3 + 32);

        assembly {
            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            let state := 0 // FSM state
            let resultLen := 0
            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )

                input := 0
                for { let i := 0 } lt(i, 3) { i := add(i, 1) } {
                    let b := byte(i, shl(232, output)) // top three char

                    switch state
                        // "
                        case 0 { switch eq(and(b, 0xFF), 0x22) case 1 { state := add(state, 1) } }
                        // i
                        case 1 { switch eq(and(b, 0xFF), 0x69) case 1 { state := add(state, 1) } case 0 { state := 0 } }
                        // m
                        case 2 { switch eq(and(b, 0xFF), 0x6d) case 1 { state := add(state, 1) } case 0 { state := 0 } }
                        // a
                        case 3 { switch eq(and(b, 0xFF), 0x61) case 1 { state := add(state, 1) } case 0 { state := 0 } }
                        // g
                        case 4 { switch eq(and(b, 0xFF), 0x67) case 1 { state := add(state, 1) } case 0 { state := 0 } }
                        // e
                        case 5 { switch eq(and(b, 0xFF), 0x65) case 1 { state := add(state, 1) } case 0 { state := 0 } }
                        // "
                        case 6 { switch eq(and(b, 0xFF), 0x22) case 1 { state := add(state, 1) } case 0 { state := 0 } }
                        // until ,
                        case 7 { switch eq(and(b, 0xFF), 0x2c) case 1 { state := add(state, 1) } case 0 {  } }
                        // start processing embeded base64 string, until "
                        case 8 { switch eq(and(b, 0xFF), 0x22) // if "
                            case 1 { state := 100 } // exit
                            case 0 { // store 1st char
                                mstore8(resultPtr, b)
                                resultPtr := add(resultPtr, 1)
                                state := add(state, 1)
                            }
                        }
                        case 9 { // store 2nd char
                            mstore8(resultPtr, b)
                            resultPtr := add(resultPtr, 1)
                            state := add(state, 1)
                        }

                        case 10 { switch eq(and(b, 0xFF), 0x3d) // if =
                            case 1 { // decode and exit
                                resultPtr := sub(resultPtr, 2)
                                input := shr(224, mload(resultPtr))
                                data := add(
                                    add(
                                        shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                                        shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                                    add(
                                        shl(6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                                    )
                                )
                                mstore(resultPtr, shl(232, data))
                                resultLen := add(resultLen, 1)
                                state := 100
                            } case 0 { // store 3rd char
                                mstore8(resultPtr, b)
                                resultPtr := add(resultPtr, 1)
                                state := add(state, 1)
                            }
                        }
                        case 11 { switch eq(and(b, 0xFF), 0x3d) // if =
                            case 1 { // decode and exit
                                resultPtr := sub(resultPtr, 3)
                                input := shr(224, mload(resultPtr))
                                data := add(
                                    add(
                                        shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                                        shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                                    add(
                                        shl(6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                                    )
                                )
                                mstore(resultPtr, shl(232, data))
                                resultLen := add(resultLen, 2)
                                state := 100
                            } case 0 { // decode and continue parsing
                                mstore8(resultPtr, b)
                                resultPtr := add(resultPtr, 1)
                                resultPtr := sub(resultPtr, 4)
                                input := shr(224, mload(resultPtr))
                                data := add(
                                    add(
                                        shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                                        shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                                    add(
                                        shl(6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                                    )
                                )
                                mstore(resultPtr, shl(232, data))
                                resultPtr := add(resultPtr, 3)
                                resultLen := add(resultLen, 3)
                            }
                            state := 8
                        }
                        default { }
                }
            }
            mstore(result, resultLen)
        }
        return result;
    }
}