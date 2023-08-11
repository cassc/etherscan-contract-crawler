// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibEIP712} from "../libraries/LibEIP712.sol";

/**
 *  ╔╗  ╔╗╔╗      ╔╗ ╔╗     ╔╗
 *  ║╚╗╔╝╠╝╚╗     ║║ ║║     ║║
 *  ╚╗║║╔╬╗╔╬═╦╦══╣║ ║║  ╔══╣╚═╦══╗
 *   ║╚╝╠╣║║║╔╬╣╔╗║║ ║║ ╔╣╔╗║╔╗║══╣
 *   ╚╗╔╣║║╚╣║║║╚╝║╚╗║╚═╝║╔╗║╚╝╠══║
 *    ╚╝╚╝╚═╩╝╚╩══╩═╝╚═══╩╝╚╩══╩══╝
 */

/**
 * @title  MintVoucherVerifier
 * @author slvrfn
 * @notice Abstract contract which contains the necessary logic to verify the validity of a MintVoucher.
 * @dev    This contract is meant to be inherited by contracts so they can use the internal functions as desired
 */
abstract contract MintVoucherVerifier {
    using LibEIP712 for LibEIP712.Layout;

    /**
     * @dev Raised if a user has not provided the necessary fee associated with a MintVoucher.
     */
    error MintFee();
    /**
     * @dev Raised if a user tried to mint 0 tokens, or more than their voucher is allowed.
     */
    error MintLimit();
    /**
     * @dev Raised if a user tried to mint before their assigned phase.
     */
    error MintPhase();
    /**
     * @dev Raised if a user tried to use a voucher not assigned to them.
     */
    error VoucherAddress();
    /**
     * @dev Raised if a user tried to use an invalid voucher (signature doesnt match fields).
     */
    error VoucherInvalid();
    /**
     * @dev Raised if a user tried to mint more than their voucher allows.
     */
    error VoucherQty();
    /**
     * @dev Raised if a user tried to use a voucher that has been fully consumed
     */
    error VoucherClaimed();

    /**
     * @dev Represents a voucher to Mint 1 or more NFTs. A signed voucher is used for proving the contained parameters
     *      were set by an address with the appropriate role.
     */
    struct MintVoucher {
        /// @dev single use nonce that prevents voucher reuse
        uint256 nonce;
        /// @dev address this voucher is associated with
        address addr;
        /// @dev how many mints this voucher is worth (in a single use)
        uint16 qty;
        /// @dev phase of mint this voucher can be used
        uint8 phase;
        /// @dev if the caller receives a free mint
        uint8 free;
        /// @dev the EIP-712 signature of all other fields in the MintVoucher struct. For a voucher to be valid, it must be signed by an account with the MINTER_ROLE.
        bytes signature;
    }

    /**
     * @dev   Returns the current mint fee.
     * @param currentPhase - mint phase to return the fee for.
     */
    // solhint-disable-next-line no-unused-vars
    function _getMintFee(uint256 currentPhase, uint16 desiredQty) internal virtual returns (uint256) {
        revert("_getMintFee needs override");
    }

    /**
     * @dev   Returns a hash of the given MintVoucher, prepared using EIP712 typed data hashing rules.
     * @param voucher - An MintVoucher to hash.
     */
    function _hashMintVoucher(LibEIP712.Layout storage e, MintVoucher memory voucher) internal view returns (bytes32) {
        return
            e._hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("MintVoucher(uint256 nonce,address addr,uint16 qty,uint8 phase,uint8 free)"),
                        voucher.nonce,
                        voucher.addr,
                        voucher.qty,
                        voucher.phase,
                        voucher.free
                    )
                )
            );
    }

    /**
     * @dev   Verifies the signature for a given MintVoucher, returning the address of the signer. Will revert if
     *        the signature is invalid. Does not verify that the signer is authorized to create a MintVoucher.
     * @param voucher - A MintVoucher describing a user's mint details.
     */
    function _verifyMintVoucher(LibEIP712.Layout storage e, MintVoucher memory voucher) internal view returns (address) {
        bytes32 digest = _hashMintVoucher(e, voucher);
        return LibEIP712._verifySignedData(digest, voucher.signature);
    }

    /**
     * @dev   Signals whether an MintVoucher is verified, and able to be used.
     * @param voucher - A MintVoucher describing a user's mint details.
     */
    function _checkVoucherGetSigner(MintVoucher memory voucher, uint40 currentPhase, uint16 desiredQty, bool claim) internal returns (address) {
        LibEIP712.Layout storage e = LibEIP712.layout();

        _checkVoucherConditions(voucher, currentPhase, desiredQty);

        // make sure signature is valid and get the address of the signer
        address signer = _verifyMintVoucher(e, voucher);

        // in public mint phase, dont claim voucher; fall back to per-address mint checks
        if (!claim) return signer;

        // make sure that the voucher has not redeemed more than its allotted amount
        if (e.isVoucherClaimed(voucher.nonce, voucher.qty, desiredQty)) {
            revert VoucherClaimed();
        }

        // mark the voucher claimed so that it can not be reused in the future
        e.claimVoucher(voucher.nonce, desiredQty);

        return signer;
    }

    /**
     * @dev   Checks basic features of the voucher to make sure it is being consumed when/how expected.
     * @param voucher - A MintVoucher describing a user's mint details.
     * @param currentPhase - the current mint phase.
     * @param desiredQty - a qty that a user chooses to consume.
     */
    function _checkVoucherConditions(MintVoucher memory voucher, uint40 currentPhase, uint16 desiredQty) internal {
        // in phase 3
        //      -yes -make sure caller is using the voucher associated with open mint
        //      -no  -make sure caller is using a voucher assigned to them
        if (currentPhase == 3 ? voucher.addr != address(this) : voucher.addr != msg.sender) {
            revert VoucherAddress();
        }

        if (voucher.phase > currentPhase) {
            revert MintPhase();
        }

        if (desiredQty > voucher.qty) {
            revert VoucherQty();
        }

        // enforce minting fee included
        if (msg.value != (voucher.free == 1 ? 0 : (_getMintFee(currentPhase, desiredQty)))) {
            revert MintFee();
        }
    }
}