// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address account, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}