//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract HoneyTokenI is Ownable, IERC20 {
    function mint(address _owner, uint256 _amount) external virtual;
    function burn(address _owner, uint256 _amount) external virtual;

    function maxSupply() external pure virtual returns (uint256);
}