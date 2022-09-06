// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "../interfaces/IQuorum.sol";
import "../interfaces/IWeightedValidator.sol";
import "./HasProxyAdmin.sol";

abstract contract GatewayV2 is HasProxyAdmin, Pausable, IQuorum {
  /// @dev Emitted when the validator contract address is updated.
  event ValidatorContractUpdated(IWeightedValidator);

  uint256 internal _num;
  uint256 internal _denom;

  IWeightedValidator public validatorContract;
  uint256 public nonce;

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   */
  uint256[50] private ______gap;

  /**
   * @dev See {IQuorum-getThreshold}.
   */
  function getThreshold() external view virtual returns (uint256, uint256) {
    return (_num, _denom);
  }

  /**
   * @dev See {IQuorum-checkThreshold}.
   */
  function checkThreshold(uint256 _voteWeight) external view virtual returns (bool) {
    return _voteWeight * _denom >= _num * validatorContract.totalWeights();
  }

  /**
   * @dev See {IQuorum-setThreshold}.
   */
  function setThreshold(uint256 _numerator, uint256 _denominator)
    external
    virtual
    onlyAdmin
    returns (uint256, uint256)
  {
    return _setThreshold(_numerator, _denominator);
  }

  /**
   * @dev Triggers paused state.
   */
  function pause() external onlyAdmin {
    _pause();
  }

  /**
   * @dev Triggers unpaused state.
   */
  function unpause() external onlyAdmin {
    _unpause();
  }

  /**
   * @dev Sets validator contract address.
   *
   * Requirements:
   * - The method caller is admin.
   *
   * Emits the `ValidatorContractUpdated` event.
   *
   */
  function setValidatorContract(IWeightedValidator _validatorContract) external virtual onlyAdmin {
    _setValidatorContract(_validatorContract);
  }

  /**
   * @dev See {IQuorum-minimumVoteWeight}.
   */
  function minimumVoteWeight() public view virtual returns (uint256) {
    return _minimumVoteWeight(validatorContract.totalWeights());
  }

  /**
   * @dev Sets validator contract address.
   *
   * Emits the `ValidatorContractUpdated` event.
   *
   */
  function _setValidatorContract(IWeightedValidator _validatorContract) internal virtual {
    validatorContract = _validatorContract;
    emit ValidatorContractUpdated(_validatorContract);
  }

  /**
   * @dev Sets threshold and returns the old one.
   *
   * Emits the `ThresholdUpdated` event.
   *
   */
  function _setThreshold(uint256 _numerator, uint256 _denominator)
    internal
    virtual
    returns (uint256 _previousNum, uint256 _previousDenom)
  {
    require(_numerator <= _denominator, "GatewayV2: invalid threshold");
    _previousNum = _num;
    _previousDenom = _denom;
    _num = _numerator;
    _denom = _denominator;
    emit ThresholdUpdated(nonce++, _numerator, _denominator, _previousNum, _previousDenom);
  }

  /**
   * @dev Returns minimum vote weight.
   */
  function _minimumVoteWeight(uint256 _totalWeight) internal view virtual returns (uint256) {
    return (_num * _totalWeight + _denom - 1) / _denom;
  }
}