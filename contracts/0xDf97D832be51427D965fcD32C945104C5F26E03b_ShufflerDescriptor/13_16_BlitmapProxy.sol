// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;


abstract contract BlitmapProxy {
    function tokenSvgDataOf(uint256 tokenId) virtual external view returns (string memory);
}