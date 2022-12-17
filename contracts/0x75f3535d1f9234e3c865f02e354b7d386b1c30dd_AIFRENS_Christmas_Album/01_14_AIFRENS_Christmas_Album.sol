// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./IAIFRENS_Christmas_Album.sol";

contract AIFRENS_Christmas_Album is ERC1155, AccessControl {
  using Strings for uint256;

  string public baseURI;
  mapping(uint256 => bool) public validTypeIds;

  bytes32 private constant AUTHORITY_CONTRACT_ROLE = keccak256("AUTHORITY_CONTRACT_ROLE");
  bytes32 private constant OWNER_ROLE = keccak256("OWNER_ROLE");

  constructor() ERC1155("") {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(OWNER_ROLE, _msgSender());
  }

  function mint(uint256 _typeId, uint256 _quantity) external onlyRole(OWNER_ROLE) {
    _mint(_msgSender(), _typeId, _quantity, "");
    validTypeIds[_typeId] = true;
  }

  function burnTypeBulk(uint256 _typeId, address[] calldata owners) external onlyRole(OWNER_ROLE) {
    for (uint256 i = 0; i < owners.length; i++) {
      uint256 amount = balanceOf(owners[i], _typeId);
      _burn(owners[i], _typeId, amount);
    }
  }

  function updateBaseURI(string memory _baseURI) external onlyRole(OWNER_ROLE) {
    baseURI = _baseURI;
  }

  function burnTypeForOwnerAddress(uint256 _typeId, uint256 _quantity, address _typeOwnerAddress) external onlyRole(AUTHORITY_CONTRACT_ROLE) returns (bool) {
    _burn(_typeOwnerAddress, _typeId, _quantity);

    return true;
  }

  function mintTypeToAddress(uint256 _typeId, uint256 _quantity, address _toAddress) external onlyRole(AUTHORITY_CONTRACT_ROLE) returns (bool) {
    _mint(_toAddress, _typeId, _quantity, "");
    validTypeIds[_typeId] = true;

    return true;
  }

  function bulkSafeTransfer(uint256 _typeId, uint256 _quantityPerRecipient, address[] calldata recipients) external {
    for (uint256 i = 0; i < recipients.length; i++) {
      safeTransferFrom(_msgSender(), recipients[i], _typeId, _quantityPerRecipient, "");
    }
  }

  function uri(uint256 typeId) public view override returns (string memory) {
    require(validTypeIds[typeId], "URI request for invalid type");

    return string(abi.encodePacked(baseURI, typeId.toString()));
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
    return interfaceId == type(IAIFRENS_Christmas_Album).interfaceId || super.supportsInterface(interfaceId);
  }
}