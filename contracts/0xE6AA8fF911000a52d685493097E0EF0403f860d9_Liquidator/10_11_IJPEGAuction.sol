// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IJPEGAuction {
    function newAuction(address _nft, uint256 _idx, uint256 _minBid) external;
}