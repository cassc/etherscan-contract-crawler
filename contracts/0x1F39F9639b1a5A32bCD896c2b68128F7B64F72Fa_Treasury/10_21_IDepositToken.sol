// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";

interface IDepositToken is IERC20Metadata {
    function underlying() external view returns (IERC20);

    function collateralFactor() external view returns (uint256);

    function unlockedBalanceOf(address account_) external view returns (uint256);

    function lockedBalanceOf(address account_) external view returns (uint256);

    function deposit(uint256 amount_, address onBehalfOf_) external returns (uint256 _deposited, uint256 _fee);

    function quoteDepositIn(uint256 amountToDeposit_) external view returns (uint256 _amount, uint256 _fee);

    function quoteDepositOut(uint256 amount_) external view returns (uint256 _amountToDeposit, uint256 _fee);

    function quoteWithdrawIn(uint256 amountToWithdraw_) external view returns (uint256 _amount, uint256 _fee);

    function quoteWithdrawOut(uint256 amount_) external view returns (uint256 _amountToWithdraw, uint256 _fee);

    function withdraw(uint256 amount_, address to_) external returns (uint256 _withdrawn, uint256 _fee);

    function seize(
        address from_,
        address to_,
        uint256 amount_
    ) external;

    function updateCollateralFactor(uint128 newCollateralFactor_) external;

    function isActive() external view returns (bool);

    function toggleIsActive() external;

    function maxTotalSupply() external view returns (uint256);

    function updateMaxTotalSupply(uint256 newMaxTotalSupply_) external;
}