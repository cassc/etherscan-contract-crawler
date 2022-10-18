// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IICHIVault is IERC20 {
    function ichiVaultFactory() external view returns (address);

    function pool() external view returns (address);

    function token0() external view returns (address);

    function allowToken0() external view returns (bool);

    function token1() external view returns (address);

    function allowToken1() external view returns (bool);

    function fee() external view returns (uint24);

    function tickSpacing() external view returns (int24);

    function affiliate() external view returns (address);

    function baseLower() external view returns (int24);

    function baseUpper() external view returns (int24);

    function limitLower() external view returns (int24);

    function limitUpper() external view returns (int24);

    function deposit0Max() external view returns (uint256);

    function deposit1Max() external view returns (uint256);

    function maxTotalSupply() external view returns (uint256);

    function hysteresis() external view returns (uint256);

    function getTotalAmounts() external view returns (uint256, uint256);

    function deposit(
        uint256,
        uint256,
        address
    ) external returns (uint256);

    function withdraw(uint256, address) external returns (uint256, uint256);

    function rebalance(
        int24 _baseLower,
        int24 _baseUpper,
        int24 _limitLower,
        int24 _limitUpper,
        int256 swapQuantity
    ) external;

    function setDepositMax(uint256 _deposit0Max, uint256 _deposit1Max) external;

    function setAffiliate(address _affiliate) external;

    event DeployICHIVault(
        address indexed sender,
        address indexed pool,
        bool allowToken0,
        bool allowToken1,
        address owner,
        uint256 twapPeriod
    );

    event SetTwapPeriod(address sender, uint32 newTwapPeriod);

    event Deposit(
        address indexed sender,
        address indexed to,
        uint256 shares,
        uint256 amount0,
        uint256 amount1
    );

    event Withdraw(
        address indexed sender,
        address indexed to,
        uint256 shares,
        uint256 amount0,
        uint256 amount1
    );

    event Rebalance(
        int24 tick,
        uint256 totalAmount0,
        uint256 totalAmount1,
        uint256 feeAmount0,
        uint256 feeAmount1,
        uint256 totalSupply
    );

    event MaxTotalSupply(address indexed sender, uint256 maxTotalSupply);

    event Hysteresis(address indexed sender, uint256 hysteresis);

    event DepositMax(
        address indexed sender,
        uint256 deposit0Max,
        uint256 deposit1Max
    );

    event Affiliate(address indexed sender, address affiliate);
}