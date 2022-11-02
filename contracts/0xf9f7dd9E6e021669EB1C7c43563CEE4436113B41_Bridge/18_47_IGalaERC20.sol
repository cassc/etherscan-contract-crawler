//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGalaERC20 is IERC20 {
    function mintBulk(address[] memory accounts, uint256[] memory amounts) external returns (bool);

    function burn(uint256 amount) external;
}