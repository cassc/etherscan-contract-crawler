//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev Diamond compatible storage for quorum governance
library StorageQuorumGovernance {
    struct DiamondStorage {
        /// @dev The minimum level of participation required for a vote to be valid.
        /// in percentages out of 100 (e.g. 40)
        uint8 quorumPercentage;
        /// @dev What percentage of the votes cast need to be in favor in order
        /// for the proposal to be accepted.
        /// in percentages out of 100 (e.g. 40)
        uint8 passRatePercentage;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.QuorumGovernance");

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

    function _initStorage(uint8 quorumPercentage, uint8 passRatePercentage)
        internal
    {
        require(
            quorumPercentage > 0 && quorumPercentage <= 100,
            "Storage: quorum percentage must be in range (0,100]"
        );
        require(
            passRatePercentage > 0 && passRatePercentage <= 100,
            "Storage: pass rate percentage must be in range (0,100]"
        );

        DiamondStorage storage ds = diamondStorage();

        ds.quorumPercentage = quorumPercentage;
        ds.passRatePercentage = passRatePercentage;
    }
}