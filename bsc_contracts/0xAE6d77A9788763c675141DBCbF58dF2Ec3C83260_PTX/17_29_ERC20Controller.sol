// SPDX-License-Identifier: MIT

// Developed by:
//////////////////////////////////////////////solarprotocol.io//////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\__0xFluffyBeard__/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\_______________/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

import {LibProtocolX} from "../libraries/LibProtocolX.sol";
import {LibContext} from "../libraries/LibContext.sol";
import {LibPausable} from "../pausable/LibPausable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

/**
 * @dev External controller for LibProtocolX exposing the ERC20 related functions.
 */
abstract contract ERC20Controller is IERC20, IERC20Metadata {
    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return LibProtocolX.name();
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return LibProtocolX.symbol();
    }

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external pure returns (uint8) {
        return LibProtocolX.decimals();
    }

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256) {
        return LibProtocolX.totalSupply();
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256) {
        return LibProtocolX.balanceOf(account);
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool) {
        LibPausable.enforceNotPaused();
        LibProtocolX.enforceValidRecipient(to);

        return LibProtocolX.transferFrom(LibContext.msgSender(), to, amount);
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256)
    {
        return LibProtocolX.allowance(owner, spender);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        LibPausable.enforceNotPaused();

        return LibProtocolX.approve(LibContext.msgSender(), spender, amount);
    }

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        LibPausable.enforceNotPaused();
        LibProtocolX.enforceValidRecipient(to);

        LibProtocolX.spendAllowance(from, LibContext.msgSender(), amount);
        return LibProtocolX.transferFrom(from, to, amount);
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        LibPausable.enforceNotPaused();

        address owner = LibContext.msgSender();
        return
            LibProtocolX.approve(
                owner,
                spender,
                LibProtocolX.allowance(owner, spender) + addedValue
            );
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        LibPausable.enforceNotPaused();

        address owner = LibContext.msgSender();
        uint256 currentAllowance = LibProtocolX.allowance(owner, spender);

        if (subtractedValue > currentAllowance) {
            subtractedValue = currentAllowance;
        }

        unchecked {
            return
                LibProtocolX.approve(
                    owner,
                    spender,
                    currentAllowance - subtractedValue
                );
        }
    }
}