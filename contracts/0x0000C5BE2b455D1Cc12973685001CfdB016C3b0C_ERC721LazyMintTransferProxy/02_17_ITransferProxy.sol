// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../libraries/AssetLib.sol";

/**
 * @title TransferProxy Interface
 * @notice Interface for Recrow-compatible transfer proxy contracts
 */
interface ITransferProxy {
    function transfer(
        AssetLib.AssetData calldata asset,
        address from,
        address to
    ) external;
}