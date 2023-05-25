// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC20 Token Standard, optional extension: Detailed
 * See https://eips.ethereum.org/EIPS/eip-20
 * Note: the ERC-165 identifier for this interface is 0xa219a025.
 */
interface IERC20Detailed {
    /**
     * Returns the name of the token. E.g. "My Token".
     * @return The name of the token.
     */
    function name() external view returns (string memory);

    /**
     * Returns the symbol of the token. E.g. "HIX".
     * @return The symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * Returns the number of decimals used to display the balances.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it does  not impact the arithmetic of the contract.
     * @return The number of decimals used to display the balances.
     */
    function decimals() external view returns (uint8);
}