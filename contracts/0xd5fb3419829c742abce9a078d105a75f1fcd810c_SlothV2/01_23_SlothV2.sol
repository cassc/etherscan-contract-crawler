//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/ISloth.sol";
import "./interfaces/ISlothItem.sol";
import "./interfaces/IEquipment.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/RevokableOperatorFiltererUpgradeable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import "./interfaces/ISlothEquipment.sol";

contract SlothV2 is Initializable, ERC721AQueryableUpgradeable, OwnableUpgradeable, ISloth, IERC2981, RevokableOperatorFiltererUpgradeable {
  string public baseURI;

  mapping(uint256 => mapping(uint256 => IEquipment.Equipment)) public items;
  mapping(uint256 => uint256) private _lastSetAt;

  address private _slothItemAddr;
  address private _slothMintAddr;

  event SetItem (
    uint256 indexed _tokenId,
    uint256[] _itemIds,
    IItemType.ItemMintType[] _itemMintType,
    address[] _slothItemAddr,
    uint256 _setAt
  );

  bool private _itemAvailable;
  uint8 private constant _ITEM_NUM = 5;
  address payable private _royaltyWallet;
  uint256 public royaltyBasis;
  uint256 public disableTransferPeriod;
  address private _slothEquipmentAddr;

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

  function setSlothEquipmentAddr(address newSlothEquipmentAddr) external onlyOwner {
    _slothEquipmentAddr = newSlothEquipmentAddr;
  }

  function setItemAvailable(bool newItemAvailable) external onlyOwner {
    _itemAvailable = newItemAvailable;
  }

  function setDisableTransferPeriod(uint256 newDisableTransferPeriod) external onlyOwner {
    disableTransferPeriod = newDisableTransferPeriod;
  }

  function getEquipments(uint256 tokenId) public view returns (IEquipment.Equipment[_ITEM_NUM] memory) {
    IEquipment.Equipment[_ITEM_NUM] memory equipments;
    for (uint8 i = 0; i < _ITEM_NUM; i++) {
      equipments[i] = items[uint256(ISlothItem.ItemType(i))][tokenId];
    }
    return equipments;
  }

  function setEquipments(uint256 _tokenId, uint256[] calldata _itemTokenIds, address[] calldata _itemContractAddress, IItemType.ItemMintType[] calldata _itemMintTypes) external {
    require(msg.sender == _slothEquipmentAddr, "forbidden"); 
    for (uint8 i = 0; i < _ITEM_NUM; i++) {
      items[uint256(ISlothItem.ItemType(i))][_tokenId] = IEquipment.Equipment(_itemTokenIds[i], _itemContractAddress[i]);
    }
    emit SetItem(_tokenId, _itemTokenIds, _itemMintTypes, _itemContractAddress, block.timestamp);
  }

  function setItems(uint256 tokenId, IEquipment.EquipmentTargetItem[] memory _targetItems) external {
    require(_itemAvailable, "item not available");
    require(_exists(tokenId), "not exist");
    require(ownerOf(tokenId) == msg.sender, "not owner");
    require(_targetItems.length == _ITEM_NUM, "invalid itemIds length");

    ISlothEquipment slothEquipment = ISlothEquipment(_slothEquipmentAddr);
    IEquipment.Equipment[_ITEM_NUM] memory _equipments = getEquipments(tokenId);
    uint256[] memory _equipmentItemIds = new uint256[](_ITEM_NUM);
    for (uint8 i = 0; i < _ITEM_NUM; i++) {
      _equipmentItemIds[i] = _equipments[i].itemId;
    }
    slothEquipment.validateSetItems(_equipmentItemIds, _targetItems, msg.sender);

    address[] memory itemAddrs = new address[](5);
    uint256[] memory _itemIds = new uint256[](5);
    IItemType.ItemMintType[] memory _itemMintTypes = new IItemType.ItemMintType[](5);
    for (uint8 i = 0; i < _ITEM_NUM; i++) {
      itemAddrs[i] = _setItem(tokenId, _targetItems[i], ISlothItem.ItemType(i));
      _itemIds[i] = _targetItems[i].itemTokenId;
      _itemMintTypes[i] = _targetItems[i].itemMintType;
    }
    _lastSetAt[tokenId] = block.timestamp;
    emit SetItem(tokenId, _itemIds, _itemMintTypes, itemAddrs, block.timestamp);
  }

  function _setItem(uint256 _tokenId, IEquipment.EquipmentTargetItem memory _targetItem, ISlothItem.ItemType _targetItemType) internal returns (address) {
    ISlothEquipment slothEquipment = ISlothEquipment(_slothEquipmentAddr);
    address itemContractAddr = slothEquipment.getTargetItemContractAddress(_targetItem.itemMintType);
    IEquipment.Equipment memory _equipment = items[uint256(_targetItemType)][_tokenId];

    if (_targetItem.itemTokenId == 0) {
      if (_equipment.itemId != 0 && _equipment.itemAddr != address(0)) {
        ISlothItem(_equipment.itemAddr).transferFrom(address(this), msg.sender, _equipment.itemId);
      }
      items[uint256(_targetItemType)][_tokenId] = IEquipment.Equipment(0, address(0));
      return address(0);
    }

    if (_equipment.itemId == _targetItem.itemTokenId && _equipment.itemAddr == itemContractAddr) {
      return itemContractAddr;
    }

    // transfer old item to sender
    if (_equipment.itemId != 0 && _equipment.itemAddr != address(0)) {
      ISlothItem(_equipment.itemAddr).transferFrom(address(this), msg.sender, _equipment.itemId);
    }
    // receive new item to contract
    ISlothItem(itemContractAddr).transferFrom(msg.sender, address(this), _targetItem.itemTokenId);
    items[uint256(_targetItemType)][_tokenId] = IEquipment.Equipment(_targetItem.itemTokenId, itemContractAddr);
    return itemContractAddr;
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