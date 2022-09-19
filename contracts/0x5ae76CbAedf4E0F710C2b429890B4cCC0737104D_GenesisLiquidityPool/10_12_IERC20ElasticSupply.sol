// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";



/**
* @title IERC20ElasticSupply
* @author Geminon Protocol
* @dev Interface for the ERC20ElasticSupply contract
*/
interface IERC20ElasticSupply is IERC20 {

    event TokenMinted(address indexed from, address indexed to, uint256 amount);

    event TokenBurned(address indexed from, address indexed to, uint256 amount);

    event MinterAdded(address minter_address);

    event MinterRemoved(address minter_address);

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function addMinter(address newMinter) external;

    function removeMinter(address minter) external;
}