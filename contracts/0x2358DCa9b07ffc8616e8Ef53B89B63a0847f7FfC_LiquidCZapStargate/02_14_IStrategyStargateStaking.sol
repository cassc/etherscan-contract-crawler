// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

interface IStrategyStargateStaking {
    function chef() external view returns (address);
    function poolId() external view returns (uint256);
    function stargateRouter() external view returns (address);
    function routerPoolId() external view returns (uint256);
    function vault() external view returns (address);
    function feeStrate() external view returns (address);

    function deposit() external;
    function afterDepositFee(uint256 shares) external view returns(uint256);
    function withdraw(uint256 _amount) external returns(uint256);
    function withdrawFee(uint256 _amount) external;
    function beforeDeposit() external;

    function balanceOf() external view returns (uint256);
    function balanceOfWant() external view returns (uint256);
    function balanceOfPool() external view returns (uint256);
    function rewardsAvailable() external view returns (uint256);
    function callReward() external view returns (uint256);
    function retireStrat() external;
    function outputToNative() external view returns (address[] memory);
    function outputToLp0() external view returns (address[] memory);
}