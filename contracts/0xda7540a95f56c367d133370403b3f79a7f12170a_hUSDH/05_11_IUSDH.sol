// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IUSDH {
    function increaseLiquidity(uint256 _amount0) external returns (uint256);
    function decreaseLiquidity(uint256 _amount) external returns (bool);
    function mint(address _collateral, uint256 _amount, bool _exactOutput) external;
    function redeem(uint256 _amount) external returns (address[] memory);
    function getLargestBalance() external returns (address, uint256);
}