//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";

library OperatorsRegistry_FundedKeyEventRebroadcasting_OperatorIndex {
    bytes32 internal constant OPERATOR_INDEX_SLOT = bytes32(
        uint256(keccak256("river.state.migration.operatorsRegistry.fundedKeyEventRebroadcasting.operatorIndex")) - 1
    );

    function get() internal view returns (uint256) {
        return LibUnstructuredStorage.getStorageUint256(OPERATOR_INDEX_SLOT);
    }

    function set(uint256 _newValue) internal {
        LibUnstructuredStorage.setStorageUint256(OPERATOR_INDEX_SLOT, _newValue);
    }
}