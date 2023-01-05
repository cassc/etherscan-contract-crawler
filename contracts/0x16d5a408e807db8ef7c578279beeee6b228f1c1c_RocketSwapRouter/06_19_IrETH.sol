// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IrETH is IERC20 {
    function getTotalCollateral() external view returns (uint256);
    function burn(uint256 _rethAmount) external;
    function getEthValue(uint256 _rethAmount) external view returns (uint256);
    function getRethValue(uint256 _ethAmount) external view returns (uint256);
}