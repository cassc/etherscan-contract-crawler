// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC20 Token Standard, optional extension: Detailed.
/// @dev See https://eips.ethereum.org/EIPS/eip-20
/// @dev Note: the ERC-165 identifier for this interface is 0xa219a025.
interface IERC20Detailed {
    /// @notice Gets the name of the token. E.g. "My Token".
    /// @return tokenName The name of the token.
    function name() external view returns (string memory tokenName);

    /// @notice Gets the symbol of the token. E.g. "TOK".
    /// @return tokenSymbol The symbol of the token.
    function symbol() external view returns (string memory tokenSymbol);

    /// @notice Gets the number of decimals used to display the balances.
    /// @notice For example, if `decimals` equals `2`, a balance of `505` tokens should be displayed to a user as `5,05` (`505 / 10 ** 2`).
    /// @notice Tokens usually opt for a value of 18, imitating the relationship between Ether and Wei.
    /// @dev Note: This information is only used for display purposes: it does  not impact the arithmetic of the contract.
    /// @return nbDecimals The number of decimals used to display the balances.
    function decimals() external view returns (uint8 nbDecimals);
}