// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import "operator-filter-registry/src/IOperatorFilterRegistry.sol";

library WithOperatorRegistryState {


    struct OperatorRegistryState {
      IOperatorFilterRegistry operatorFilterRegistry;
    }


    /**
     * @dev Get storage data from dedicated slot.
     * This pattern avoids storage conflict during proxy upgrades
     * and give more flexibility when creating extensions
     */
    function _getOperatorRegistryState()
        internal
        pure
        returns (OperatorRegistryState storage state)
    {
        bytes32 storageSlot = keccak256("liveart.OperatorRegistryState");
        assembly {
            state.slot := storageSlot
        }
    }
}