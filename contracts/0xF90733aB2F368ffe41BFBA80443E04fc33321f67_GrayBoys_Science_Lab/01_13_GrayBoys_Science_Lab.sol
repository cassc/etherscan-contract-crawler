// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./IGrayBoys_Science_Lab.sol";

contract GrayBoys_Science_Lab is ERC1155, AccessControl {
  using Strings for uint256;

  string public baseURI;
  mapping(uint256 => bool) public validTypeIds;

  bytes32 private constant EXPERIMENT_CONTRACT_ROLE = keccak256("EXPERIMENT_CONTRACT_ROLE");
  bytes32 private constant OWNER_ROLE = keccak256("OWNER_ROLE");

  constructor() ERC1155("") {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(OWNER_ROLE, _msgSender());
  }

  /**
   * Owner Only
   */

  function mint(uint256 _typeId, uint256 _quantity) external onlyRole(OWNER_ROLE) {
    _mint(_msgSender(), _typeId, _quantity, "");
    validTypeIds[_typeId] = true;
  }

  function updateBaseURI(string memory _baseURI) external onlyRole(OWNER_ROLE) {
    baseURI = _baseURI;
  }

  /**
   * Experiment Contracts
   */

  function burnMaterialForOwnerAddress(uint256 _typeId, uint256 _quantity, address _materialOwnerAddress) external onlyRole(EXPERIMENT_CONTRACT_ROLE) {
    _burn(_materialOwnerAddress, _typeId, _quantity);
  }

  function mintMaterialToAddress(uint256 _typeId, uint256 _quantity, address _toAddress) external onlyRole(EXPERIMENT_CONTRACT_ROLE) {
    _mint(_toAddress, _typeId, _quantity, "");
    validTypeIds[_typeId] = true;
  }

  /**
   * Public
   */

  function bulkSafeTransfer(uint256 _typeId, uint256 _quantityPerRecipient, address[] calldata recipients) external {
    for (uint256 i = 0; i < recipients.length; i++) {
      safeTransferFrom(_msgSender(), recipients[i], _typeId, _quantityPerRecipient, "");
    }
  }

  function uri(uint256 typeId) public view override returns (string memory) {
    require(validTypeIds[typeId], "URI request for invalid material type");

    return string(abi.encodePacked(baseURI, typeId.toString()));
  }

  /**
   * Overrides
   */

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
    return interfaceId == type(IGrayBoys_Science_Lab).interfaceId || super.supportsInterface(interfaceId);
  }
}