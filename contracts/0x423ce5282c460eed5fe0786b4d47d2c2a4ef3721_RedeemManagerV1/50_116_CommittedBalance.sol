//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";

library CommittedBalance {
    bytes32 internal constant COMMITTED_BALANCE_SLOT = bytes32(uint256(keccak256("river.state.committedBalance")) - 1);

    function get() internal view returns (uint256) {
        return LibUnstructuredStorage.getStorageUint256(COMMITTED_BALANCE_SLOT);
    }

    function set(uint256 newValue) internal {
        LibUnstructuredStorage.setStorageUint256(COMMITTED_BALANCE_SLOT, newValue);
    }
}