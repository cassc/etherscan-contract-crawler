// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { IBridgeRegistry, ValidatorSet } from "../common/IBridgeRegistry.sol";
import { Multisigable } from "../../prerequisite/Multisigable.sol";

// LightLink 2023
contract L1BridgeRegistry is Initializable, UUPSUpgradeable, ReentrancyGuard, Multisigable, IBridgeRegistry {
  using ECDSA for bytes32;
  using ValidatorSet for ValidatorSet.Record;

  // variables
  uint256 public consensusPowerThreshold;
  ValidatorSet.Record internal validators;
  address public systemVerifier;

  function initialize(address _multisig) public initializer {
    __Multisigable_init(_multisig);
    __L1BridgeRegistry_init();
  }

  /* Views */
  // verified
  function getValidators() public view returns (ValidatorSet.Validator[] memory) {
    return validators.values;
  }

  // verified
  function validValidator(address _validator) public view returns (bool) {
    return validators.contains(_validator);
  }

  // verified
  function getPower(address _validator) public view returns (uint256) {
    return validators.getPower(_validator);
  }

  function getMultisig() public view returns (address) {
    return multisig;
  }

  function getSystemVerifier() public view returns (address) {
    return systemVerifier;
  }

  /* Admin */
  // verified
  function modifyConsensusPowerThreshold(uint256 _amount) public requireMultisig {
    consensusPowerThreshold = _amount;
  }

  // verified
  function modifyValidators(address[] memory _validators, uint256[] memory _powers) public requireMultisig {
    for (uint256 i = 0; i < _validators.length; i++) {
      validators.modify(_validators[i], _powers[i]);
    }

    emit ValidatorsModifed(_validators, _powers);
  }

  // verified
  function removeValidators(address[] memory _accounts) public requireMultisig {
    for (uint256 i = 0; i < _accounts.length; i++) {
      validators.remove(_accounts[i]);
    }

    emit ValidatorsRemoved(_accounts);
  }

  // verified
  function modifySystemVerifier(address _systemVerifier) public requireMultisig {
    systemVerifier = _systemVerifier;
    emit SystemVerifierModified(_systemVerifier);
  }

  function __L1BridgeRegistry_init() internal {}

  function _authorizeUpgrade(address) internal override requireMultisig {}
}