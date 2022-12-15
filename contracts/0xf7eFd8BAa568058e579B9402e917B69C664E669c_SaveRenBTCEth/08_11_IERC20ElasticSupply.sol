// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";


/**
* @title IERC20ElasticSupply
* @author Geminon Protocol
* @dev Interface for the ERC20ElasticSupply contract
*/
interface IERC20ElasticSupply is IERC20 {

    function addMinter(address newMinter) external;
    function removeMinter(address minter) external;
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function maxAmountMintable() external view returns(uint256);
}