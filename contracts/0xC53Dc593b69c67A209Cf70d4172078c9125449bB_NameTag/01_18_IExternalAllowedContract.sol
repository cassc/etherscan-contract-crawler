// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


interface IExternalAllowedContract {
    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);
}