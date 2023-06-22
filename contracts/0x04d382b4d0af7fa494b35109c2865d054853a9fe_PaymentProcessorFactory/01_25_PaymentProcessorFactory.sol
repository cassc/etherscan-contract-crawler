// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../PaymentProcessor.sol';
import '../../../interfaces/IJBDirectory.sol';
import '../../../interfaces/IJBOperatorStore.sol';
import '../../../interfaces/IJBProjects.sol';
import '../../TokenLiquidator.sol';

/**
 * @notice Creates an instance of PaymentProcessor contract
 */
library PaymentProcessorFactory {
  /**
   * @notice Deploys a PaymentProcessor.
   */
  function createPaymentProcessor(
    IJBDirectory _jbxDirectory,
    IJBOperatorStore _jbxOperatorStore,
    IJBProjects _jbxProjects,
    ITokenLiquidator _liquidator,
    uint256 _jbxProjectId,
    bool _ignoreFailures,
    bool _defaultLiquidation
  ) external returns (address paymentProcessor) {
    PaymentProcessor p = new PaymentProcessor(
      _jbxDirectory,
      _jbxOperatorStore,
      _jbxProjects,
      _liquidator,
      _jbxProjectId,
      _ignoreFailures,
      _defaultLiquidation
    );

    return address(p);
  }
}