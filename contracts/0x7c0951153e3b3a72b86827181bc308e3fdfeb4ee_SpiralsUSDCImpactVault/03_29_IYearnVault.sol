// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IYearnVault is IERC20Upgradeable {
    function deposit(uint256 amount, address recipient)
        external
        returns (uint256);

    function withdraw(uint256 maxShares, address recipient)
        external
        returns (uint256);

    function token() external view returns (address);

    function totalSupply() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function lockedProfit() external view returns (uint256);
}