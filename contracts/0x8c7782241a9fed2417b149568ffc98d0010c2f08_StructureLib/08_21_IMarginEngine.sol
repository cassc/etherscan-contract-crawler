// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IGrappa} from "grappa/interfaces/IGrappa.sol";
import {IPomace} from "pomace/interfaces/IPomace.sol";

import {BatchExecute as GrappaBatchExecute, ActionArgs as GrappaActionArgs} from "grappa/config/types.sol";
import {BatchExecute as PomaceBatchExecute, ActionArgs as PomaceActionArgs} from "pomace/config/types.sol";
import "../config/types.sol";

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
}

interface IMarginEngineCash is IMarginEngine {
    function grappa() external view returns (IGrappa grappa);

    function execute(address account, GrappaActionArgs[] calldata actions) external;

    function batchExecute(GrappaBatchExecute[] calldata batchActions) external;
}

interface IMarginEnginePhysical is IMarginEngine {
    function pomace() external view returns (IPomace pomace);

    function execute(address account, PomaceActionArgs[] calldata actions) external;

    function batchExecute(PomaceBatchExecute[] calldata batchActions) external;
}