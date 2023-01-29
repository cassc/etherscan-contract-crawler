// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev ERC20 token with a mint control feature
 */
interface IERC20MintFeature {

    /**
     * @notice Mint tokens to a single address
     * @dev Only the MINTER_ROLE can mint tokens.
     */
    function mint(address account, uint256 amount) external;

    /**
     * @notice Mint tokens to a set of address
     * @dev Only the MINTER_ROLE can mint tokens. Should set the role
     */
    function bulkMint(address[] calldata accounts, uint256[] calldata amounts) external;

}