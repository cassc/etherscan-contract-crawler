// SPDX-License-Identifier: PROPRIERTARY

// Author: Ilya A. Shlyakhovoy
// Email: [email protected]

pragma solidity 0.8.17;

interface IMaternity {
    event Born(address indexed owner_, uint256 indexed id);
    event Grow(address indexed owner_, uint256 indexed id);
    event Adult(address indexed owner_, uint256 indexed id);

    /**
@notice Birth the person. Takes the needed amount of tokens from the caller account
@param id Person token id
*/
    function born(uint256 id) external;

    /**
@notice Get the max grow payment
@param id Person token id
@return Price for grow
*/
    function growPrice(uint256 id) external returns (uint256);

    /**
@notice Get the amount of seconds for the payment
@param id Person token id
@param amount Amount of tokens transferred
@return Time in secs for grow
*/
    function growTime(uint256 id, uint256 amount) external returns (uint256);

    /**
@notice Grow the non-adult person. Takes the provided amount of tokens from 
the caller account, but not more than needed
@param id Person token id
@param amount Amount of tokens transferred
*/
    function grow(uint256 id, uint256 amount) external;
}