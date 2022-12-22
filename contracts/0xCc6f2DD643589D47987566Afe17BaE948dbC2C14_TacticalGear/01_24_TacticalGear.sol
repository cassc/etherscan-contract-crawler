// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import 'erc721a/contracts/extensions/IERC721AQueryable.sol';

import './Library.sol';
import './interfaces/IForgedGear.sol';
import './interfaces/IAssets.sol';
import './interfaces/IKeys.sol';
import './interfaces/ITacticalGear.sol';
import './interfaces/ILibrary.sol';

import './opensea-enforcer/DefaultOperatorFilterer.sol';

contract TacticalGear is ERC721AQueryable, Ownable, DefaultOperatorFilterer {
  using SafeMath for uint256;

  uint256 public constant PRICE = 0.025 ether;
  uint256 public constant ITEMS_PER_PACK = 6;
  uint256 public constant MAX_SUPPLY = 4444 * ITEMS_PER_PACK;
  uint256 public constant MAX_PACKS_PER_MINT = 10;

  bool public isPresale = true;
  bool public isDealerAvailable = false;
  address signerAddress;

  mapping(uint256 => ITacticalGear.Item) private items;
  mapping(uint256 => string) private prefixes;
  mapping(uint256 => string) private suffixes;
  mapping(uint256 => string) private r0n1;
  mapping(address => uint256) private allowListMints;

  uint256 private itemsLength;
  uint256 private prefixesLength;
  uint256 private suffixesLength;
  uint256 private r0n1Length;

  mapping(uint256 => uint256) private tokenToItemIndex;
  mapping(uint256 => uint256) private tokenToMintedAt;

  // contract references
  IAssets private assets;
  IForgedGear private forgedGear;
  IKeys private keysContract;
  IERC721Enumerable private oniContract;

  constructor(
    string memory name,
    string memory symbol,
    address assetsAddress,
    address oniAddress
  ) ERC721A(name, symbol) {
    assets = IAssets(assetsAddress);
    oniContract = IERC721Enumerable(oniAddress);
  }

  modifier onlyInternalOrForged() {
    bool isInternal = msg.sender == address(this);
    bool isForgedContract = msg.sender == address(forgedGear);
    require(isInternal || isForgedContract, 'Unknown caller');
    _;
  }

  function isFromForgedContract() internal view returns (bool) {
    return msg.sender == address(forgedGear);
  }

  function freeMint(
    uint256 packs,
    uint256 max,
    bytes calldata signature
  ) external {
    require(isPresale, 'Presale ended');
    require(isValidSignature(signerAddress, max, packs, signature), 'Invalid signature');
    require(allowListMints[_msgSender()] + packs <= max, 'You have reached the limit');

    allowListMints[_msgSender()] += packs;
    mint(packs);
  }

  function publicMint(uint256 packs) external payable {
    require(oniContract.balanceOf(msg.sender) != 0, 'Should own at least one 0n1');
    require(msg.value == packs * PRICE, 'Invalid amount of ETH');
    mint(packs);
  }

  function mint(uint256 packs) internal {
    require(isDealerAvailable, 'The dealer is not available');
    require(packs <= MAX_PACKS_PER_MINT, 'Cannot mint that many at once');
    require(totalSupply().add(packs * ITEMS_PER_PACK) <= MAX_SUPPLY, 'Not enough left to mint');
    tokenToMintedAt[_nextTokenId()] = block.timestamp;

    _safeMint(msg.sender, packs * ITEMS_PER_PACK);
  }

  function burn(uint256[] calldata tokenIds) internal {
    uint256 itemIndex1 = getItemIndex(tokenIds[0]);
    uint256 itemIndex2 = getItemIndex(tokenIds[1]);
    uint256 itemIndex3 = getItemIndex(tokenIds[2]);

    require(itemIndex1 == itemIndex2 && itemIndex1 == itemIndex3, 'All items should be of equal type');

    for (uint256 i = 0; i <= 2; i++) {
      require(ownerOf(tokenIds[i]) == _msgSender(), 'Not your gear');
      _burn(tokenIds[i]);
    }
  }

  function forgeGear(uint256[] calldata tokenIds) public {
    require(tokenIds.length == 3, 'Need three items to forge');
    burn(tokenIds);
    forgedGear.forge(_msgSender(), tokenIds[0]);
  }

  function forgeKey(uint256[] calldata tokenIds) public {
    require(tokenIds.length == 3, 'Need three items to forge');
    burn(tokenIds);
    keysContract.forge(_msgSender());
  }

  function transferAll(address to) public {
    uint256 balanceOf = this.balanceOf(_msgSender());
    uint256[] memory tokensOfOwner = this.tokensOfOwner(_msgSender());

    for (uint256 i = 0; i < balanceOf; i++) {
      super.safeTransferFrom(_msgSender(), to, tokensOfOwner[i]);
    }
  }

  function completedAllowListMints(address _address) public view returns (uint256) {
    return allowListMints[_address];
  }

  function getMintedAt(uint256 tokenId) private view returns (uint256) {
    for (uint256 i = tokenId; i >= 0; i--) {
      if (tokenToMintedAt[i] != 0) {
        return tokenToMintedAt[tokenId];
      }
    }

    return 0;
  }

  function getItemIndex(uint256 tokenId) private view returns (uint256) {
    uint256 seed = getMintedAt(tokenId);
    uint256 rand = Library.random('item', seed + tokenId);
    return rand % itemsLength;
  }

  function getItem(uint256 tokenId) external view onlyInternalOrForged returns (ITacticalGear.Item memory) {
    return items[getItemIndex(tokenId)];
  }

  function getPrefix(uint256 tokenId) external view onlyInternalOrForged returns (string memory) {
    bool isForged = isFromForgedContract();
    uint256 seed = isForged ? forgedGear.getForgedAt(tokenId) : getMintedAt(tokenId);
    uint256 rand = Library.random('prefix', seed + tokenId);
    return prefixes[rand % prefixesLength];
  }

  function getSuffix(uint256 tokenId) external view onlyInternalOrForged returns (string memory) {
    bool isForged = isFromForgedContract();
    uint256 seed = isForged ? forgedGear.getForgedAt(tokenId) : getMintedAt(tokenId);
    uint256 rand = Library.random('suffix', seed + tokenId);
    return suffixes[rand % suffixesLength];
  }

  function hasR0N1(uint256 tokenId) external view onlyInternalOrForged returns (bool) {
    string memory name = this.getItem(tokenId).name;

    for (uint256 i = 0; i < r0n1Length; i++) {
      if (Library.isEqualStrings(r0n1[i], string(abi.encodePacked('R0N1 ', name)))) {
        uint256 rand = Library.random('r0n1', getItemIndex(tokenId) + tokenId);
        return rand % uint256(7) == uint256(0);
      }
    }

    return false;
  }

  function getGear(uint256 tokenId) external view returns (ITacticalGear.TacticalGear memory) {
    require(_exists(tokenId), 'Token does not exist');

    string memory name = this.getItem(tokenId).name;
    string memory suffix = this.getSuffix(tokenId);
    string memory category = this.getItem(tokenId).category;

    return
      ITacticalGear.TacticalGear({
        fullName: string(abi.encodePacked(name, ' ', suffix)),
        name: name,
        category: category,
        suffix: suffix
      });
  }

  function getImage(uint256 tokenId) public view returns (string memory) {
    require(_exists(tokenId), 'Token does not exist');
    return Library.getImage(ILibrary.ImageInput(assets.getAsset(this.getItem(tokenId).name), '', '', false, false));
  }

  function getCardImage(uint256 tokenId) public view returns (string memory) {
    require(_exists(tokenId), 'Token does not exist');

    return
      Library.getCardImage(
        ILibrary.CardImageInput(
          this.getItem(tokenId).name,
          '',
          this.getSuffix(tokenId),
          assets.getAsset(this.getItem(tokenId).name),
          assets.getAsset(string(abi.encodePacked('R0N1 ', this.getItem(tokenId).name))),
          assets.getAsset(this.getSuffix(tokenId)),
          '',
          false,
          false,
          assets.getAsset('card'),
          assets.getAsset('font')
        )
      );
  }

  function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
    require(_exists(tokenId), 'Token does not exist');
    return Library.getMetadata(this.getItem(tokenId), this.getSuffix(tokenId), '', false, false, getCardImage(tokenId));
  }

  function setItems(string[][] calldata _items) public onlyOwner {
    itemsLength = _items.length;
    for (uint256 i = 0; i < _items.length; i++) {
      items[i] = ITacticalGear.Item({ category: _items[i][0], name: _items[i][1] });
    }
  }

  function setSuffixes(string[] calldata _suffixes) public onlyOwner {
    suffixesLength = _suffixes.length;
    for (uint256 i = 0; i < _suffixes.length; i++) {
      suffixes[i] = _suffixes[i];
    }
  }

  function setPrefixes(string[] calldata _prefixes) public onlyOwner {
    prefixesLength = _prefixes.length;
    for (uint256 i = 0; i < _prefixes.length; i++) {
      prefixes[i] = _prefixes[i];
    }
  }

  function setR0n1(string[] calldata _r0n1) public onlyOwner {
    r0n1Length = _r0n1.length;
    for (uint256 i = 0; i < _r0n1.length; i++) {
      r0n1[i] = _r0n1[i];
    }
  }

  function setForgedGearContract(address _forgedGear) public onlyOwner {
    forgedGear = IForgedGear(_forgedGear);
  }

  function setKeysContract(address _keysContract) public onlyOwner {
    keysContract = IKeys(_keysContract);
  }

  function setPresale(bool _presale) public onlyOwner {
    isPresale = _presale;
  }

  function setIsDealerAvailable(bool _isDealerAvailable) public onlyOwner {
    isDealerAvailable = _isDealerAvailable;
  }

  function setSignerAddress(address _signerAddress) public onlyOwner {
    signerAddress = _signerAddress;
  }

  function isValidSignature(
    address signer,
    uint256 max,
    uint256 amount,
    bytes calldata signature
  ) private view returns (bool) {
    return signer == ECDSA.recover(keccak256(abi.encodePacked(_msgSender(), max, amount)), signature);
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(_msgSender()).transfer(balance);
  }

  // OpenSea Enforcer functions
  function setApprovalForAll(address operator, bool approved)
    public
    override(ERC721A, IERC721A)
    onlyAllowedOperatorApproval(operator)
  {
    super.setApprovalForAll(operator, approved);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}