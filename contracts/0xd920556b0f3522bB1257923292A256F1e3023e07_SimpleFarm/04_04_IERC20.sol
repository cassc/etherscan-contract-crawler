// SPDX-License-Identifier: -- BCOM --

pragma solidity =0.8.19;

interface IERC20 {

    /**
     * @dev Interface fo transfer function
     */
    function transfer(
        address recipient,
        uint256 amount
    )
        external
        returns (bool);

    /**
     * @dev Interface for transferFrom function
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        external
        returns (bool);
}