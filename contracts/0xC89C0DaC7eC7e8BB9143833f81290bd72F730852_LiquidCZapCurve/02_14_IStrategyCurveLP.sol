// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

interface IStrategyCurveLP {
    function rewardsGauge() external view returns (address);
    function pool() external view returns (address);
    function poolSize() external view returns (uint);
    function useUnderlying() external view returns (bool);
    function useMetapool() external view returns (bool);
    function vault() external view returns (address);
    function feeStrate() external view returns (address);
    function inputTokens(uint256 i) external view returns (address);

    function deposit() external;
    function afterDepositFee(uint256 shares) external view returns(uint256);
    function withdraw(uint256 _amount) external returns(uint256);
    function withdrawFee(uint256 _amount) external;
    function beforeDeposit() external;

    function balanceOf() external view returns (uint256);
    function balanceOfWant() external view returns (uint256);
    function balanceOfPool() external view returns (uint256);
    function crvToNative() external view returns(address[] memory);
    function nativeToDeposit() external view returns(address[] memory);
    function rewardsAvailable() external view returns (uint256);
    function callReward() external view returns (uint256);
    function retireStrat() external;
}