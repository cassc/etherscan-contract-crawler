//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/ISloth.sol";
import "./interfaces/ISlothItem.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/RevokableOperatorFiltererUpgradeable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";

contract Sloth is Initializable, ERC721AQueryableUpgradeable, OwnableUpgradeable, ISloth, IERC2981, RevokableOperatorFiltererUpgradeable {
  struct Equipment {
    uint256 itemId;
    address itemAddr;
  }

  string public baseURI;

  mapping(uint256 => mapping(uint256 => Equipment)) public items;
  mapping(uint256 => uint256) private _lastSetAt;

  address private _slothItemAddr;
  address private _slothMintAddr;

  event SetItem (
    uint256 indexed _tokenId,
    uint256[] _itemId,
    address[] _slothItemAddr,
    uint256 _setAt
  );

  bool private _itemAvailable;
  uint8 private constant _ITEM_NUM = 5;
  address payable private _royaltyWallet;
  uint256 public royaltyBasis;
  uint256 public disableTransferPeriod;

  function initialize() initializerERC721A initializer public {
    __ERC721A_init("Sloth", "SLT");
    __Ownable_init();
    __RevokableOperatorFilterer_init(address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6), true);

    _royaltyWallet = payable(0x452Ccc6d4a818D461e20837B417227aB70C72B56);
    royaltyBasis = 200; // 2%
    disableTransferPeriod = 1 days;
  }

  function owner() public view override(OwnableUpgradeable, RevokableOperatorFiltererUpgradeable) returns (address) {
    return super.owner();
  }

  function setItemAddr(address newItemAddr) external onlyOwner {
    _slothItemAddr = newItemAddr;
  }

  function setSlothMintAddr(address newSlothMintAddr) external onlyOwner {
    _slothMintAddr = newSlothMintAddr;
  }

  function setItemAvailable(bool newItemAvailable) external onlyOwner {
    _itemAvailable = newItemAvailable;
  }

  function setDisableTransferPeriod(uint256 newDisableTransferPeriod) external onlyOwner {
    disableTransferPeriod = newDisableTransferPeriod;
  }

  function getEquipments(uint256 tokenId) external view returns (Equipment[_ITEM_NUM] memory) {
    Equipment[_ITEM_NUM] memory equipments;
    for (uint8 i = 0; i < _ITEM_NUM; i++) {
      equipments[i] = items[uint256(ISlothItem.ItemType(i))][tokenId];
    }
    return equipments;
  }

  function setItems(uint256 tokenId, uint256[] memory itemIds) external {
    require(_itemAvailable, "item not available");
    require(_exists(tokenId), "not exist");
    require(ownerOf(tokenId) == msg.sender, "not owner");
    require(itemIds.length == _ITEM_NUM, "invalid itemIds length");

    for (uint8 i = 0; i < _ITEM_NUM; i++) {
      _setItem(tokenId, itemIds[i], ISlothItem.ItemType(i));
    }
    _lastSetAt[tokenId] = block.timestamp;

    address[] memory itemAddrs = new address[](1);
    itemAddrs[0] = _slothItemAddr;
    emit SetItem(tokenId, itemIds, itemAddrs, block.timestamp);
  }

  function _setItem(uint256 tokenId, uint256 itemId, ISlothItem.ItemType targetItemType) internal {
    ISlothItem item = ISlothItem(_slothItemAddr);
    Equipment memory equipment = items[uint256(targetItemType)][tokenId];
    if (itemId == 0) {
      if (equipment.itemId != 0 && equipment.itemAddr != address(0)) {
        item.transferFrom(address(this), msg.sender, equipment.itemId);
      }
      items[uint256(targetItemType)][tokenId] = Equipment(0, address(0));
      return;
    }

    if (items[uint256(targetItemType)][tokenId].itemId == itemId && items[uint256(targetItemType)][tokenId].itemAddr == _slothItemAddr) {
      return;
    }
    require(item.exists(itemId), "not exist");
    require(item.ownerOf(itemId) == msg.sender, "not owner");
    require(item.getItemType(itemId) == targetItemType, "invalid itemType");

    // transfer old item to sender
    if (equipment.itemId != 0 && equipment.itemAddr != address(0)) {
      item.transferFrom(address(this), msg.sender, equipment.itemId);
    }
    // receive new item to contract
    item.transferFrom(msg.sender, address(this), itemId);

    items[uint256(targetItemType)][tokenId] = Equipment(itemId, _slothItemAddr);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function mint(address sender, uint8 quantity) external {
    require(msg.sender == _slothMintAddr, "not slothMintAddr");

    _mint(sender, quantity);
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function numberMinted(address sender) external view returns (uint256) {
    return _numberMinted(sender);
  }

  function setApprovalForAll(address operator, bool approved) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
      public
      override(ERC721AUpgradeable, IERC721AUpgradeable)
      onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function supportsInterface(bytes4 interfaceId)
      public
      view
      override(ERC721AUpgradeable, IERC165, IERC721AUpgradeable)
      returns (bool)
  {
      return super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC165-royaltyInfo}.
   */
  function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    require(_exists(tokenId), "Nonexistent token");
    return (payable(_royaltyWallet), uint((salePrice * royaltyBasis)/10000));
  }

  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  function _beforeTokenTransfers(
      address from,
      address to,
      uint256 startTokenId,
      uint256 quantity
  ) internal virtual override {
    for (uint256 i = 0; i < quantity; i++) {
      uint256 tokenId = startTokenId + i;
      require(block.timestamp - _lastSetAt[tokenId] > disableTransferPeriod, "ineligible transfer");
    }
    super._beforeTokenTransfers(from, to, startTokenId, quantity);
  }
}