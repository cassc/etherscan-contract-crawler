// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import '../../abstract/JBOperatable.sol';
import '../../interfaces/IJBDirectory.sol';
import '../../libraries/JBOperations.sol';

import '../structs.sol';
import './components/BaseNFT.sol';
import './interfaces/IMintFeeOracle.sol';

contract NFUToken is BaseNFT, JBOperatable {
  error INVALID_OPERATION();

  IJBDirectory public jbxDirectory;
  IERC721 public jbxProjects;

  IMintFeeOracle public feeOracle;

  uint256 public projectId;

  //*********************************************************************//
  // -------------------------- initializer ---------------------------- //
  //*********************************************************************//

  /**
   * @dev This contract is meant to be deployed via the `Deployer` which makes `Clone`s. The `Deployer` itself has a reference to a known-good copy. When the platform admin is deploying the `Deployer` and the source `NFUToken` the constructor will lock that contract to the platform admin. When the deployer is making copies of it the source storage isn't taken so the Deployer will call `initialize` to set the admin to the correct account.
   */
  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
    _grantRole(REVEALER_ROLE, msg.sender);
  }

  /**
   * @notice Initializes token state. Used by the Deployer contract to set NFT parameters and contract ownership.
   *
   * @param _owner Token admin.
   */
  function initialize(
    address payable _owner,
    CommonNFTAttributes memory _commonNFTAttributes,
    PermissionValidationComponents memory _permissionValidationComponents,
    IMintFeeOracle _feeOracle
  ) public {
    if (bytes(name).length != 0) {
      // NOTE: prevent re-init
      revert INVALID_OPERATION();
    }

    if (getRoleMemberCount(DEFAULT_ADMIN_ROLE) != 0) {
      if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
        revert INVALID_OPERATION();
      }
    } else {
      _grantRole(DEFAULT_ADMIN_ROLE, _owner);
      _grantRole(MINTER_ROLE, _owner);
      _grantRole(REVEALER_ROLE, _owner);
    }

    name = _commonNFTAttributes.name;
    symbol = _commonNFTAttributes.symbol;

    baseUri = _commonNFTAttributes.baseUri;
    isRevealed = _commonNFTAttributes.revealed;
    contractUri = _commonNFTAttributes.contractUri;
    maxSupply = _commonNFTAttributes.maxSupply;
    unitPrice = _commonNFTAttributes.unitPrice;
    mintAllowance = _commonNFTAttributes.mintAllowance;

    payoutReceiver = _owner;
    royaltyReceiver = _owner;

    operatorStore = _permissionValidationComponents.jbxOperatorStore; // JBOperatable

    jbxDirectory = _permissionValidationComponents.jbxDirectory;
    jbxProjects = _permissionValidationComponents.jbxProjects;

    feeOracle = _feeOracle;
  }

  function setProjectId(
    uint256 _projectId
  )
    external
    requirePermissionAllowingOverride(
      jbxProjects.ownerOf(_projectId),
      _projectId,
      JBOperations.MANAGE_PAYMENTS,
      (msg.sender == address(jbxDirectory.controllerOf(_projectId)))
    )
  {
    projectId = _projectId;
  }

  function feeExtras(uint256 expectedPrice) internal view override returns (uint256 fee) {
    if (address(0) == address(feeOracle)) {
      fee = 0;
    } else {
      fee = feeOracle.fee(projectId, expectedPrice);
    }
  }
}