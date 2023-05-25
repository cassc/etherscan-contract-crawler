// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "openzeppelin-contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IDZooToken is IERC20Permit, IERC20 {
    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must be the DZooNFT contract.
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * See {ERC20-_burn}.
     *
     * Requirements:
     *
     * - the caller must be the DZooNFT contract.
     */
    function burn(address to, uint256 amount) external;
}