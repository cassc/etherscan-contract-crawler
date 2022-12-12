// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../mint/IMintNFT.sol";

interface IRedeemNFT is IMintNFT {
    function redeem(uint256 tokenId, address owner) external returns (uint256 newTokenId);
}