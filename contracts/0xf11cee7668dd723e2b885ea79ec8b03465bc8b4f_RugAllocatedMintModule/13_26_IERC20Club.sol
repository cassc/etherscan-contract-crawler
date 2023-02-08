// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC1644} from "src/contracts/utils/IERC1644.sol";
import {ITokenEnforceable} from "src/contracts/TokenEnforceable/ITokenEnforceable.sol";
import {ITokenRecoverable} from "src/contracts/utils/TokenRecoverable/ITokenRecoverable.sol";

/**
 * @title IERC20ClubUnchained
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Interface for only functions defined in `ERC20Club` (excludes inherited and
 * overriden functions)
 */
interface IERC20ClubUnchained is IERC1644 {
    event MemberJoined(address indexed member);
    event MemberExited(address indexed member);

    /**
     * Initializes `ERC20Club`.
     *
     * Emits an `Initialized` event.
     *
     * @param name_ Name of token
     * @param symbol_ Symbol of token
     * @param mintGuard_ Address of mint guard
     * @param burnGuard_ Address of burn guard
     * @param transferGuard_ Address of transfer guard
     */
    // solhint-disable-next-line func-name-mixedcase
    function __ERC20Club_init(
        string memory name_,
        string memory symbol_,
        address mintGuard_,
        address burnGuard_,
        address transferGuard_
    ) external;

    /**
     * @return Number of addresses that currently hold tokens.
     */
    function memberCount() external view returns (uint256);

    /**
     * @return True after successfully executing mint and transfer of
     * `amount` tokens to `account`.
     *
     * Emits a `Transfer` event with `address(0)` as `from`. Emits a
     * `MemberJoined` event if `account` is a new member.
     *
     * Requirements:
     * - `account` cannot be the zero address.
     * @param account The account to receive the minted tokens.
     * @param amount The quantity of tokens to mint.
     */
    function mintTo(address account, uint256 amount) external returns (bool);

    /**
     * @return True after successfully burning `amount` of the caller's tokens.
     *
     * Emits a `Transfer` event with `address(0)` as `to`. Emits a
     * `MemberExited` event if the caller has no balance after burning.
     *
     * Requirements:
     * - The caller must have at least `amount` tokens.
     * - The caller cannot be the zero address.
     * @param amount The quantity of tokens to be burned.
     */
    function redeem(uint256 amount) external returns (bool);

    /**
     * @return True after successfully burning `amount` of `account`'s tokens.
     *
     * Emits a `Transfer` event with `address(0)` as `to`. Emits a
     * `MemberExited` event if the caller has no balance after burning.
     *
     * Requirements:
     * - The caller must either be `account` or be approved to spend at least
     * `amount` of `account`'s tokens.
     * - `account` cannot be the zero address.
     * @param amount The quantity of tokens to be burned.
     */
    function redeemFrom(address account, uint256 amount)
        external
        returns (bool);
}

/**
 * @title IERC20Club
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Interface for all functions in `ERC20Club`, including inherited and
 * overriden functions.
 */
interface IERC20Club is
    IERC20,
    IERC20Metadata,
    ITokenEnforceable,
    IERC20ClubUnchained
{

}