// SPDX-License-Identifier: MIT



pragma solidity ^0.8.0;

interface IWombatPoolHelperV2Reader {
    function isNative() external view returns(bool);
    function depositToken() external view returns(address);
    function lpToken() external view returns(address);
    function pid() external view returns(uint256);
    function stakingToken() external view returns(address);
    function balance(address _address) external  view returns (uint256);
}