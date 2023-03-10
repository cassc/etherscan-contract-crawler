// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

interface ITransferableRoyalties {
    function transferTokenRoyalty(uint256 tokenId, address receiver) external;

    function transferDefaultRoyalty(address receiver) external;
}