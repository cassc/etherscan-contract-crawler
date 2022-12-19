//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {LibQuorumGovernance} from "../libraries/LibQuorumGovernance.sol";
import {StorageApprovedHashes} from "../storage/StorageApprovedHashes.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library LibWalletHash {
    event ApprovedHash(bytes32 hash);
    event RevokedHash(bytes32 hash);

    /// @dev The hash time-to-live
    uint256 internal constant HASH_TTL = 4 weeks;

    /// @dev Adds `hash` to the approved hashes list
    /// Emits `ApprovedHash`
    function _internalApproveHash(bytes32 hash) internal {
        StorageApprovedHashes.DiamondStorage storage ds = StorageApprovedHashes
            .diamondStorage();

        // solhint-disable-next-line not-rely-on-time
        ds.deadlines[hash] = block.timestamp + HASH_TTL;
        emit ApprovedHash(hash);
    }

    /// @dev Removes `hash` from the approved hashes list
    /// Emits `RevokedHash`
    function _internalRevokeHash(bytes32 hash) internal {
        StorageApprovedHashes.DiamondStorage storage ds = StorageApprovedHashes
            .diamondStorage();

        delete ds.deadlines[hash];
        emit RevokedHash(hash);
    }

    function _hashDeadline(bytes32 hash) internal view returns (uint256) {
        StorageApprovedHashes.DiamondStorage storage ds = StorageApprovedHashes
            .diamondStorage();

        return ds.deadlines[hash];
    }

    function _isHashApproved(bytes32 hash) internal view returns (bool) {
        StorageApprovedHashes.DiamondStorage storage ds = StorageApprovedHashes
            .diamondStorage();

        uint256 deadline = ds.deadlines[hash];

        // solhint-disable-next-line not-rely-on-time
        return deadline > block.timestamp;
    }

    function _approveHash(bytes32 hash, bytes[] memory signatures) internal {
        // Can only approve an unapproved hash
        require(hash != bytes32(0), "Wallet: Invalid hash");
        require(!_isHashApproved(hash), "Wallet: Approved hash");

        // Verify that the group agrees to approve the hash
        _verifyHashGuard(hash, signatures);

        _internalApproveHash(hash);
    }

    function _revokeHash(bytes32 hash, bytes[] memory signatures) internal {
        // Can only revoke an already approved hash
        require(hash != bytes32(0), "Wallet: Invalid hash");
        require(_isHashApproved(hash), "Wallet: Unapproved hash");

        // Verify that the group agrees to revoke the hash
        _verifyHashGuard(hash, signatures);

        _internalRevokeHash(hash);
    }

    /// @dev Reverts with "Wallet: Unapproved request", if `signatures` don't verify `hash`
    function _verifyHashGuard(bytes32 hash, bytes[] memory signatures)
        internal
        view
    {
        bytes32 ethSignedHash = ECDSA.toEthSignedMessageHash(hash);
        bool isAgreed = LibQuorumGovernance._verifyHash(
            ethSignedHash,
            signatures
        );
        require(isAgreed, "Wallet: Unapproved request");
    }
}