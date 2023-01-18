// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '../interfaces/IGMTransferController.sol';
import '../errors/GMTransferControllerErrors.sol';
import '../structs/GMTransferControllerStructs.sol';

abstract contract GMTransferController is Initializable, AccessControlUpgradeable, IGMTransferController {
  bytes32 public constant DEFAULT_BYPASS_ROLE = keccak256('DEFAULT_BYPASS_ROLE');
  mapping(address => mapping(uint256 => TransferStatus)) internal _transferStatusByCollectionAndTokenId;

  function __GMTransferController_init(address admin, address bypassAdmin) internal onlyInitializing {
    __AccessControl_init();
    _grantRole(DEFAULT_ADMIN_ROLE, admin);
    _grantRole(DEFAULT_BYPASS_ROLE, bypassAdmin);
  }

  function canTokenBeTransferred(
    address collection,
    address,
    address,
    uint256 tokenId
  ) external view virtual returns (bool) {
    TransferStatus storage transferStatus = _transferStatusByCollectionAndTokenId[collection][tokenId];
    return transferStatus.isBlocked ? transferStatus.isBypassed : true;
  }

  function bypassTokenId(address collection, uint256 tokenId) external virtual override onlyRole(DEFAULT_BYPASS_ROLE) {
    _transferStatusByCollectionAndTokenId[collection][tokenId].isBypassed = true;
  }

  function removeBypassTokenId(address collection, uint256 tokenId)
    external
    virtual
    override
    onlyRole(DEFAULT_BYPASS_ROLE)
  {
    _transferStatusByCollectionAndTokenId[collection][tokenId].isBypassed = false;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IERC165, AccessControlUpgradeable)
    returns (bool)
  {
    return interfaceId == type(IGMTransferController).interfaceId || super.supportsInterface(interfaceId);
  }

  function _blockTokenId(address collection, uint256 tokenId) internal virtual {
    _transferStatusByCollectionAndTokenId[collection][tokenId].isBlocked = true;
  }

  function _unBlockTokenId(address collection, uint256 tokenId) internal virtual {
    _transferStatusByCollectionAndTokenId[collection][tokenId].isBlocked = false;
  }
}