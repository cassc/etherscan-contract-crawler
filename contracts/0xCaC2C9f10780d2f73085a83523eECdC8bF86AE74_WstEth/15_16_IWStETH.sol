// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract IWStETH is ERC20 {
    function unwrap(uint256 _wstETHAmount) external virtual returns (uint256);

    function getWstETHByStETH(
        uint256 _stETHAmount
    ) external view virtual returns (uint256);

    function getStETHByWstETH(
        uint256 _wstETHAmount
    ) external view virtual returns (uint256);

    function stEthPerToken() external view virtual returns (uint256);
}