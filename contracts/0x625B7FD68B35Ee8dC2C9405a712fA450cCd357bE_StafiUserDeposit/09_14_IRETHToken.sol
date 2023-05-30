pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

interface IRETHToken {
    function getEthValue(uint256 _rethAmount) external view returns (uint256);
    function getRethValue(uint256 _ethAmount) external view returns (uint256);
    function getExchangeRate() external view returns (uint256);
    function getTotalCollateral() external view returns (uint256);
    function getCollateralRate() external view returns (uint256);
    function depositRewards() external payable;
    function depositExcess() external payable;
    function userMint(uint256 _ethAmount, address _to) external;
    function userBurn(uint256 _rethAmount) external;
}