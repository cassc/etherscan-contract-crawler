// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import './abstract/JBControllerUtility.sol';
import './interfaces/IJBFundAccessConstraintsStore.sol';

/**
  @notice
  Information pertaining to how much funds can be accessed by a project from each payment terminal.
  
  @dev
  Adheres to -
  IJBFundAccessConstraintsStore: General interface for the generic controller methods in this contract that interacts with funding cycles and tokens according to the protocol's rules.

  @dev
  Inherits from -
  JBControllerUtility: Several functions in this contract can only be accessed by a project owner, or an address that has been preconfifigured to be an operator of the project.
  ERC165: Introspection on interface adherance. 
*/
contract JBFundAccessConstraintsStore is
  JBControllerUtility,
  ERC165,
  IJBFundAccessConstraintsStore
{
  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//

  error INVALID_DISTRIBUTION_LIMIT();
  error INVALID_DISTRIBUTION_LIMIT_CURRENCY();
  error INVALID_OVERFLOW_ALLOWANCE();
  error INVALID_OVERFLOW_ALLOWANCE_CURRENCY();

  //*********************************************************************//
  // --------------------- internal stored properties ------------------ //
  //*********************************************************************//

  /**
    @notice
    Data regarding the distribution limit of a project during a configuration.

    @dev
    bits 0-231: The amount of token that a project can distribute per funding cycle.

    @dev
    bits 232-255: The currency of amount that a project can distribute.

    _projectId The ID of the project to get the packed distribution limit data of.
    _configuration The configuration during which the packed distribution limit data applies.
    _terminal The terminal from which distributions are being limited.
    _token The token for which distributions are being limited.
  */
  mapping(uint256 => mapping(uint256 => mapping(IJBPaymentTerminal => mapping(address => uint256))))
    internal _packedDistributionLimitDataOf;

  /**
    @notice
    Data regarding the overflow allowance of a project during a configuration.

    @dev
    bits 0-231: The amount of overflow that a project is allowed to tap into on-demand throughout the configuration.

    @dev
    bits 232-255: The currency of the amount of overflow that a project is allowed to tap.

    _projectId The ID of the project to get the packed overflow allowance data of.
    _configuration The configuration during which the packed overflow allowance data applies.
    _terminal The terminal managing the overflow.
    _token The token for which overflow is being allowed.
  */
  mapping(uint256 => mapping(uint256 => mapping(IJBPaymentTerminal => mapping(address => uint256))))
    internal _packedOverflowAllowanceDataOf;

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /**
    @notice
    The amount of token that a project can distribute per funding cycle, and the currency it's in terms of.

    @dev
    The number of decimals in the returned fixed point amount is the same as that of the specified terminal. 

    @param _projectId The ID of the project to get the distribution limit of.
    @param _configuration The configuration during which the distribution limit applies.
    @param _terminal The terminal from which distributions are being limited.
    @param _token The token for which the distribution limit applies.

    @return The distribution limit, as a fixed point number with the same number of decimals as the provided terminal.
    @return The currency of the distribution limit.
  */
  function distributionLimitOf(
    uint256 _projectId,
    uint256 _configuration,
    IJBPaymentTerminal _terminal,
    address _token
  ) external view override returns (uint256, uint256) {
    // Get a reference to the packed data.
    uint256 _data = _packedDistributionLimitDataOf[_projectId][_configuration][_terminal][_token];

    // The limit is in bits 0-231. The currency is in bits 232-255.
    return (uint256(uint232(_data)), _data >> 232);
  }

  /**
    @notice
    The amount of overflow that a project is allowed to tap into on-demand throughout a configuration, and the currency it's in terms of.

    @dev
    The number of decimals in the returned fixed point amount is the same as that of the specified terminal. 

    @param _projectId The ID of the project to get the overflow allowance of.
    @param _configuration The configuration of the during which the allowance applies.
    @param _terminal The terminal managing the overflow.
    @param _token The token for which the overflow allowance applies.

    @return The overflow allowance, as a fixed point number with the same number of decimals as the provided terminal.
    @return The currency of the overflow allowance.
  */
  function overflowAllowanceOf(
    uint256 _projectId,
    uint256 _configuration,
    IJBPaymentTerminal _terminal,
    address _token
  ) external view override returns (uint256, uint256) {
    // Get a reference to the packed data.
    uint256 _data = _packedOverflowAllowanceDataOf[_projectId][_configuration][_terminal][_token];

    // The allowance is in bits 0-231. The currency is in bits 232-255.
    return (uint256(uint232(_data)), _data >> 232);
  }

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /** 
    @param _directory A contract storing directories of terminals and controllers for each project.
  */
  // solhint-disable-next-line no-empty-blocks
  constructor(IJBDirectory _directory) JBControllerUtility(_directory) {}

  //*********************************************************************//
  // --------------------- external transactions ----------------------- //
  //*********************************************************************//

  /**
    @notice
    Sets a project's constraints for accessing treasury funds.

    @dev
    Only a project's current controller can set its fund access constraints.

    @param _projectId The ID of the project whose fund access constraints are being set.
    @param _configuration The funding cycle configuration the constraints apply within.
    @param _fundAccessConstraints An array containing amounts that a project can use from its treasury for each payment terminal. Amounts are fixed point numbers using the same number of decimals as the accompanying terminal. The `_distributionLimit` and `_overflowAllowance` parameters must fit in a `uint232`.
  */
  function setFor(
    uint256 _projectId,
    uint256 _configuration,
    JBFundAccessConstraints[] calldata _fundAccessConstraints
  ) external override onlyController(_projectId) {
    // Save the number of constraints.
    uint256 _numberOfFundAccessConstraints = _fundAccessConstraints.length;

    // Set distribution limits if there are any.
    for (uint256 _i; _i < _numberOfFundAccessConstraints; ) {
      // If distribution limit value is larger than 232 bits, revert.
      if (_fundAccessConstraints[_i].distributionLimit > type(uint232).max) revert INVALID_DISTRIBUTION_LIMIT();

      // If distribution limit currency value is larger than 24 bits, revert.
      if (_fundAccessConstraints[_i].distributionLimitCurrency > type(uint24).max)
        revert INVALID_DISTRIBUTION_LIMIT_CURRENCY();

      // If overflow allowance value is larger than 232 bits, revert.
      if (_fundAccessConstraints[_i].overflowAllowance > type(uint232).max) revert INVALID_OVERFLOW_ALLOWANCE();

      // If overflow allowance currency value is larger than 24 bits, revert.
      if (_fundAccessConstraints[_i].overflowAllowanceCurrency > type(uint24).max)
        revert INVALID_OVERFLOW_ALLOWANCE_CURRENCY();

      // Set the distribution limit if there is one.
      if (_fundAccessConstraints[_i].distributionLimit > 0)
        _packedDistributionLimitDataOf[_projectId][_configuration][_fundAccessConstraints[_i].terminal][
          _fundAccessConstraints[_i].token
        ] = _fundAccessConstraints[_i].distributionLimit | (_fundAccessConstraints[_i].distributionLimitCurrency << 232);

      // Set the overflow allowance if there is one.
      if (_fundAccessConstraints[_i].overflowAllowance > 0)
        _packedOverflowAllowanceDataOf[_projectId][_configuration][_fundAccessConstraints[_i].terminal][
          _fundAccessConstraints[_i].token
        ] = _fundAccessConstraints[_i].overflowAllowance | (_fundAccessConstraints[_i].overflowAllowanceCurrency << 232);

      emit SetFundAccessConstraints(_configuration, _projectId, _fundAccessConstraints[_i], msg.sender);

      unchecked {
        ++_i;
      }
    }
  }
}