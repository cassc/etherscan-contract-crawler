// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../access/AdminAgent.sol";
import "../access/AdminGovernanceAgent.sol";
import "../governance/Governable.sol";
import "./Treasury.sol";
import "../MFCCollateralLoan.sol";
import "../RegistrarClient.sol";
import "../lib/token/BEP20/IBEP20.sol";

contract BUSDT is Treasury, AdminGovernanceAgent, Governable, RegistrarClient {

  address private _migration;
  address private _mfcExchangeFloor;
  MFCCollateralLoan private _mfcCollateralLoan;

  event CollateralTransfer(address recipient, uint256 amount);
  event FloorTransfer(address recipient, uint256 amount);

  constructor(
    address registrarAddress_,
    address busdAddress_,
    address[] memory adminGovAgents
  ) AdminGovernanceAgent(adminGovAgents)
    Treasury(busdAddress_)
    RegistrarClient(registrarAddress_) {
  }

  modifier onlyCollateralLoan() {
    require(address(_mfcCollateralLoan) == _msgSender(), "Unauthorized");
    _;
  }

  modifier onlyExchangeFloor() {
    require(_mfcExchangeFloor == _msgSender(), "Unauthorized");
    _;
  }

  function getBusdtValue() public view returns (uint256) {
    uint256 busdTreasuryBalance = getTreasuryToken().balanceOf(address(this));
    uint256 busdTotalLoanValue = _mfcCollateralLoan.getTotalLoanValue();
    return busdTreasuryBalance + busdTotalLoanValue;
  }

  function getMigration() external view returns (address) {
    return _migration;
  }

  function setMigration(address destination) external onlyGovernance {
    _migration = destination;
  }

  function transferMigration(uint256 amount) external onlyAdminGovAgents {
    require(_migration != address(0), "Migration not set");
    _transfer(_migration, amount);
  }

  function collateralTransfer(address recipient, uint256 amount) external onlyCollateralLoan {
    _transfer(recipient, amount);
    emit CollateralTransfer(recipient, amount);
  }

  function floorTransfer(address recipient, uint256 amount) external onlyExchangeFloor {
    _transfer(recipient, amount);
    emit FloorTransfer(recipient, amount);
  }

  function updateAddresses() public override onlyRegistrar {
    _mfcCollateralLoan = MFCCollateralLoan(_registrar.getMFCCollateralLoan());
    _mfcExchangeFloor = _registrar.getMFCExchangeFloor();
    _updateGovernable(_registrar);
  }

  function _transfer(address recipient, uint256 amount) internal {
    require(getTreasuryToken().balanceOf(address(this)) >= amount, "Insufficient balance");
    getTreasuryToken().transfer(recipient, amount);
  }
}