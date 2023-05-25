// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./AccessControlledOffchainAggregator.sol";
import "./AccessControlTestHelper.sol";

contract TestOffchainAggregator is AccessControlledOffchainAggregator {
  function testDecodeReport(
    bytes memory report
  ) public pure returns (bytes32, bytes32, int192[] memory)
  {
    return decodeReport(report);
  }

  constructor(
    uint32 _maximumGasPrice,
    uint32 _reasonableGasPrice,
    uint32 _microLinkPerEth,
    uint32 _linkGweiPerObservation,
    uint32 _linkGweiPerTransmission,
    LinkTokenInterface _link,
    int192 _minAnswer, int192 _maxAnswer,
    AccessControllerInterface _billingAccessController,
    AccessControllerInterface _requesterAdminAccessController
  )
    AccessControlledOffchainAggregator(_maximumGasPrice, _reasonableGasPrice, _microLinkPerEth,
      _linkGweiPerObservation, _linkGweiPerTransmission, _link,
      _minAnswer, _maxAnswer, _billingAccessController, _requesterAdminAccessController, 0, "TEST"
    )
  {}

  function testPayee(
    address _transmitter
  )
    external
    view
    returns (address)
  {
    return s_payees[_transmitter];
  }

  function getConfigDigest() public view returns (bytes16) {
    return s_hotVars.latestConfigDigest;
  }

  function testSaturatingAddUint16(uint16 _x, uint16 _y)
    external pure returns (uint16)
  {
    return saturatingAddUint16(_x, _y);
  }

  function testImpliedGasPrice(uint256 txGasPrice, uint256 reasonableGasPrice,
    uint256 maximumGasPrice
  ) external pure returns (uint256) {
    return impliedGasPrice(txGasPrice, reasonableGasPrice, maximumGasPrice);
  }

  function testTransmitterGasCostEthWei(uint256 initialGas, uint256 gasPrice,
    uint256 callDataCost, uint256 gasLeft
  ) external pure returns (uint128) {
    return transmitterGasCostEthWei(
      initialGas, gasPrice, callDataCost, gasLeft
    );
  }

  function testSetOracleObservationCount(address _oracle, uint16 _amount) external {
    s_oracleObservationsCounts[s_oracles[_oracle].index] = _amount + 1;
  }

  function testTotalLinkDue()
    external view returns (uint256 linkDue)
  {
    return totalLINKDue();
  }

  function billingData() external view returns (
    uint16[maxNumOracles] memory observationsCounts,
    uint256[maxNumOracles] memory gasReimbursements,
    uint32 maximumGasPrice,
    uint32 reasonableGasPrice,
    uint32 microLinkPerEth,
    uint32 linkGweiPerObservation,
    uint32 linkGweiPerTransmission
  ) {
    Billing memory b = s_billing;
    return (s_oracleObservationsCounts, s_gasReimbursementsLinkWei,
      b.maximumGasPrice, b.reasonableGasPrice, b.microLinkPerEth,
      b.linkGweiPerObservation, b.linkGweiPerTransmission);
  }

  function testSetGasReimbursements(address _transmitterOrSigner, uint256 _amountLinkWei)
    external
  {
    require(s_oracles[_transmitterOrSigner].role != Role.Unset, "address unknown");
    s_gasReimbursementsLinkWei[s_oracles[_transmitterOrSigner].index] = _amountLinkWei + 1;
  }

  function testAccountingGasCost() public pure returns (uint256) {
    return accountingGasCost;
  }

  function testBurnLINK(uint256 amount) public {
      s_linkToken.transfer(address(1), amount);
  }
}