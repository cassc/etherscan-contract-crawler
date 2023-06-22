// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IAeon is IERC20 {
    function mint(address to, uint256 qty) external;

    function burn(uint256 qty) external;

    function burnFrom(address from, uint256 qty) external;
}