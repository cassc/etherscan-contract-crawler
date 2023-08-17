// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "../../libs/ValidatorSet.sol";

// LightLink 2023
interface IBridgeRegistry {
  event ConsensusPowerThresholdModified(uint256 _amount);
  event ValidatorsModifed(address[] _accounts, uint256[] _powers);
  event ValidatorsRemoved(address[] _accounts);
  event MutisigModified(address _multisig);
  event SystemVerifierModified(address _systemVerifier);

  /* Views */
  function consensusPowerThreshold() external view returns (uint256);

  function validValidator(address) external view returns (bool);

  function getPower(address) external view returns (uint256);

  function getValidators() external view returns (ValidatorSet.Validator[] memory);

  function getMultisig() external view returns (address);

  function getSystemVerifier() external view returns (address);

  /* Actions */
  function modifyConsensusPowerThreshold(uint256 _amount) external;

  function modifyValidators(address[] memory _accounts, uint256[] memory _powers) external;

  function removeValidators(address[] memory _accounts) external;

  function modifySystemVerifier(address _systemVerifier) external;
}