// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {XXYYZZCore} from "./XXYYZZCore.sol";

/**
 * @title XXYYZZRerollFinalize
 * @author emo.eth
 * @notice This contract handles "rerolling" and "finalizing" tokens.
 *         Rerolling allows users to burn a token they own in exchange for a new one. The new token may be either
 *         pseudorandom, or a specific color when using one of the "Specific" methods.
 *         Finalizing allows users to prevent a token from being rerolled again, in addition to adding their
 *         wallet address to the token's metadata as the "Finalizer" trait.
 */
abstract contract XXYYZZRerollFinalize is XXYYZZCore {
    ////////////
    // REROLL //
    ////////////
    /**
     * @notice Burn a token you own and mint a new one with a pseudorandom hex value.
     * @param oldId The 6-hex-digit token ID to burn
     * @return The new token ID
     */
    function reroll(uint256 oldId) public payable returns (uint256) {
        _validatePayment(REROLL_PRICE, 1);
        // use the caller as the seed to derive the new token ID
        // this means multiple calls in the same block will be gas-inefficient
        // which may somewhat discourage botting
        return _rerollWithSeed(oldId, uint160(msg.sender));
    }

    /**
     * @notice Burn a number of tokens you own and mint new ones with pseudorandom hex values.
     * @param ids The 6-hex-digit token IDs to burn in exchange for new tokens
     * @return The new token IDs
     */
    function batchReroll(uint256[] calldata ids) public payable returns (uint256[] memory) {
        _validatePayment(REROLL_PRICE, ids.length);
        // use the caller as the seed to derive the new token IDs
        // this means multiple calls in the same block will be gas-inefficient
        // which may somewhat discourage botting
        uint256 seed = uint256(uint160(msg.sender));
        uint256[] memory newIds = new uint256[](ids.length);
        for (uint256 i; i < ids.length;) {
            newIds[i] = _rerollWithSeed(ids[i], seed);
            unchecked {
                ++i;
                ++seed;
            }
        }
        return newIds;
    }

    /**
     * @notice Burn and re-mint a token with a specific hex ID. Uses a commit-reveal scheme to prevent front-running.
     *         Only callable by the owner of the token. Users must call `commit(bytes32)` with the result of
     *         `computeCommitment(address,uint256,bytes32)` and wait at least COMMITMENT_LIFESPAN seconds before
     *         calling `rerollSpecific`.
     * @param oldId The 6-hex-digit token ID to burn
     * @param newId The 6-hex-digit token ID to mint
     * @param salt The salt used in the commitment for the new ID commitment
     */
    function rerollSpecific(uint256 oldId, uint256 newId, bytes32 salt) public payable {
        _validatePayment(REROLL_PRICE, 1);
        _rerollSpecificWithSalt(oldId, newId, salt);
    }

    /**
     * @notice Burn and re-mint a number of tokens with specific hex values. Uses a commit-reveal scheme to prevent
     *         front-running. Only callable by the owner of the tokens. Users must call `commit(bytes32)` with the
     *         result of `computeBatchCommitment(address,uint256[],bytes32)` and wait at least COMMITMENT_LIFESPAN
     *         seconds before calling `batchRerollSpecific`.
     * @param oldIds The 6-hex-digit token IDs to burn
     * @param newIds The 6-hex-digit token IDs to mint
     * @param salt The salt used in the commitment for the new IDs commitment
     * @return An array of booleans indicating whether each token was successfully rerolled
     */
    function batchRerollSpecific(uint256[] calldata oldIds, uint256[] calldata newIds, bytes32 salt)
        public
        payable
        returns (bool[] memory)
    {
        _validateRerollBatchAndPayment(oldIds, newIds, REROLL_PRICE);
        bytes32 computedCommitment = computeBatchCommitment(msg.sender, newIds, salt);
        _assertCommittedReveal(computedCommitment);

        return _batchRerollAndRefund(oldIds, newIds);
    }

    /**
     * @notice Burn and re-mint a token with a specific hex ID, then finalize it. Uses a commit-reveal scheme to
     *         prevent front-running. Only callable by the owner of the token. Users must call `commit(bytes32)`
     *         with the result of `computeCommitment(address,uint256,bytes32)` and wait at least COMMITMENT_LIFESPAN
     *         seconds before calling `rerollSpecificAndFinalize`.
     * @param oldId The 6-hex-digit token ID to burn
     * @param newId The 6-hex-digit token ID to mint
     * @param salt The salt used in the commitment for the new ID commitment
     */
    function rerollSpecificAndFinalize(uint256 oldId, uint256 newId, bytes32 salt) public payable {
        _validatePayment(REROLL_AND_FINALIZE_PRICE, 1);

        _rerollSpecificWithSalt(oldId, newId, salt);
        // won't re-validate price, but above function already did
        _finalizeToken(newId, msg.sender);
    }

    /**
     * @notice Burn and re-mint a number of tokens with specific hex values, then finalize them.
     * @param oldIds The 6-hex-digit token IDs to burn
     * @param newIds The 6-hex-digit token IDs to mint
     * @param salt The salt used in the batch commitment for the new ID commitment
     * @return An array of booleans indicating whether each token was successfully rerolled
     */
    function batchRerollSpecificAndFinalize(uint256[] calldata oldIds, uint256[] calldata newIds, bytes32 salt)
        public
        payable
        returns (bool[] memory)
    {
        _validateRerollBatchAndPayment(oldIds, newIds, REROLL_AND_FINALIZE_PRICE);
        bytes32 computedCommitment = computeBatchCommitment(msg.sender, newIds, salt);
        _assertCommittedReveal(computedCommitment);
        return _batchRerollAndFinalizeAndRefund(oldIds, newIds);
    }

    //////////////
    // FINALIZE //
    //////////////

    /**
     * @notice Finalize a token, which updates its metadata with a "Finalizer" trait and prevents it from being
     *         rerolled in the future.
     * @param id The 6-hex-digit token ID to finalize. Must be owned by the caller.
     */
    function finalize(uint256 id) public payable {
        _validatePayment(FINALIZE_PRICE, 1);
        _finalize(id);
    }

    /**
     * @notice Finalize a number of tokens, which updates their metadata with a "Finalizer" trait and prevents them
     *         from being rerolled in the future. The caller must pay the finalization price for each token, and must
     *         own all tokens.
     * @param ids The 6-hex-digit token IDs to finalize
     */
    function batchFinalize(uint256[] calldata ids) public payable {
        _validatePayment(FINALIZE_PRICE, ids.length);
        for (uint256 i; i < ids.length;) {
            _finalize(ids[i]);
            unchecked {
                ++i;
            }
        }
    }

    //////////////
    // INTERNAL //
    //////////////

    /**
     * @dev Internal function to burn and re-mint tokens with a specific hex ID. Does not check initial payment.
     *      Does refund any overpayment.
     * @param oldIds The 6-hex-digit token IDs to burn
     * @param newIds The 6-hex-digit token IDs to mint
     * @return An array of booleans indicating whether each token was successfully rerolled
     */
    function _batchRerollAndRefund(uint256[] calldata oldIds, uint256[] calldata newIds)
        internal
        returns (bool[] memory)
    {
        bool[] memory rerolled = new bool[](oldIds.length);
        uint256 quantityRerolled;
        for (uint256 i; i < oldIds.length;) {
            if (_rerollSpecificUnprotected(oldIds[i], newIds[i])) {
                rerolled[i] = true;
                unchecked {
                    ++quantityRerolled;
                }
            }
            unchecked {
                ++i;
            }
        }
        // if none were rerolled, revert to avoid wasting further gas
        if (quantityRerolled == 0) {
            revert NoneAvailable();
        }
        // refund any overpayment
        _refundOverpayment(REROLL_PRICE, quantityRerolled);

        return rerolled;
    }

    /**
     * @dev Internal function to burn and re-mint tokens with a specific hex ID, then finalize them. Does not check
     *     initial payment. Does refund any overpayment.
     * @param oldIds The 6-hex-digit token IDs to burn
     * @param newIds The 6-hex-digit token IDs to mint
     * @return An array of booleans indicating whether each token was successfully rerolled
     */
    function _batchRerollAndFinalizeAndRefund(uint256[] calldata oldIds, uint256[] calldata newIds)
        internal
        returns (bool[] memory)
    {
        bool[] memory rerolled = new bool[](oldIds.length);
        uint256 quantityRerolled;
        for (uint256 i; i < oldIds.length;) {
            if (_rerollSpecificUnprotected(oldIds[i], newIds[i])) {
                _finalizeToken(newIds[i], msg.sender);
                rerolled[i] = true;
                unchecked {
                    ++quantityRerolled;
                }
            }
            unchecked {
                ++i;
            }
        }
        // if none were rerolled, revert to avoid wasting gas
        if (quantityRerolled == 0) {
            revert NoneAvailable();
        }
        // refund any overpayment
        _refundOverpayment(REROLL_AND_FINALIZE_PRICE, quantityRerolled);

        return rerolled;
    }

    /**
     * @dev Validate an old tokenId is rerollable, burn it, then mint a token with a pseudorandom
     *      hex ID.
     * @param oldId The old ID to reroll
     * @param seed The seed to use for the reroll
     *
     */
    function _rerollWithSeed(uint256 oldId, uint256 seed) internal returns (uint256) {
        _checkCallerIsOwnerAndNotFinalized(oldId);
        // burn old token
        _burn(oldId);
        uint256 tokenId = _findAvailableHex(seed);
        _mint(msg.sender, tokenId);
        return tokenId;
    }

    /**
     * @dev Validate an old tokenId is rerollable, burn it, then mint a token with a specific
     *     hex ID, validating that the commit-reveal scheme was followed.
     * @param oldId The old ID to reroll
     * @param newId The new ID to mint
     * @param salt The salt used in the commit-reveal scheme
     */
    function _rerollSpecificWithSalt(uint256 oldId, uint256 newId, bytes32 salt) internal {
        _checkCallerIsOwnerAndNotFinalized(oldId);
        // burn old token
        _burn(oldId);
        _mintSpecific(newId, salt);
    }

    /**
     * @dev Validate an old tokenId is rerollable, mint a token with a specific new hex ID (if available)
     *      and burn the old token.
     * @param oldId The old ID to reroll
     * @param newId The new ID to mint
     * @return Whether the mint succeeded, ie, the new ID was available
     */
    function _rerollSpecificUnprotected(uint256 oldId, uint256 newId) internal returns (bool) {
        _checkCallerIsOwnerAndNotFinalized(oldId);
        // only burn old token if mint succeeded
        if (_mintSpecificUnprotected(newId)) {
            _burn(oldId);
            return true;
        }
        return false;
    }

    /**
     * @dev Internal function to finalize a token, first checking that the caller is the owner and that the token
     *      has not already been finalized.
     * @param id The 6-hex-digit token ID to finalize
     */
    function _finalize(uint256 id) internal {
        _checkCallerIsOwnerAndNotFinalized(id);
        // set finalized flag
        _finalizeToken(id, msg.sender);
        // emit onchain metadata update event
        emit MetadataUpdate(id);
    }

    /**
     * @dev Finalize a tokenId, updating its metadata with a "Finalizer" trait, and preventing it from being rerolled in the future.
     * @param id The 6-hex-digit token ID to finalize
     * @param finalizer The address of the account finalizing the token
     */
    function _finalizeToken(uint256 id, address finalizer) internal {
        finalizers[id] = finalizer;
        _setExtraData(id, 1);
    }
}