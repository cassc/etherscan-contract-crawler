// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IAssetRegistry} from "./IAssetRegistry.sol";

import "../config/types.sol";

/**
 * @notice Interface for the abstract margin engine contract which handles both cash and physical settlement
 *         used only in the settlement contracts to provide compatibility between the engine interfaces
 */
interface IMarginEngine {
    function optionToken() external view returns (address);

    function marginAccounts(address)
        external
        view
        returns (Position[] memory shorts, Position[] memory longs, Balance[] memory collaterals);

    function previewMinCollateral(Position[] memory shorts, Position[] memory longs) external view returns (Balance[] memory);

    function allowedExecutionLeft(uint160 mask, address account) external view returns (uint256);

    function setAccountAccess(address account, uint256 allowedExecutions) external;

    function revokeSelfAccess(address granter) external;

    function grappa() external view returns (IAssetRegistry grappa);

    function pomace() external view returns (IAssetRegistry pomace);

    function execute(address account, ActionArgs[] calldata actions) external;

    function batchExecute(BatchExecute[] calldata batchActions) external;
}