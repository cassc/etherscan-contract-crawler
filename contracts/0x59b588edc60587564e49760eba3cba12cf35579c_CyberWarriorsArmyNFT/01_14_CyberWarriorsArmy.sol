// SPDX-License-Identifier: UNLICENSED
// solium-disable linebreak-style
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract CyberWarriorsArmyNFT is Context, Ownable, ERC721 {
  using Address for address;
  using Strings for uint256;

  string private _baseTokenURI;
  string private _notRevealedURI;

  uint8 public LIMIT_TOKENS_PER_WALLET_PUBLIC = 20;
  uint8 public LIMIT_TOKENS_PER_WALLET_PRIVATE = 5;
  uint8 public LIMIT_TOKENS_FOR_GIVEAWAYS = 250;

  uint256 public PRIVATE_MINT_TOKEN_PRICE = 0.035 ether;
  uint256 public PUBLIC_MINT_TOKEN_PRICE = 0.050 ether;

  bool public revealed = false;
  bool public isPublic = false;
  bool public isOpen = false;

  uint256 public maxSupply;
  uint256 private nextTokenId = 1;
  mapping(address => bool) private _whitelisted;
  mapping(address => uint256) public countPurchasedTokens;

  /** Events */
  event AddedToWhitelist(address indexed account);
  event RemoveFromWhitelist(address indexed account);

  /** Constructor */

  constructor(
    address superOwner,
    string memory name,
    string memory symbol,
    uint256 initMaxSupply,
    string memory baseTokenURI,
    string memory notRevealedURI
    ) ERC721(name, symbol) {
    _baseTokenURI = baseTokenURI;
    _notRevealedURI = notRevealedURI;
    maxSupply = initMaxSupply;

    if (superOwner != msg.sender) {
      transferOwnership(superOwner);
    }
  }

  /** Functions */

  /// The required currency value in wei during the method execution based on the price for the token from the current round
  /// @dev Buy tokens by single wallet
  function buyToken(uint8 _amount) public payable {
    require(isOpen, "Minting is not open yet");
    require(msg.sender == tx.origin, "no bots");        // solium-disable-line security/no-tx-origin

    uint256 _nextTokenId = nextTokenId;
    uint256 _currentSupply = _nextTokenId - 1;
    uint256 _purchasedByWallet = countPurchasedTokens[msg.sender];

    uint8 maxWalletSupply = LIMIT_TOKENS_PER_WALLET_PUBLIC;
    uint256 currentTokenPrice = PUBLIC_MINT_TOKEN_PRICE;
    if (isPublic == false) {
      require(_whitelisted[msg.sender], "You are not whitelisted");
      maxWalletSupply = LIMIT_TOKENS_PER_WALLET_PRIVATE;
      currentTokenPrice = PRIVATE_MINT_TOKEN_PRICE;
    }

    require(_amount * currentTokenPrice == msg.value, "invalid coin amount");
    require(_currentSupply + _amount <= maxSupply, "mint: maxSupply reached");
    require(_purchasedByWallet + _amount <= LIMIT_TOKENS_PER_WALLET_PUBLIC, "mint: limit tokens for this wallet reached");

    for (uint8 i = 0; i < _amount; i++) {
      _safeMint(msg.sender, _nextTokenId);
      unchecked {
        _nextTokenId++;
        _purchasedByWallet++;
      }

    }
    unchecked {
      countPurchasedTokens[msg.sender] = _purchasedByWallet;
      nextTokenId = _nextTokenId;
    }

  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  /// Only owner
  /// @dev Change baseURI
  /// @param newTokenURI New uri to new folder with metadata
  function setBaseURI(string memory newTokenURI) public onlyOwner returns (bool) {
    _baseTokenURI = newTokenURI;
    return true;
  }

  /// Only owner
  /// @dev Change baseURI for not revealed tokens
  /// @param newTokenURI New uri to new folder with metadata
  function setNotRevealedURI(string memory newTokenURI) public onlyOwner returns (bool) {
    _notRevealedURI = newTokenURI;
    return true;
  }

  /// @dev Return all available tokens
  function availableTokens() public view returns (uint256) {
    uint256 supply = nextTokenId - 1;
    return maxSupply - supply;
  }

    /// @dev Return all available tokens
  function totalSupply() public view returns (uint256) {
    return nextTokenId - 1;
  }

  /**
    * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
    */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    if(revealed == false) {
      return _notRevealedURI;
    }

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
  }

  /// Only owner
  /// @dev Reveal URI of tokens
  function reveal() public onlyOwner {
    revealed = true;
  }

  /// Only owner
  /// @dev Sets public mint
  /// @param _isPublic  isPublic indicator
  function setPublic(bool _isPublic) public onlyOwner {
    isPublic = _isPublic;
  }

  /// Only owner
  /// @dev Sets open mint
  /// @param _isOpen  isOpen indicator
  function setOpen(bool _isOpen) public onlyOwner {
    isOpen = _isOpen;
  }

  /// Only owner
  /// @dev Add array of addresses to whitelist
  /// @param _addresses array of addresses
  function addToWhitelist(address[] memory _addresses) public onlyOwner {
    require(_addresses.length > 0, "Addresses not provided");
    uint16 i = 0;
    for(i; i < _addresses.length; i++) {
      if (!_whitelisted[_addresses[i]]) {
        _whitelisted[_addresses[i]] = true;
        emit AddedToWhitelist(_addresses[i]);
      }
    }
  }

  /// Only owner
  /// @dev Remove array of addresses from whitelist
  /// @param _addresses array of addresses
  function removeFromWhitelist(address[] memory _addresses) public onlyOwner {
    require(_addresses.length > 0, "Addresses not provided");
    uint16 i = 0;
    for(i; i < _addresses.length; i++) {
      if (_whitelisted[_addresses[i]]) {
        _whitelisted[_addresses[i]] = false;
        emit RemoveFromWhitelist(_addresses[i]);
      }
    }
  }

  /// @dev Check if address is on whitelist
  /// @param _address address to check
  function isWhitelisted(address _address) public view returns(bool) {
    return _whitelisted[_address];
  }

  /// Only owner
  /// @dev Withdraw funds to the receiver address
  /// @param receiver wallet of receiver funds
  /// @param amount amount of funds
  function withdraw(address payable receiver, uint256 amount) public onlyOwner {
    receiver.transfer(amount);
  }

  /// Only owner
  /// @dev Creates Giveaways tokens
  /// @param tokensAmount amount of tokens to be created
  function createGiveawayTokens(
    uint8 tokensAmount
  ) public onlyOwner {
    uint256 _nextTokenId = nextTokenId;
    uint256 _currentSupply = totalSupply();
    uint256 _purchasedTokensByWallet = countPurchasedTokens[msg.sender];

    require(
      _purchasedTokensByWallet + tokensAmount <= LIMIT_TOKENS_FOR_GIVEAWAYS,
      "createGiveawaysTokens: limit tokens for giveaway wallet reached"
    );
    require(_currentSupply + tokensAmount <= maxSupply, "createGiveawaysTokens: Total tokens limit reached");

    for (uint8 i = 0; i < tokensAmount; i++) {
      _safeMint(msg.sender, _nextTokenId);
      _nextTokenId++;
      _purchasedTokensByWallet++;
    }
    nextTokenId = _nextTokenId;
    countPurchasedTokens[msg.sender] = _purchasedTokensByWallet;
  }

  function tokensOfOwnerByIndex(address _owner, uint256 _index)
      public
      view
      returns (uint256) {
    return tokensOfOwner(_owner)[_index];
  }

  function tokensOfOwner(address _owner)
    public
    view
    returns (uint256[] memory) {
    uint256 _tokenCount = balanceOf(_owner);
    uint256[] memory _tokenIds = new uint256[](_tokenCount);
    uint256 _tokenIndex = 0;
    for (uint256 i = 1; i <= totalSupply(); i++) {
      if (ownerOf(i) == _owner) {
        _tokenIds[_tokenIndex] = i;
        _tokenIndex++;
      }
    }
    return _tokenIds;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  /**
    * @dev See {IERC165-supportsInterface}.
    */
  function supportsInterface(bytes4 interfaceId)
      public
      view
      virtual
      override(ERC721)
      returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}