// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IUnoFarmPancakeswap {
    struct SwapInfo{
        address[] route;
        uint256 amountOutMin;
    }
    struct FeeInfo {
        address feeTo;
        uint256 fee;
    }

    function rewardToken() external view returns (address);
    function lpPair() external view returns (address);
    function tokenA() external view returns (address);
    function tokenB() external view returns (address);
    function pid() external view returns (uint256);
    function assetRouter() external view returns (address);

    function initialize( address _lpPair, address _assetRouter) external;

    function deposit(uint256 amount, address recipient) external;
    function withdraw(uint256 amount, uint256 amountAMin, uint256 amountBMin, bool withdrawLP, address origin, address recipient) external returns(uint256 amountA, uint256 amountB);

    function distribute(
        SwapInfo[2] calldata swapInfos,
        SwapInfo calldata feeSwapInfo,
        FeeInfo calldata feeInfo
    ) external returns(uint256 reward);

    function userBalance(address _address) external view returns (uint256);
    function getTotalDeposits() external view returns (uint256);
}