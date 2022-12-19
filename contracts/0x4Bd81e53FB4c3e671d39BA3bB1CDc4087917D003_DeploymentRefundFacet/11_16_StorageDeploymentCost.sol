//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev Diamond compatible storage for deployment cost split mechanism
library StorageDeploymentCost {
    struct DiamondStorage {
        /// @dev The account that deployed the contract
        address deployer;
        /// @dev Use to indicate that the deployer has joined the group
        /// (for deployment cost refund calculation)
        bool isDeployerJoined;
        /// @dev Contract deployment cost to refund (minus what the deployer already paid)
        uint256 deploymentCostToRefund;
        /// @dev Deployment cost refund paid so far
        uint256 paid;
        /// @dev Refund amount withdrawn by the deployer
        uint256 withdrawn;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.DeploymentCost");

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }
}