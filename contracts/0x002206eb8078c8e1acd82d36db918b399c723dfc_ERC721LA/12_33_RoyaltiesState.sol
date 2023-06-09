// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

library RoyaltiesState {
    struct RoyaltyReceiver {
        address payable wallet;
        uint48 primarySalePercentage;
        uint48 secondarySalePercentage;
    }

    /**
     * @dev Storage layout
     * This pattern allow us to extend current contract using DELETGATE_CALL
     * without worrying about storage slot conflicts
     */
    struct RoyaltiesRegistryState {
        // contractAddress => RoyaltyReceiver
        mapping(address => RoyaltyReceiver[]) _collectionRoyaltyReceivers;
        // contractAddress => editionId => RoyaltyReceiver
        mapping(address => mapping(uint256 => RoyaltyReceiver[])) _editionRoyaltyReceivers;
        // contractAddress => editionId => tokenNumber => RoyaltyReceiver
        mapping(address => mapping(uint256 => mapping(uint256 => RoyaltyReceiver[]))) _tokenRoyaltyReceivers;
    }

    /**
     * @dev Get storage data from dedicated slot.
     * This pattern avoids storage conflict during proxy upgrades
     * and give more flexibility when creating extensions
     */
    function _getRoyaltiesState()
        internal
        pure
        returns (RoyaltiesRegistryState storage state)
    {
        bytes32 storageSlot = keccak256("liveart.RoyalitiesState");
        assembly {
            state.slot := storageSlot
        }
    }
}