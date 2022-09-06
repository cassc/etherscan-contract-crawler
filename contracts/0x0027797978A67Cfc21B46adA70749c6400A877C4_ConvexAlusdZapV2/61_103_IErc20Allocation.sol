// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IERC20, IDetailedERC20} from "contracts/common/Imports.sol";

/**
 * @notice An asset allocation for tokens not stored in a protocol
 * @dev `IZap`s and `ISwap`s register these separate from other allocations
 * @dev Unlike other asset allocations, new tokens can be added or removed
 * @dev Registration can override `symbol` and `decimals` manually because
 * they are optional in the ERC20 standard.
 */
interface IErc20Allocation {
    /** @notice Log when an ERC20 allocation is registered */
    event Erc20TokenRegistered(IERC20 token, string symbol, uint8 decimals);

    /** @notice Log when an ERC20 allocation is removed */
    event Erc20TokenRemoved(IERC20 token);

    /**
     * @notice Add a new ERC20 token to the asset allocation
     * @dev Should not allow duplicate tokens
     * @param token The new token
     */
    function registerErc20Token(IDetailedERC20 token) external;

    /**
     * @notice Add a new ERC20 token to the asset allocation
     * @dev Should not allow duplicate tokens
     * @param token The new token
     * @param symbol Override the token symbol
     */
    function registerErc20Token(IDetailedERC20 token, string calldata symbol)
        external;

    /**
     * @notice Add a new ERC20 token to the asset allocation
     * @dev Should not allow duplicate tokens
     * @param token The new token
     * @param symbol Override the token symbol
     * @param decimals Override the token decimals
     */
    function registerErc20Token(
        IERC20 token,
        string calldata symbol,
        uint8 decimals
    ) external;

    /**
     * @notice Remove an ERC20 token from the asset allocation
     * @param token The token to remove
     */
    function removeErc20Token(IERC20 token) external;

    /**
     * @notice Check if an ERC20 token is registered
     * @param token The token to check
     * @return `true` if the token is registered, `false` otherwise
     */
    function isErc20TokenRegistered(IERC20 token) external view returns (bool);

    /**
     * @notice Check if multiple ERC20 tokens are ALL registered
     * @param tokens An array of tokens to check
     * @return `true` if every token is registered, `false` otherwise
     */
    function isErc20TokenRegistered(IERC20[] calldata tokens)
        external
        view
        returns (bool);
}