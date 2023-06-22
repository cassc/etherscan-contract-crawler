// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import '../../abstract/JBOperatable.sol';
import '../../interfaces/IJBDirectory.sol';
import '../../libraries/JBOperations.sol';

import '../structs.sol';
import './components/BaseNFT.sol';
import './interfaces/IMintFeeOracle.sol';

/**
 * @notice ERC721
 */
contract NFToken is BaseNFT, JBOperatable {
  IJBDirectory public immutable jbxDirectory;
  IERC721 public immutable jbxProjects;

  IMintFeeOracle public immutable feeOracle;

  uint256 public projectId;

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /**
   * @notice Creates the NFT contract.
   *
   */
  constructor(
    CommonNFTAttributes memory _commonNFTAttributes,
    PermissionValidationComponents memory _permissionValidationComponents,
    IMintFeeOracle _feeOracle
  ) {
    name = _commonNFTAttributes.name;
    symbol = _commonNFTAttributes.symbol;

    baseUri = _commonNFTAttributes.baseUri;
    isRevealed = _commonNFTAttributes.revealed;
    contractUri = _commonNFTAttributes.contractUri;
    maxSupply = _commonNFTAttributes.maxSupply;
    unitPrice = _commonNFTAttributes.unitPrice;
    mintAllowance = _commonNFTAttributes.mintAllowance;

    payoutReceiver = payable(msg.sender);
    royaltyReceiver = payable(msg.sender);

    operatorStore = _permissionValidationComponents.jbxOperatorStore; // JBOperatable

    jbxDirectory = _permissionValidationComponents.jbxDirectory;
    jbxProjects = _permissionValidationComponents.jbxProjects;

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
    _grantRole(REVEALER_ROLE, msg.sender);

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