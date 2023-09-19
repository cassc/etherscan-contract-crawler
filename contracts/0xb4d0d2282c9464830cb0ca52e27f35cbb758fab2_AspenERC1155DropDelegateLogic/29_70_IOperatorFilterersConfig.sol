// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "./types/OperatorFiltererDataTypes.sol";

interface IOperatorFiltererConfigV0 {
    event OperatorFiltererAdded(
        bytes32 operatorFiltererId,
        string name,
        address defaultSubscription,
        address operatorFilterRegistry
    );

    function getOperatorFiltererOrDie(
        bytes32 _operatorFiltererId
    ) external view returns (IOperatorFiltererDataTypesV0.OperatorFilterer memory);

    function getOperatorFilterer(
        bytes32 _operatorFiltererId
    ) external view returns (IOperatorFiltererDataTypesV0.OperatorFilterer memory);

    function getOperatorFiltererIds() external view returns (bytes32[] memory operatorFiltererIds);

    function addOperatorFilterer(IOperatorFiltererDataTypesV0.OperatorFilterer memory _newOperatorFilterer) external;
}