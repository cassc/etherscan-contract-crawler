// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interface/IDEXConstants.sol";

abstract contract DEXConstants {
    uint8 public constant MAKER_SIDE = 0;
    uint8 public constant TAKER_SIDE = 1;

    uint8 public constant ERC1155_ASSET = 0;
    uint8 public constant ERC721_ASSET = 1;
    uint8 public constant ERC20_ASSET = 2;
    uint8 public constant ETHER_ASSET = 3;

    uint8 public constant OPEN_SWAP = 0;
    uint8 public constant CLOSED_SWAP = 1;
    uint8 public constant DROPPED_SWAP = 2;
}