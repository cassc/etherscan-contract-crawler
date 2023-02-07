// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {ITokenRecoverable} from "./ITokenRecoverable.sol";
import {IGuard} from "src/contracts/guards/IGuard.sol";

/**
 * @title ITokenEnforceable
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Interface for tokens with modular conditions on mint, burn, and transfer
 * functions enforced by Guard contracts, such as `ERC20Club` and
 * `ERC721Collective`.
 */
interface ITokenEnforceable is ITokenRecoverable {
    event ControlDisabled(address indexed controller);
    event BatcherUpdated(address batcher);
    event GuardUpdated(GuardType indexed guard, address indexed implementation);
    event GuardLocked(
        bool mintGuardLocked,
        bool burnGuardLocked,
        bool transferGuardLocked
    );

    /**
     * @return The address of the transaction batcher used to batch calls over
     * onlyOwner functions.
     */
    function batcher() external view returns (address);

    /**
     * @return True iff the token contract owner is allowed to mint, burn, or
     * transfer on behalf of arbitrary addresses.
     */
    function isControllable() external view returns (bool);

    /**
     * @return The address of the Guard used to determine whether a mint is
     * allowed. The contract at this address is assumed to implement the IGuard
     * interface.
     */
    function mintGuard() external view returns (IGuard);

    /**
     * @return The address of the Guard used to determine whether a burn is
     * allowed. The contract at this address is assumed to implement the IGuard
     * interface.
     */
    function burnGuard() external view returns (IGuard);

    /**
     * @return The address of the Guard used to determine whether a transfer is
     * allowed. The contract at this address is assumed to implement the IGuard
     * interface.
     */
    function transferGuard() external view returns (IGuard);

    /**
     * @return True iff the mint Guard cannot be changed.
     */
    function mintGuardLocked() external view returns (bool);

    /**
     * @return True iff the burn Guard cannot be changed.
     */
    function burnGuardLocked() external view returns (bool);

    /**
     * @return True iff the transfer Guard cannot be changed.
     */
    function transferGuardLocked() external view returns (bool);

    /**
     * Irreversibly disables the token contract owner from minting, burning,
     * and transferring on behalf of arbitrary addresses.
     *
     * Emits a `ControlDisabled` event.
     *
     * Requirements:
     * - The caller must be the token contract owner or the batcher.
     */
    function disableControl() external;

    /**
     * Irreversibly prevents the token contract owner from changing the mint,
     * burn, and/or transfer Guards.
     *
     * If at least one guard was requested to be locked, emits a `GuardLocked`
     * event confirming whether each Guard is locked.
     *
     * Requirements:
     * - The caller must be the token contract owner or the batcher.
     * @param mintGuardLock If true, the mint Guard will be locked. If false,
     * does nothing to the mint Guard.
     * @param burnGuardLock If true, the mint Guard will be locked. If false,
     * does nothing to the burn Guard.
     * @param transferGuardLock If true, the mint Guard will be locked. If
     * false, does nothing to the transfer Guard.
     */
    function lockGuards(
        bool mintGuardLock,
        bool burnGuardLock,
        bool transferGuardLock
    ) external;

    /**
     * Update the address of the batcher for batching calls over
     * onlyOwner functions.
     *
     * Emits a `BatcherUpdated` event.
     *
     * Requirements:
     * - The caller must be the token contract owner or the batcher.
     * @param implementation Address of new batcher
     */
    function updateBatcher(address implementation) external;

    /**
     * Update the address of the Guard for minting. The contract at the
     * passed-in address is assumed to implement the IGuard interface.
     *
     * Emits a `GuardUpdated` event with `GuardType.Mint`.
     *
     * Requirements:
     * - The caller must be the token contract owner or the batcher.
     * - The mint Guard must not be locked.
     * @param implementation Address of new mint Guard
     */
    function updateMintGuard(address implementation) external;

    /**
     * Update the address of the Guard for burning. The contract at the
     * passed-in address is assumed to implement the IGuard interface.
     *
     * Emits a `GuardUpdated` event with `GuardType.Burn`.
     *
     * Requirements:
     * - The caller must be the token contract owner or the batcher.
     * - The burn Guard must not be locked.
     * @param implementation Address of new burn Guard
     */
    function updateBurnGuard(address implementation) external;

    /**
     * Update the address of the Guard for transferring. The contract at the
     * passed-in address is assumed to implement the IGuard interface.
     *
     * Emits a `GuardUpdated` event with `GuardType.Transfer`.
     *
     * Requirements:
     * - The caller must be the token contract owner or the batcher.
     * - The transfer Guard must not be locked.
     * @param implementation Address of transfer Guard
     */
    function updateTransferGuard(address implementation) external;

    /**
     * @return True iff a token can be minted, burned, or transferred by a
     * particular operator, from a particular sender (`from` is address 0 iff
     * the token is being minted), to a particular recipient (`to` is address 0
     * iff the token is being burned).
     * @param operator Transaction msg.sender
     * @param from Token sender
     * @param to Token recipient
     * @param value Amount (ERC20) or token ID (ERC721)
     */
    function isAllowed(
        address operator,
        address from,
        address to,
        uint256 value // amount (ERC20) or tokenId (ERC721)
    ) external view returns (bool);

    /**
     * @return owner The address of the token contract owner
     */
    function owner() external view returns (address);

    /**
     * Transfers ownership of the contract to a new account (`newOwner`)
     *
     * Emits an `OwnershipTransferred` event.
     *
     * Requirements:
     * - The caller must be the current owner.
     * @param newOwner Address that will become the owner
     */
    function transferOwnership(address newOwner) external;

    /**
     * Leaves the contract without an owner. After calling this function, it
     * will no longer be possible to call `onlyOwner` functions.
     *
     * Requirements:
     * - The caller must be the current owner.
     */
    function renounceOwnership() external;
}

enum GuardType {
    Mint,
    Burn,
    Transfer
}