// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IOperable is IERC20{
    function mint(uint256 amount) external;
    function burn(uint amount) external;
    function raise(uint256 amount) external view returns (uint256);
}