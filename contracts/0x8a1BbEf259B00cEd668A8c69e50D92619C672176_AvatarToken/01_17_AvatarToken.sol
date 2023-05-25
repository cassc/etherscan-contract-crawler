// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AvatarToken is ERC721URIStorage, ERC721Enumerable, Ownable, ERC721Pausable {
  using Counters for Counters.Counter;
  using Strings for uint256;

  Counters.Counter private _tokenIds;

  // ID for ERC-2981 Royalty fee standard
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  // File extension for metadata file
  string constant Extension = ".json";

  uint96 constant DefaultRoyaltyPercent = 250;

  // The base domain for the tokenURI
  string private _baseTokenURI;

  // Limit the number of tokens able to mint
  uint private _tokenLimit;

  // Limit the number of tokens user can buy in a transaction
  uint private _purchaseLimit;

  // initial Price in Ether for each token
  uint private _price;

  // Royalty percentage fee
  uint96 private _royaltyPercent;

  enum PricingMode { FIXED, TIMEDROP }

  /**
   * 1 is presale
   * 2 is public
   */
  PricingMode private _pricingMode;

  /* The time the pricing mode is changed to timedrop */
  uint private _timeDropAt;
  uint private _dropDuration;
  uint private _dropPrice;
  uint private _floorPrice;
  uint private _dropOffset;

  /* The time the contract is created */
  uint private _createdAt;

  /* Presale and whitelist addresses */
  bool private _presale;
  mapping(address => bool) private _whitelist;
  address[] private _whitelistAddresses;

  /**
   * name: the token's name
   * price: the price (in Wei) for each token purchase
   * baseTokenURI: the base domain for each token URI
   * tokenLimit: the maximum number of tokens can be minted
   */
  constructor(string memory name, string memory token, string memory baseTokenURI, uint tokenLimit) ERC721(name, token) {
    _baseTokenURI = baseTokenURI;
    _tokenLimit = tokenLimit;
    _purchaseLimit = 20;
    _royaltyPercent = DefaultRoyaltyPercent;
    _pricingMode = PricingMode.FIXED;

    // Price & Drop price initial parameters
    _price = 0.1 ether;
    _createdAt = block.timestamp;
    _dropDuration = 12 hours;
    _dropOffset = 24 hours;
    _dropPrice = 0.01 ether;
    _floorPrice = 0.01 ether;

    // presale
    _presale = true;
    _whitelist[msg.sender] = true;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function _mintTokensToAddr(uint amount, address receiver) internal {
    while (amount > 0) {
      amount--;
      _tokenIds.increment();

      uint256 newTokenId = _tokenIds.current();

      _safeMint(receiver, newTokenId);
      _setTokenURI(newTokenId, string(abi.encodePacked(newTokenId.toString(), Extension)));
    }
  }

  // Purchase and mint amount of tokens to message sender
  function purchaseToken(uint tokens) public payable {
    require(!paused(), "Token mint while paused");
    require(tokens <= _purchaseLimit, "Tokens purchase exceeds limit");
    require(totalSupply() + tokens <= _tokenLimit, "Token limit exceeded");
    require(getPrice() * tokens <= msg.value, "Invalid ETH amount");

    if (_presale) {
      require(_whitelist[msg.sender], "Wallet address is not allowed");
    }

    _mintTokensToAddr(tokens, msg.sender);
  }

  // Mint an amount of tokens for free to an address `to`
  function mintTokens(uint tokens, address to) public onlyOwner {
    require(totalSupply() + tokens <= _tokenLimit, "Token limit exceeded");

    _mintTokensToAddr(tokens, to);
  }

  // Increase the token's limit
  function increaseLimit(uint limit) public onlyOwner {
    _tokenLimit += limit;
  }

  // Set the token's limit
  function setLimit(uint limit) public onlyOwner {
    _tokenLimit = limit;
  }

  // Set the purchase limit
  function setPurchaseLimit(uint limit) public onlyOwner {
    _purchaseLimit = limit;
  }

  // Update the base URI for token
  function updateBaseTokenURI(string memory baseTokenURI) public onlyOwner {
    _baseTokenURI = baseTokenURI;
  }

  // Update the royalty fee
  function updateRoyaltyPercent(uint96 royaltyPercent) public onlyOwner {
    _royaltyPercent = royaltyPercent;
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Pausable, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  // ERC-2981 interface method
  function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
    // all tokens have the same royalty fee
    tokenId = tokenId;
    return (owner(), (salePrice * _royaltyPercent) / 10000);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
    if (interfaceId == _INTERFACE_ID_ERC2981) {
      return true;
    }

    return super.supportsInterface(interfaceId);
  }

  // Get the current token mint price
  function getPrice() public view returns (uint) {
    if (_pricingMode == PricingMode.TIMEDROP && _timeDropAt > 0) {
      return _calcPrice(block.timestamp);
    }

    return _price;
  }

  // calculate the price at timeAt (only for TimeDrop mode)
  function _calcPrice(uint timeAt) internal view returns (uint) {
    // calculate the price based on the elapsed time
    if (timeAt > _timeDropAt + _dropOffset) {
      uint intervals = (timeAt - _dropOffset - _timeDropAt) / _dropDuration;
      uint dropBy = intervals * _dropPrice;

      return _price > _floorPrice + dropBy ? _price - dropBy : _floorPrice;
    }

    return _price;
  }

  // Get the drop price at (only used in testing)
  function _getDropPriceAt(uint timeAt) public view onlyOwner returns (uint) {
    return _calcPrice(timeAt);
  }

  // Get the pricing mode, only owner
  function _getPricingData() public view onlyOwner returns (uint[5] memory) {
    return [ uint(_pricingMode), _dropDuration, _dropOffset, _dropPrice, _floorPrice ];
  }

  // Set the pricing mode, only owner
  function setPricing(uint8 mode, uint price, uint duration, uint dropOffset, uint dropPrice, uint floorPrice) public onlyOwner {
    _pricingMode = PricingMode(mode);
    _price = price;

    if (_pricingMode == PricingMode.TIMEDROP) {
      _timeDropAt = block.timestamp;
      _dropDuration = duration;
      _dropOffset = dropOffset;
      _dropPrice = dropPrice;
      _floorPrice = floorPrice;
    }
  }

  function setSalePublic() public onlyOwner {
    _presale = false;
  }

  function setPresale() public onlyOwner {
    _presale = true;
  }

  function isPresale() public view returns (bool) {
    return _presale;
  }

  function addAddress(address addr) public onlyOwner {
    _whitelist[addr] = true;
    _whitelistAddresses.push(addr);
  }

  function removeAddress(address addr) public onlyOwner {
    _whitelist[addr] = false;
  }

  function getWhitelistAddresses() public view onlyOwner returns (address[] memory) {
    uint j = 0;
    uint len = _whitelistAddresses.length;

    for (uint i = 0; i < _whitelistAddresses.length; i++) {
      address addr = _whitelistAddresses[i];

      if (!_whitelist[addr]) {
        len--;
      }
    }

    address[] memory addresses = new address[](len);
    for (uint i = 0; i < _whitelistAddresses.length; i++) {
      address addr = _whitelistAddresses[i];

      if (_whitelist[addr]) {
        addresses[j++] = addr;
      }
    }

    return addresses;
  }

  // Withdraw all money to sender's account, only owner can call this
  function withdrawMoney() public onlyOwner {
    address payable to = payable(msg.sender);
    to.transfer(address(this).balance);
  }

  // Get the current royalty fee
  function getRoyaltyPercent() public view onlyOwner returns (uint) {
    return _royaltyPercent;
  }

  // Get the current token limit
  function getLimit() public view returns (uint) {
    return _tokenLimit;
  }

  // Get the purchase limit
  function getPurchaseLimit() public view returns (uint) {
    return _purchaseLimit;
  }

  // Return the list of tokenIds of an owner
  function tokensOfOwner(address owner) external view returns (uint256[] memory) {
    uint size = balanceOf(owner);
    uint[] memory tokens = new uint[](size);

    for (uint i = 0; i < size; i++) {
      tokens[i] = tokenOfOwnerByIndex(owner, i);
    }

    return tokens;
  }

  // Pause the contract
  function setPaused(bool pause) public onlyOwner {
    if (pause && !paused()) {
      _pause();
    }

    if (!pause && paused()) {
      _unpause();
    }
  }

  // Destroy the smart contract and transfer fund to owner
  function destroySmartContract() public onlyOwner {
    selfdestruct(payable(msg.sender));
  }
}