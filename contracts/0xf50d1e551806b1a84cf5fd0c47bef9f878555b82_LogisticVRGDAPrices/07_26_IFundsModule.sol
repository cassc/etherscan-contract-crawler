// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./ISlicer.sol";
import "./ISliceCore.sol";

interface IFundsModule {
  function JBProjectId() external view returns (uint256 projectId);

  function sliceCore() external view returns (ISliceCore sliceCoreAddress);

  function balances(address account, address currency)
    external
    view
    returns (uint128 accountBalance, uint128 protocolPayment);

  function depositEth(address account, uint256 protocolPayment)
    external
    payable;

  function depositTokenFromSlicer(
    uint256 tokenId,
    address account,
    address currency,
    uint256 amount,
    uint256 protocolPayment
  ) external;

  function withdraw(address account, address currency) external;

  function batchWithdraw(address account, address[] memory currencies) external;

  function withdrawOnRelease(
    uint256 tokenId,
    address account,
    address currency,
    uint256 amount,
    uint256 protocolPayment
  ) external payable;

  function batchReleaseSlicers(
    ISlicer[] memory slicers,
    address account,
    address currency,
    bool triggerWithdraw
  ) external;
}