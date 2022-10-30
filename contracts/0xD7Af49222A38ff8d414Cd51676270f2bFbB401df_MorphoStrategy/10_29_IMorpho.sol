// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IMorpho {
  function claimRewards(address[] calldata _cTokenAddresses, bool _tradeForMorphoToken) external;
  function supply(address _poolTokenAddress, address _onBehalf, uint256 _amount) external;
  function supplyBalanceInOf(address,address) external view returns (uint256 inP2P, uint256 onPool);
  function withdraw(address _poolTokenAddress, uint256 _amount) external;
}