// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0; 

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";


interface IIERC20 is IERC20Upgradeable {

   function mint(address _to, uint256 _amount) external;
   function transferOwnership(address newOwner) external;

}