//SPDX-License-Identifier: Skillet-Group
pragma solidity ^0.8.0;

import './PaymentManager.sol';
import './SafeTransferrable.sol';
import './SafeWithdrawable.sol';
import './ProtocolExecutionManager.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract SkilletContract is
  Ownable,
  Pausable,
  SafeWithdrawable,
  PaymentManager,
  SafeTransferrable, 
  ProtocolExecutionManager
{

  constructor(address feeManagerAddress) {
    setAlwaysWithdrawWeth(true);
    setFeeManager(feeManagerAddress);
  }

  receive() external payable {}

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function liquidate(
    PaymentOptionParams[] memory paymentOptions,
    BulkTransferParams[] memory transfers,
    ProxyApprovalParams[] memory proxyApprovals,
    ProtocolExecutionParams[] calldata protocols
  ) public
    whenNotPaused
  {

    /* 1. Get all initial payment token balances */
    uint256[] memory initBalances = getAllPaymentTokenBalances(paymentOptions);

    /* 2. Transfer all assets to contract */
    bulkTransferAllAssets(transfers);

    /* 3. Set Approvals for all Protocol Proxies */
    bulkCheckAndSetAllProxyApprovals(proxyApprovals);

    /* 4. Liquidate into each protocol, grouped by protocol */
    bulkExecuteProtocols(protocols);

    /* 4. Pay seller all owed payments */
    paySellerAllPayments(
      initBalances,
      paymentOptions
    );
  }
}