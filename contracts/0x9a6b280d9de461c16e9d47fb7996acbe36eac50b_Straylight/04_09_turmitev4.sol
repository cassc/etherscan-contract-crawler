//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./gameboard.sol";

/// @title Turmite v4
/// @notice Implementation of Turmite logic for Straylight Protocoll.
/// @author @brachlandberlin / plsdlr.net
/// @dev Every Turmite rule is for simplicity represented as 12 Bytes. For easy acess by render functions all individual turmite data is safed in an struct.

contract Turmite is Gameboard {
    // using Base64 for string;    //note what is this used for?

    mapping(uint256 => turmite) public turmites;

    event TurmiteMove(uint256 indexed tokenId, uint8 indexed boardnumber, uint256 indexed moves);

    /// @dev individual slot for every turmite
    // Layout from Example:
    // _____________________________________________________________________________________________________
    // Empty Space :)                   Rule                     State  Boardnumber  Orientation   Y     X
    // _____________________________________________________________________________________________________
    // 0x000000000000000000000000000000 ff0801ff0201ff0000000001 01     01           01            32    3a
    // _____________________________________________________________________________________________________
    //
    struct turmite {
        uint8 turposx;
        uint8 turposy;
        uint8 orientation;
        uint8 boardnumber;
        bytes1 state;
        bytes12 rule;
    }

    /// @dev grammar for the rules
    // Layout from example rule
    // Rule:
    // _________________________________________________
    // ff0801ff0201ff0000000001                            2 states / 4 rulessegments
    // _________________________________________________
    // | ff0801 | ff0201 | ff0000 | 000001 |               4 * 3 Bytes
    // _________________________________________________
    // | c d s  |  c d s |  ...                            c = color, d = direction, s = state
    // _________________________________________________
    // | c = ff  ,  d = 08  ,  s = 01 | ...
    // _________________________________________________
    //
    // written as context-sensitive grammar, with start symbol S:
    //
    //     S    	→       a  a  a
    //     a        →       c  d  s
    //     c        →       ff | 00
    //     d        →       02 | 08 | 04
    //     s        →       01 | 00

    /// @dev creates an Turmite Struct and mapping to id, every turmite gets initalized with state 0
    /// @param posx the x position of the turmite on the board
    /// @param posy the y position on the turmite on the board
    /// @param startdirection the startdirection of the turmite
    /// @param boardNumber the boardNumber number
    /// @param rule 12 Byte rule which defines behavior of the turmite
    function createTurmite(
        uint256 id,
        uint8 posx,
        uint8 posy,
        uint8 startdirection,
        uint8 boardNumber,
        bytes12 rule
    ) internal {
        bytes1 state = hex"00";
        turmites[id] = turmite(posx, posy, startdirection, boardNumber, state, rule);
    }

    /// @dev main computational logic of turmite
    /// @dev this function is internal because there should be a check to validate ownership of the turmite
    /// @param id the id of the turmite to move
    /// @param moves the number of moves
    function calculateTurmiteMove(uint256 id, uint256 moves) internal {
        bytes1 colorField;
        uint8 _x;
        uint8 _y;
        uint8 _boardNumber;
        bytes32 sour;

        turmite storage data = turmites[id];
        assembly {
            sour := sload(data.slot)
        }
        for (uint256 z = 0; z < moves; ) {
            assembly {
                _x := and(sour, 0xFF)
                _y := and(shr(8, sour), 0xFF)
                _boardNumber := shr(24, sour)
            }
            bytes1 stateOfField = getByte(_x, _y, _boardNumber);
            assembly {
                let maskedRule := and(sour, 0x000000000000000000000000000000ffffffffffffffffffffffff0000000000)

                let _orientation := and(
                    shr(16, sour),
                    0x00000000000000000000000000000000000000000000000000000000000000ff
                )

                let newState
                let newDirection

                if and(
                    eq(shr(248, stateOfField), 0x00),
                    eq(shr(32, and(sour, 0x000000000000000000000000000000000000000000000000000000ff00000000)), 0x00)
                ) {
                    colorField := shl(120, maskedRule)
                    newDirection := and(shr(120, maskedRule), 0xFF)
                    newState := and(shr(112, maskedRule), 0xFF)
                }
                if and(
                    eq(shr(248, stateOfField), 0xff),
                    eq(shr(32, and(sour, 0x000000000000000000000000000000000000000000000000000000ff00000000)), 0x00)
                ) {
                    colorField := shl(144, maskedRule)
                    newDirection := and(shr(96, maskedRule), 0xFF)
                    newState := and(shr(88, maskedRule), 0xFF)
                }
                if and(
                    eq(shr(248, stateOfField), 0x00),
                    eq(shr(32, and(sour, 0x000000000000000000000000000000000000000000000000000000ff00000000)), 0x01)
                ) {
                    colorField := shl(168, maskedRule)
                    newDirection := and(shr(72, maskedRule), 0xFF)
                    newState := and(shr(64, maskedRule), 0xFF)
                }
                if and(
                    eq(shr(248, stateOfField), 0xff),
                    eq(shr(32, and(sour, 0x000000000000000000000000000000000000000000000000000000ff00000000)), 0x01)
                ) {
                    colorField := shl(192, maskedRule)
                    newDirection := and(shr(48, maskedRule), 0xFF)
                    newState := and(shr(40, maskedRule), 0xFF)
                }

                let newOrientation
                switch newDirection
                case 0x02 {
                    newOrientation := addmod(_orientation, 1, 4)
                }
                case 0x08 {
                    switch _orientation
                    case 0 {
                        newOrientation := 3
                    }
                    default {
                        newOrientation := mod(sub(_orientation, 1), 4)
                    }
                }
                case 0x04 {
                    newOrientation := mod(add(_orientation, 2), 4)
                }
                default {
                    newOrientation := _orientation
                }

                let buffer := mload(0x40)

                switch newOrientation
                case 0x00 {
                    mstore8(add(buffer, 31), addmod(_x, 1, 144))
                    mstore8(add(buffer, 30), _y)
                }
                case 0x02 {
                    switch _x
                    case 0 {
                        mstore8(add(buffer, 31), 143)
                        mstore8(add(buffer, 30), _y)
                    }
                    default {
                        mstore8(add(buffer, 31), sub(_x, 1))
                        mstore8(add(buffer, 30), _y)
                    }
                }
                case 0x03 {
                    mstore8(add(buffer, 31), _x)
                    mstore8(add(buffer, 30), addmod(_y, 1, 144))
                }
                case 0x01 {
                    switch _y
                    case 0 {
                        mstore8(add(buffer, 31), _x)
                        mstore8(add(buffer, 30), 143)
                    }
                    default {
                        mstore8(add(buffer, 31), _x)
                        mstore8(add(buffer, 30), sub(_y, 1))
                    }
                }

                //  128   120  112  104   96   88   80   72   64   56   48  40
                // 0xff    08   01   ff   02   01   ff   00   00   00   44  21

                mstore8(add(buffer, 29), newOrientation)
                mstore8(add(buffer, 28), _boardNumber)
                mstore8(add(buffer, 27), newState)
                sour := or(mload(buffer), maskedRule)
            }

            // note that we pass here the "old" x & y
            setByte(_x, _y, colorField, _boardNumber);
            unchecked {
                z += 1;
            }
        }
        assembly {
            sstore(data.slot, sour)
        }
        emit TurmiteMove(id, _boardNumber, moves);
    }
}