// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IFewl is IERC20 {

    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}