// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMBLK is IERC20{
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed owner, uint256 value);

    function mint(address account_, uint256 amount_) external;
    
    function burn(uint256 amount_) external;
}