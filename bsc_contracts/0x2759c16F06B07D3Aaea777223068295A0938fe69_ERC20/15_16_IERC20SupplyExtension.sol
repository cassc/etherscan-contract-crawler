// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @dev Extension of {ERC20} that tracks supply and defines a max supply cap.
 */
interface IERC20SupplyExtension {
    /**
     * @dev Maximum amount of tokens possible to exist.
     */
    function maxSupply() external view returns (uint256);
}