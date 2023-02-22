// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBFundAccessConstraints.sol';
import './IJBPaymentTerminal.sol';

interface IJBFundAccessConstraintsStore is IERC165 {
  event SetFundAccessConstraints(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed projectId,
    JBFundAccessConstraints constraints,
    address caller
  );

  function distributionLimitOf(
    uint256 _projectId,
    uint256 _configuration,
    IJBPaymentTerminal _terminal,
    address _token
  ) external view returns (uint256 distributionLimit, uint256 distributionLimitCurrency);

  function overflowAllowanceOf(
    uint256 _projectId,
    uint256 _configuration,
    IJBPaymentTerminal _terminal,
    address _token
  ) external view returns (uint256 overflowAllowance, uint256 overflowAllowanceCurrency);

  function setFor(
    uint256 _projectId,
    uint256 _configuration,
    JBFundAccessConstraints[] memory _fundAccessConstaints
  ) external;
}