// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IUtilityToken is IERC20{
     /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(
        uint256 amount,
        uint256 serviceId,
        bytes calldata data
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(
        address account,
        uint256 amount,
        uint256 serviceId,
        bytes calldata data
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`.
     *
     * See {ERC20-_burn}.
     *
     * Requirements:
     *
     * - The sender must be granted the EXTERNAL_SPENDER_ROLE role.
     */
    function externalBurnFrom(
        address account,
        uint256 amount,
        uint256 serviceId,
        bytes calldata data
    ) external;
}