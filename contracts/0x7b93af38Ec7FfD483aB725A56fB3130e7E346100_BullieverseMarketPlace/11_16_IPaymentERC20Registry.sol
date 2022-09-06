//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

interface IPaymentERC20Registry {  
  function isApprovedERC20(address _token) external view returns (bool);

  function addApprovedERC20(address _token) external;

  function removeApprovedERC20(address _token) external;
}