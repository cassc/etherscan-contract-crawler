//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {LibSignature} from "./LibSignature.sol";
import {LibPercentage} from "./LibPercentage.sol";
import {LibOwnership} from "./LibOwnership.sol";
import {StorageQuorumGovernance} from "../storage/StorageQuorumGovernance.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// @author Amit Molek
/// @dev Please see `QuorumGovernanceFacet` for docs
library LibQuorumGovernance {
    /// @param hash the hash to verify
    /// @param signatures array of the members signatures on `hash`
    /// @return true, if enough members signed the `hash` with enough voting powers
    function _verifyHash(bytes32 hash, bytes[] memory signatures)
        internal
        view
        returns (bool)
    {
        address[] memory signedMembers = _extractMembers(hash, signatures);

        return _verifyQuorum(signedMembers) && _verifyPassRate(signedMembers);
    }

    /// @param hash the hash to verify
    /// @param signatures array of the members signatures on `hash`
    /// @return members a list of the members that signed `hash`
    function _extractMembers(bytes32 hash, bytes[] memory signatures)
        internal
        view
        returns (address[] memory members)
    {
        members = new address[](signatures.length);

        address lastSigner = address(0);
        for (uint256 i = 0; i < signatures.length; i++) {
            address signer = LibSignature._recoverSigner(hash, signatures[i]);
            // Check for duplication (same signer)
            require(signer > lastSigner, "Governance: Invalid signatures");
            lastSigner = signer;

            require(
                LibOwnership._isMember(signer),
                string(
                    abi.encodePacked(
                        "Governance: Signer ",
                        Strings.toHexString(uint256(uint160(signer)), 20),
                        " is not a member"
                    )
                )
            );

            members[i] = signer;
        }
    }

    /// @dev Explain to a developer any extra details
    /// @param members the members to check the quorum of
    /// @return true, if enough members signed the hash
    function _verifyQuorum(address[] memory members)
        internal
        view
        returns (bool)
    {
        return members.length >= _quorumThreshold();
    }

    /// @dev The calculation always rounds up (ceil) the threshold
    /// e.g. if the group size is 3 and the quorum percentage is 50% the threshold is 2
    /// ceil((3 * 50) / 100) = ceil(1.5) -> 2
    /// @return the quorum threshold amount of members that must sign for the hash to be verified
    function _quorumThreshold() internal view returns (uint256) {
        uint256 groupSize = LibOwnership._members().length;
        uint256 quorumPercentage = StorageQuorumGovernance
            .diamondStorage()
            .quorumPercentage;

        return LibPercentage._calculateCeil(groupSize, quorumPercentage);
    }

    /// @dev Verifies that the pass rate of `members` passes the minimum pass rate
    /// @param members the members to check the pass rate of
    /// @return true, if the `members` pass rate has passed the minimum pass rate
    function _verifyPassRate(address[] memory members)
        internal
        view
        returns (bool)
    {
        uint256 passRate = _calculatePassRate(members);
        uint256 passRatePercentage = StorageQuorumGovernance
            .diamondStorage()
            .passRatePercentage;

        return passRate >= passRatePercentage;
    }

    /// @notice Calculate the weighted pass rate
    /// @dev The weight is based upon the ownership units of each member
    /// e.g. if Alice and Bob are the group members,
    /// they have 60 and 40 units respectively. So the group total is 100 units.
    /// so their weights are 60% (60/100*100) for Alice and 40% (40/100*100) for Bob.
    /// @param members the members to check the pass rate of
    /// @return the pass rate percentage of `members` (e.g. 46%)
    function _calculatePassRate(address[] memory members)
        internal
        view
        returns (uint256)
    {
        uint256 totalSignersUnits;
        for (uint256 i = 0; i < members.length; i++) {
            totalSignersUnits += LibOwnership._ownershipUnits(members[i]);
        }

        uint256 totalUnits = LibOwnership._totalOwnershipUnits();
        require(totalUnits > 0, "Governance: units can't be 0");

        return
            (totalSignersUnits * LibPercentage.PERCENTAGE_DIVIDER) / totalUnits;
    }
}