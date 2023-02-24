// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IConvexToken is IERC20 {
    function totalCliffs() external view returns (uint256);

    function reductionPerCliff() external view returns (uint256);

    function maxSupply() external view returns (uint256);
}