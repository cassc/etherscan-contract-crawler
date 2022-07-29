// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILoot {
    /**
     * @dev Mints the amount of tokens of token type `id` `to` user.
     */
    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity
    ) external;
}