// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../lib/LibSignature.sol";

abstract contract ITransferExecutor {
    event Transfer(LibAsset.Asset asset, address indexed from, address indexed to);

    function transfer(
        LibSignature.AuctionType auctionType,
        LibAsset.Asset memory asset,
        address from,
        address to,
        uint256 decreasingPriceValue,
        bool validRoyalty,
        LibAsset.Asset[] memory optionalNftAssets
    ) internal virtual;
}