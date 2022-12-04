// SPDX-License-Identifier: MIT

////////////////////////////////////////////////solarde.fi//////////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\_________________/\\\\\\\\\_______/\\\\\\\\\_____        //
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

import {LibERC20} from "../LibERC20.sol";
import {IERC20Errors} from "../errors/IERC20Errors.sol";
import {LibSimpleBlacklist} from "../../../blacklist/LibSimpleBlacklist.sol";
import {LibPausable} from "../../../pausable/LibPausable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract ERC20Facet is IERC20, IERC20Metadata {
    /**
     * @inheritdoc IERC20
     */
    function transfer(address to, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        LibPausable.enforceNotPaused(to, address(0));

        LibSimpleBlacklist.enforceNotBlacklisted();
        LibSimpleBlacklist.enforceNotBlacklisted(to);

        LibERC20.transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @inheritdoc IERC20
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external virtual override returns (bool) {
        LibPausable.enforceNotPaused(from, to);

        LibSimpleBlacklist.enforceNotBlacklisted();
        LibSimpleBlacklist.enforceNotBlacklisted(from);
        LibSimpleBlacklist.enforceNotBlacklisted(to);

        LibERC20.spendAllowance(from, msg.sender, amount);
        LibERC20.transfer(from, to, amount);
        return true;
    }

    /**
     * @inheritdoc IERC20
     */
    function balanceOf(address account)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return LibERC20.balanceOf(account);
    }

    /**
     * @inheritdoc IERC20
     */
    function allowance(address owner, address spender)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return LibERC20.allowance(owner, spender);
    }

    /**
     * @inheritdoc IERC20
     */
    function approve(address spender, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        LibERC20.approve(msg.sender, spender, amount);
        return true;
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
        public
        virtual
        returns (bool)
    {
        LibERC20.approve(
            msg.sender,
            spender,
            LibERC20.allowance(msg.sender, spender) + addedValue
        );
        return true;
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
        uint256 currentAllowance = LibERC20.allowance(msg.sender, spender);
        if (subtractedValue > currentAllowance) {
            revert IERC20Errors.ERC20DecreasedAllowanceBelowZero(
                subtractedValue,
                currentAllowance
            );
        }

        unchecked {
            LibERC20.approve(
                msg.sender,
                spender,
                currentAllowance - subtractedValue
            );
        }

        return true;
    }

    /**
     * @inheritdoc IERC20
     */
    function totalSupply() external view virtual override returns (uint256) {
        return LibERC20.totalSupply();
    }

    /**
     * @inheritdoc IERC20Metadata
     */
    function name() external view virtual override returns (string memory) {
        return LibERC20.getName();
    }

    /**
     * @inheritdoc IERC20Metadata
     */
    function symbol() external view virtual override returns (string memory) {
        return LibERC20.getSymbol();
    }

    /**
     * @inheritdoc IERC20Metadata
     */
    function decimals() external view virtual override returns (uint8) {
        return 18;
    }
}