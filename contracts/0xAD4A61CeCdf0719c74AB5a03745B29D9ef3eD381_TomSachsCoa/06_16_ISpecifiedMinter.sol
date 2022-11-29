// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/*----------------------------------------------------------\
|                             _                 _           |
|        /\                  | |     /\        | |          |
|       /  \__   ____ _ _ __ | |_   /  \   _ __| |_ ___     |
|      / /\ \ \ / / _` | '_ \| __| / /\ \ | '__| __/ _ \    |
|     / ____ \ V / (_| | | | | |_ / ____ \| |  | ||  __/    |
|    /_/    \_\_/ \__,_|_| |_|\__/_/    \_\_|   \__\___|    |
|                                                           |
|    https://avantarte.com/careers                          |
|    https://avantarte.com/support/contact                  |
|                                                           |
\----------------------------------------------------------*/

/**
 * @title An interface for a contract that allows minting with a specified token id
 * @author Liron Navon
 * @dev This interface is used for connecting to the lazy minting contracts.
 */
interface ISpecifiedMinter {
    function mint(address to, uint256 tokenId) external returns (uint256);
}