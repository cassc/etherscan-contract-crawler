// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import './openzepplin/ERC1155Upgradeable.sol';
import './openzepplin/ERC1155SupplyUpgradeable.sol';
import './HYDNSealStorage.sol';

//

contract HYDNSeal is
  Initializable,
  ContextUpgradeable,
  UUPSUpgradeable,
  OwnableUpgradeable,
  HYDNERC1155Upgradeable,
  HYDNERC1155SupplyUpgradeable,
  HYDNSealStorage
{
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(string memory _baseURI) external initializer {
    __Context_init();
    __UUPSUpgradeable_init();
    __Ownable_init();
    __ERC1155_init(_baseURI);
    __ERC1155Supply_init();
    currentAuditId = block.chainid * 10_000_000;
    name = 'HYDN Seal';
    // solhint-disable-next-line prettier/prettier
    // prettier-ignore
    symbol = unicode"⛑";
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
    newImplementation; // avoid empty block
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override(HYDNERC1155SupplyUpgradeable, HYDNERC1155Upgradeable) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  function safeTransferFrom(
    address,
    address,
    uint256,
    uint256,
    bytes memory
  ) public override {
    revert('HYDNSeal: transfer not allowed');
  }

  function safeBatchTransferFrom(
    address,
    address,
    uint256[] memory,
    uint256[] memory,
    bytes memory
  ) public override {
    revert('HYDNSeal: transfer batch not allowed');
  }

  function uri(uint256 _tokenId) public view override returns (string memory) {
    require(exists(_tokenId), 'HYDNSeal: token not existing');
    return string(abi.encodePacked(super.uri(_tokenId), StringsUpgradeable.toString(_tokenId)));
  }

  function totalSupply() public view returns (uint256) {
    return currentAuditId - block.chainid * 10_000_000;
  }

  function mintSeal(address[] calldata _contracts) external onlyOwner returns (bool success) {
    currentAuditId += 1;
    uint256 id = currentAuditId;
    for (uint256 i = 0; i < _contracts.length; i++) {
      require(AddressUpgradeable.isContract(_contracts[i]), 'HYDNSeal: receiver is not a contract');
      _mint(_contracts[i], id, 1, '');
    }
    return true;
  }
}