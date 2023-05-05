// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface INetworkPaymentAdapter {
  function topUp() external returns (uint256 _daiSent);
}