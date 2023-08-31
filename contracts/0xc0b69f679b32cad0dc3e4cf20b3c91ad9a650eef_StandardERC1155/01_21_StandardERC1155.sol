// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC4906.sol";

contract StandardERC1155 is ERC1155, Pausable, AccessControl, ERC2981, IERC4906, Ownable, ERC1155Supply {
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  mapping(uint256 => uint256) public preset;

  constructor(
    string memory uri_
  ) ERC1155(uri_) {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(PAUSER_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
  }

  /**
   * @notice Set up preset for limit token supply
   * @param ids: token ids
   * @param amounts: amount for each token
   */
  function setupPreset(uint256[] calldata ids, uint256[] calldata amounts)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    for (uint256 i = 0; i < ids.length; i++) {
      preset[ids[i]] = amounts[i];
    }
  }

  function setURI(string memory newuri) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _setURI(newuri);
  }

  function pause() public onlyRole(PAUSER_ROLE) {
    _pause();
  }

  function unpause() public onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  function mint(
    address account,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public onlyRole(MINTER_ROLE) {
    require(preset[id]==0 || totalSupply(id) + amount <= preset[id], "exceed preset");
    _mint(account, id, amount, data);
  }

  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public onlyRole(MINTER_ROLE) {
    for (uint256 i = 0; i < ids.length; i++) {
      require(preset[ids[i]]==0 || totalSupply(ids[i]) + amounts[i] <= preset[ids[i]], "exceed preset");
    }
    _mintBatch(to, ids, amounts, data);
  }

  /**
   * @notice Callback limit: not multiHolders could only hold one gen
   */
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override(ERC1155, ERC1155Supply) whenNotPaused {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view override(ERC1155, ERC2981, AccessControl, IERC165) returns (bool) {
    return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
  }

  /**
   * @dev External onlyOwner version of {ERC2981-_setDefaultRoyalty}.
   */
  function setDefaultRoyalty(
    address receiver,
    uint96 feeNumerator
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  /**
   * @dev External onlyOwner version of {ERC2981-_deleteDefaultRoyalty}.
   */
  function deleteDefaultRoyalty() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _deleteDefaultRoyalty();
  }

  /**
   * @dev External onlyOwner version of {ERC2981-_setTokenRoyalty}.
   */
  function setTokenRoyalty(
    uint256 tokenId,
    address receiver,
    uint96 feeNumerator
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setTokenRoyalty(tokenId, receiver, feeNumerator);
  }

  /**
   * @dev External onlyOwner version of {ERC2981-_resetTokenRoyalty}.
   */
  function resetTokenRoyalty(uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _resetTokenRoyalty(tokenId);
  }

  function emitMetadataUpdate(uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
    // Emit an event with the update.
    emit MetadataUpdate(tokenId);
  }

  function emitBatchMetadataUpdate(
    uint256 fromTokenId,
    uint256 toTokenId
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    // Emit an event with the update.
    emit BatchMetadataUpdate(fromTokenId, toTokenId);
  }
}