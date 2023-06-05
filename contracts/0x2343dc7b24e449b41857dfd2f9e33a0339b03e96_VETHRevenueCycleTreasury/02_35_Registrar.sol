// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { AdminAgent } from "./access/AdminAgent.sol";
import { IRegistrarClient } from "./RegistrarClient.sol";
import { VYToken } from "./token/VYToken.sol";

contract Registrar is AdminAgent {

  bytes32 private constant ECOSYSTEM_ID = keccak256(bytes("VY_ETH"));

  address[] private _contracts;
  address[] private _prevContracts;
  bool private _finalized;

  event SetContracts(address[] addresses);
  event SetContractByIndex(uint8 index, address contractAddressTo);
  event Finalize(address registrarAddress);

  enum Contract {
    VYToken,
    VETHYieldRateTreasury,
    VETHP2P,
    VETHRevenueCycleTreasury,
    VETHGovernance,
    VETHReverseStakingTreasury
  }

  /**
   * @dev Constructor that setup the owner of this contract.
   */
  constructor(address[] memory adminAgents) AdminAgent(adminAgents) {
    _prevContracts = new address[](_numbersOfContracts());
  }

  modifier onlyUnfinalized() {
    require(_finalized == false, "Registrar already finalized");
    _;
  }

  modifier onlyValidContractIndex(uint256 index) {
    require(index < _numbersOfContracts(), "Invalid index");
    _;
  }

  function getEcosystemId() external pure virtual returns (bytes32) {
    return ECOSYSTEM_ID;
  }

  function getContracts() external view returns (address[] memory) {
    return _contracts;
  }

  function getContractByIndex(
    uint256 index
  ) external view onlyValidContractIndex(index) returns (address) {
    return _contracts[index];
  }

  function getPrevContractByIndex(
    uint256 index
  ) external view onlyValidContractIndex(index) returns (address) {
    return _prevContracts[index];
  }

  function setContracts(address[] calldata _addresses) external onlyAdminAgents onlyUnfinalized {
    require(_validContractsLength(_addresses.length), "Invalid number of addresses");

    // Loop through and update _prevContracts entries only if those addresses are new.
    // For example, assume _prevContracts[0] = 0xABC and contracts[i] = 0xF00
    // If _addresses[i] = 0xF00 and we didn't perform the check below, then we would overwrite the old
    // 0xABC with 0xF00, thereby losing whatever actual previous contract address that was.
    for (uint i = 0; i < _contracts.length; i++) {
      if (_addresses[i] != _contracts[i]) {
        _prevContracts[i] = _contracts[i];
      }
    }

    _contracts = _addresses;

    emit SetContracts(_addresses);
  }

  function setContractByIndex(uint8 _index, address _address) external onlyAdminAgents onlyUnfinalized {
    if (_address != _contracts[_index]) {
      _prevContracts[_index] = _contracts[_index];
    }

    _contracts[_index] = _address;

    emit SetContractByIndex(_index, _address);
  }

  function updateAllClients() external onlyAdminAgents onlyUnfinalized {
    VYToken(this.getVYToken()).setMinter();
    IRegistrarClient(this.getVETHP2P()).updateAddresses();
    IRegistrarClient(this.getVETHRevenueCycleTreasury()).updateAddresses();
    IRegistrarClient(this.getVETHReverseStakingTreasury()).updateAddresses();
    IRegistrarClient(this.getVETHYieldRateTreasury()).updateAddresses();
    IRegistrarClient(this.getVETHGovernance()).updateAddresses();
  }

  function getVYToken() external view returns (address) {
    return _contracts[uint(Contract.VYToken)];
  }

  function getVETHYieldRateTreasury() external view returns (address) {
    return _contracts[uint(Contract.VETHYieldRateTreasury)];
  }

  function getVETHP2P() external view returns (address) {
    return _contracts[uint(Contract.VETHP2P)];
  }

  function getVETHRevenueCycleTreasury() external view returns (address) {
    return _contracts[uint(Contract.VETHRevenueCycleTreasury)];
  }

  function getVETHGovernance() external view returns (address) {
    return _contracts[uint(Contract.VETHGovernance)];
  }

  function getVETHReverseStakingTreasury() external view returns (address) {
    return _contracts[uint(Contract.VETHReverseStakingTreasury)];
  }

  function finalize() external onlyAdminAgents onlyUnfinalized {
    _finalized = true;
    emit Finalize(address(this));
  }

  function isFinalized() external view returns (bool) {
    return _finalized;
  }

  function _numbersOfContracts() private pure returns (uint256) {
    return uint(Contract.VETHReverseStakingTreasury) + 1;
  }

  function _validContractsLength(uint256 contractsLength) private pure returns (bool) {
    return contractsLength == _numbersOfContracts();
  }
}