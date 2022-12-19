//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IGovernance} from "../../interfaces/IGovernance.sol";
import {LibQuorumGovernance} from "../../libraries/LibQuorumGovernance.sol";
import {StorageQuorumGovernance} from "../../storage/StorageQuorumGovernance.sol";

/// @title Quorum Governance
/// @author Amit Molek
/// @dev A hash is verified based upon 2 factors:
///     - Quorum: minimum level of in favor participation required for a vote to be valid
///     - Pass rate: the percentage of holding power that needs to be in favor in order for the hash to be accepted
/// Please see `IGovernance` and `LibQuorumGovernance` for more docs.
contract QuorumGovernanceFacet is IGovernance {
    function verifyHash(bytes32 hash, bytes[] memory signatures)
        external
        view
        override
        returns (bool)
    {
        return LibQuorumGovernance._verifyHash(hash, signatures);
    }

    function quorumPercentage() external view returns (uint256) {
        StorageQuorumGovernance.DiamondStorage
            storage ds = StorageQuorumGovernance.diamondStorage();

        return ds.quorumPercentage;
    }

    function passRatePercentage() external view returns (uint256) {
        StorageQuorumGovernance.DiamondStorage
            storage ds = StorageQuorumGovernance.diamondStorage();

        return ds.passRatePercentage;
    }
}