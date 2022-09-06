// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IQuorum.sol";

interface IWeightedValidator is IQuorum {
  struct WeightedValidator {
    address validator;
    address governor;
    uint256 weight;
  }

  /// @dev Emitted when the validators are added
  event ValidatorsAdded(uint256 indexed nonce, WeightedValidator[] validators);
  /// @dev Emitted when the validators are updated
  event ValidatorsUpdated(uint256 indexed nonce, WeightedValidator[] validators);
  /// @dev Emitted when the validators are removed
  event ValidatorsRemoved(uint256 indexed nonce, address[] validators);

  /**
   * @dev Returns validator weight of the validator.
   */
  function getValidatorWeight(address _addr) external view returns (uint256);

  /**
   * @dev Returns governor weight of the governor.
   */
  function getGovernorWeight(address _addr) external view returns (uint256);

  /**
   * @dev Returns total validator weights of the address list.
   */
  function sumValidatorWeights(address[] calldata _addrList) external view returns (uint256 _weight);

  /**
   * @dev Returns total governor weights of the address list.
   */
  function sumGovernorWeights(address[] calldata _addrList) external view returns (uint256 _weight);

  /**
   * @dev Returns the validator list attached with governor address and weight.
   */
  function getValidatorInfo() external view returns (WeightedValidator[] memory _list);

  /**
   * @dev Returns the validator list.
   */
  function getValidators() external view returns (address[] memory _validators);

  /**
   * @dev Returns the validator at `_index` position.
   */
  function validators(uint256 _index) external view returns (WeightedValidator memory);

  /**
   * @dev Returns total of validators.
   */
  function totalValidators() external view returns (uint256);

  /**
   * @dev Returns total weights.
   */
  function totalWeights() external view returns (uint256);

  /**
   * @dev Adds validators.
   *
   * Requirements:
   * - The weights are larger than 0.
   * - The validators are not added.
   * - The method caller is admin.
   *
   * Emits the `ValidatorsAdded` event.
   *
   */
  function addValidators(WeightedValidator[] calldata _validators) external;

  /**
   * @dev Updates validators.
   *
   * Requirements:
   * - The weights are larger than 0.
   * - The validators are added.
   * - The method caller is admin.
   *
   * Emits the `ValidatorsUpdated` event.
   *
   */
  function updateValidators(WeightedValidator[] calldata _validators) external;

  /**
   * @dev Removes validators.
   *
   * Requirements:
   * - The validators are added.
   * - The method caller is admin.
   *
   * Emits the `ValidatorsRemoved` event.
   *
   */
  function removeValidators(address[] calldata _validators) external;
}