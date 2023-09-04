// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IGrappa} from "grappa/interfaces/IGrappa.sol";
import {IPomace} from "pomace/interfaces/IPomace.sol";

import {BatchExecute, ActionArgs} from "../config/types.sol";

import "../config/types.sol";

/**
 * @notice Interface for the base margin engine contract
 */
interface IMarginEngine {
    function optionToken() external view returns (address);

    function marginAccounts(address)
        external
        view
        returns (Position[] memory shorts, Position[] memory longs, Balance[] memory collaterals);

    function previewMinCollateral(Position[] memory shorts, Position[] memory longs) external view returns (Balance[] memory);

    function allowedExecutionLeft(uint160 mask, address account) external view returns (uint256);

    function batchExecute(BatchExecute[] calldata batchActions) external;

    function execute(address account, ActionArgs[] calldata actions) external;

    function revokeSelfAccess(address granter) external;

    function setAccountAccess(address account, uint256 allowedExecutions) external;

    function grappa() external view returns (IGrappa grappa);

    function pomace() external view returns (IPomace pomace);

    function tokenTracker(uint256 tokenId) external view returns (uint64 issued, uint80 totalDebt, uint80 totalPaid);
}