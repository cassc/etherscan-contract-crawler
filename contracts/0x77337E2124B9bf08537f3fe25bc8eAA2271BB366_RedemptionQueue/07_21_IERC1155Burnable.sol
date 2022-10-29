// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @title IERC1155Burnable
 * @author Protofire
 * @dev IERC1155Burnable Interface.
 *
 */

interface IERC1155Burnable is IERC1155 {
    /**
     * @dev Burn erc 1155 Token
     */
    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) external;
}