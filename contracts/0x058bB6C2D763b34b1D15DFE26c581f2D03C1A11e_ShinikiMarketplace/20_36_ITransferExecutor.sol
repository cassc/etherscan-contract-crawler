// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../lib/LibAsset.sol";

abstract contract ITransferExecutor {
    //events
    event Transfer(
        LibAsset.Asset asset,
        address from,
        address to
    );

    function transfer(
        LibAsset.Asset memory asset,
        address from,
        address to
    ) internal virtual;
}