//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IWeth9 is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}