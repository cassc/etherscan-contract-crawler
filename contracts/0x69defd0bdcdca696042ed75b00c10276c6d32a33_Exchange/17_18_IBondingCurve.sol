// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

/// @title abbreviated curve interface for BZZ bonding curve
/// @dev refer https://github.com/ethersphere/bzzaar-contracts/blob/main/packages/chain/contracts/Curve.sol
interface IBondingCurve {
    function buyPrice(uint256 _amount) external view returns (uint256);
    function sellReward(uint256 _amount) external view returns (uint256);
    function collateralToken() external view returns (address);
    function bondedToken() external view returns (address);
    function mint(uint256 _amount, uint256 _maxCollateralSpend) external returns (bool success);
    function mintTo(uint256 _amount, uint256 _maxCollateralSpend, address _to) external returns (bool);
    function redeem(uint256 _amount, uint256 _minCollateralReward) external returns (bool success);
}