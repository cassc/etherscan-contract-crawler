// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ISafEth {
    function stake(
        uint256 _minOut
    ) external payable returns (uint256 mintedAmount);

    function unstake(uint256 _safEthAmount, uint256 _minOut) external;

    function approxPrice(bool _validate) external view returns (uint256);

    function balanceOf(address _account) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}