// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IDataStructures } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/IDataStructures.sol";

contract MockAccountManager {
    mapping(bytes => uint256) public lifecycleStatus;
    function setLifecycleStatus(bytes calldata _blsKey, uint256 _status) external {
        lifecycleStatus[_blsKey] = _status;
    }

    function blsPublicKeyToLifecycleStatus(bytes calldata _blsPubKey) external view returns (uint256) {
        return lifecycleStatus[_blsPubKey];
    }

    /// @dev BLS public Key -> Last know state of the validator
    mapping(bytes => IDataStructures.ETH2DataReport) public blsPublicKeyToLastState;
    function markSlashedIsTrue(bytes calldata _blsPubKey) external {
        blsPublicKeyToLastState[_blsPubKey].slashed = true;
    }
}