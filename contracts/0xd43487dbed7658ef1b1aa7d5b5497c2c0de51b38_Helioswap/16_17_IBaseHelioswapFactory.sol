// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IBaseHelioswapFactory {
    function defaults() external view returns(uint256 defaultFee, uint256 defaultSlippageFee, uint256 defaultDecayPeriod);

    function defaultFee() external view returns(uint256);
    function defaultSlippageFee() external view returns(uint256);
    function defaultDecayPeriod() external view returns(uint256);

    function setDefaultFee(uint256) external returns(uint256);
    function setDefaultSlippageFee(uint256) external returns(uint256);
    function setDefaultDecayPeriod(uint256) external returns(uint256);

    function isActive() external view returns (bool);
}