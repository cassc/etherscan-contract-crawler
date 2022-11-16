// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../lib/LibAsset.sol";
import "../lib/LibFill.sol";
import "../TransferExecutor.sol";
import "../lib/LibOrderData.sol";

abstract contract ITransferManager is ITransferExecutor {

    function doTransfers(
        LibAsset.AssetType memory makeMatch,
        LibAsset.AssetType memory takeMatch,
        LibFill.FillResult memory fill,
        LibOrder.Order memory leftOrder,
        LibOrder.Order memory rightOrder,
        LibOrderData.Data memory leftData,
        LibOrderData.Data memory rightData
    ) internal virtual;
}