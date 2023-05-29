// SPDX-License-Identifier: GPL-3.0
/// @title Mint.sol
/// @author Lawrence X Rogers
/// @dev this Library has some useful utility functions for the Mints stored as Bytes32

pragma solidity ^0.8.10;
import "./ArtParams.sol";

library Mint {
    function mintType(bytes32 mint) internal pure returns (uint256) {
        return uint256(uint8(mint[0]));
    }

    function isShape(bytes32 mint) internal pure returns (bool) {
        return mintType(mint) <= MINT_TYPE_CIRCLE;
    }

    function isBackground(bytes32 mint) internal pure returns (bool) {
        return mintType(mint) == MINT_TYPE_BACKGROUND;
    }

    function isEffect(bytes32 mint) internal pure returns (bool) {
        return mintType(mint) > MINT_TYPE_CIRCLE && mintType(mint) != MINT_TYPE_BACKGROUND;
    }

    function isFinishingTouch(bytes32 mint) internal pure returns (bool) {
        return mint[31] == 0x01;
    }
}