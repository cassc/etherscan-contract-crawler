// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "../libs/LibERC721MintData.sol";

interface IERC721Mintable {
    function mint(LibERC721MintData.MintData calldata mintData) external;
}