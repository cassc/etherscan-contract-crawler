// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./lib/utils/Context.sol";
import "./access/AdminAgent.sol";
import "./RegistrarClient.sol";

contract Registrar is Context, AdminAgent {

  address[] private _contracts;
  bool private _finalized;

  event SetContracts(address[] addresses);
  event SetContractByIndex(uint8 index, address contractAddressTo);
  event Finalize(address registrarAddress);

  /**
   * @dev Constructor that setup the owner of this contract.
   */
  constructor(address[] memory adminAgents_) AdminAgent(adminAgents_) {}

  modifier onlyUnfinalized() {
    require(_finalized == false, "Registrar already finalized");
    _;
  }

  function getContracts() external view returns (address[] memory) {
    return _contracts;
  }

  function setContracts(address[] calldata _addresses) external onlyAdminAgents onlyUnfinalized {
    _contracts = _addresses;
    emit SetContracts(_addresses);
  }

  function setContractByIndex(uint8 _index, address _address) external onlyAdminAgents onlyUnfinalized {
    _contracts[_index] = _address;
    emit SetContractByIndex(_index, _address);
  }

  function updateAllClients() external onlyAdminAgents onlyUnfinalized {
    IRegistrarClient(this.getMFCToken()).updateAddresses();
    IRegistrarClient(this.getMFCMembership()).updateAddresses();
    IRegistrarClient(this.getMFCExchange()).updateAddresses();
    IRegistrarClient(this.getMFCExchangeCap()).updateAddresses();
    IRegistrarClient(this.getMFCExchangeFloor()).updateAddresses();
    IRegistrarClient(this.getMFCCollateralLoan()).updateAddresses();
    IRegistrarClient(this.getBUSDT()).updateAddresses();
    IRegistrarClient(this.getMFCBuyback()).updateAddresses();
    IRegistrarClient(this.getMFCGovernance()).updateAddresses();
  }

  function getMFCToken() external view returns (address) {
    return _contracts[0];
  }

  function getBUSDT() external view returns (address) {
    return _contracts[1];
  }

  function getMFCMembership() external view returns (address) {
    return _contracts[2];
  }

  function getMFCExchange() external view returns (address) {
    return _contracts[3];
  }

  function getMFCExchangeCap() external view returns (address) {
    return _contracts[4];
  }

  function getMFCExchangeFloor() external view returns (address) {
    return _contracts[5];
  }

  function getMFCBuyback() external view returns (address) {
    return _contracts[6];
  }

  function getMFCGovernance() external view returns (address) {
    return _contracts[7];
  }

  function getMFCCollateralLoan() external view returns (address) {
    return _contracts[8];
  }

  function finalize() external onlyAdminAgents onlyUnfinalized {
    _finalized = true;
    emit Finalize(address(this));
  }

  function isFinalized() external view returns (bool) {
    return _finalized;
  }
}