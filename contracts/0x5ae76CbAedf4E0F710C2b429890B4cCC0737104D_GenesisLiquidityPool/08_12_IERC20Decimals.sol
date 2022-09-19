// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";


/**
* @title IERC20Decimals
* @author Geminon Protocol
* @dev Interface for ERC20 tokens that don't follow the
* 18 decimals standard. 
*/
interface IERC20Decimals is IERC20 {

    function decimals() external view returns(uint8);
}