//
//                        ,.  ;-.  ,--.   ,-.   ,.   ,-.
//                       /  \ |  ) |      |  \ /  \ /   \
//                       |--| |-'  |-     |  | |--| |   |
//                       |  | |    |      |  / |  | \   /
//                       '  ' '    `--'   `-'  '  '  `-'
//
// ..........................................................................
// ..........................................................................
// ..........................................................................
// ..........................................................................
// ..........................*&&&&&,........&&&&&&...........................
// .....................,(....&&&&&(.......&&*..,&&..........................
// .................,&&/.&&....&&&&#.........&&&&&...,&&&&&&.................
// ...................&&&.........................../&#&&&&..................
// ....................#&............***.***.............&&....,.............
// ...........&&&&&&&&...............***.***................*&&&*&&..........
// ............&&&&..........................................&&...&&.........
// .............&&.......&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%......,&&&&..........
// ....................&&&&&.....,*#&&&&&&&&&#*,.....&&&&%...................
// ....................&&&............&&&&&...........,&&&...................
// ...................&&&&............,&&&,............&&&&..................
// ...................&&&&%........*%&&&&&&&#*........&&&&&..................
// ...................&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&..................
// ..............,......&&&&&&&&%&&&&&&...&&&&&&%&&&&&&&&......*.............
// ...............*.............&&&&&.......&&&&&............**..............
// ...............,**..........&&&&%....&....&&&&&.........***...............
// ................****........&&&&&&&&&&&&&&&&&&&.......****................
// ...............*******.......&&&&&&&&&&&&&&&&&......,******...............
// .................****.......&&&&&&,(&&&&*&&&&&&......****.................
// ..................****..............................****..................
// ..................******.....&&&.*&&&&&&&.,&&&....******..................
// .....................**.......&&&&&&&&&&&&&&&......**.....................
// .......................**......&&&&&&&&&&&&&.....**.......................
// ..................................#&&&&&(.................................
// ..........................................................................
// ....................................***...................................
// ..........................................................................
// ..........................................................................

/*

       888~-_      888~-_      888         e    e              e
       888   \     888   \     888        d8b  d8b            d8b
       888    |    888    |    888       d888bdY88b          /Y88b
       888   /     888   /     888      / Y88Y Y888b        /  Y88b
       888_-~      888_-~      888     /   YY   Y888b      /____Y88b
       888         888 ~-_     888    /          Y888b    /      Y88b

       888~-_        ,88~-_      888b    |    888b    |         e
       888   \      d888   \     |Y88b   |    |Y88b   |        d8b
       888    |    88888    |    | Y88b  |    | Y88b  |       /Y88b
       888    |    88888    |    |  Y88b |    |  Y88b |      /  Y88b
       888   /      Y888   /     |   Y88b|    |   Y88b|     /____Y88b
       888_-~        `88_-~      |    Y888    |    Y888   /       Y88b

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// ========== Imports ==========
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./RemixMintClub.sol";
import "./ApeDaoRemix.sol";

contract OriginalsPrimaDonna is ERC721, ERC721Burnable, ERC721Enumerable, ERC721URIStorage, AccessControl, Ownable, Pausable, ReentrancyGuard {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIdCounter;
  uint256 private _goldTokenIdCount;

  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  uint8 constant GOLD_TOKEN_ID = 1;
  uint8 constant BASIC_TOKEN_ID = 2;

  // ========== Immutable Variables ==========

  /// @notice Mint Token Address
  address payable public immutable MINT_TOKEN_CONTRACT_ADDRESS;
  /// @notice Remix Contract Address
  address payable public immutable REMIX_CONTRACT_ADDRESS;
  /// @notice An address to withdraw balance to
  address payable public immutable PAYABLE_ADDRESS_1;
  /// @notice An address to withdraw balance to
  address payable public immutable PAYABLE_ADDRESS_2;

  // ========== Mutable Variables ==========

  string public baseURI;
  string public provenanceHash;
  uint16 public maximumSupply;
  uint16 public maximumGoldSupply;
  uint8 public transactionLimit;
  uint256 public mintCost;

  mapping(address => mapping(TokenRequirementType => uint256)) numMintsPerAddress;
  mapping(TokenRequirementType => uint16) walletLimitByWindow;
  mapping(address => bool) doubleGoldWalletHolder;
  address[] doubleGoldWalletHolderAddresses;

  TokenRequirementType public mintTokenRequirement;

  enum TokenRequirementType {
    NONE,
    GOLD,
    BASIC,
    ANY
  }

  bool public remixHolderRequired = true;

  // ========== Constructor ==========

  constructor(
    address payable _MINT_TOKEN_CONTRACT_ADDRESS,
    address payable _REMIX_CONTRACT_ADDRESS,
    uint16 _maximumSupply,
    uint16 _maximumGoldSupply,
    uint256 _mintCost,
    uint8 _transactionLimit,
    address _payableAddress1,
    address _payableAddress2,
    bool _remixHolderRequired,
    string memory _provenanceHash
  ) ERC721("Prima Donna", "PRIMADONNA") {
    MINT_TOKEN_CONTRACT_ADDRESS = _MINT_TOKEN_CONTRACT_ADDRESS;
    REMIX_CONTRACT_ADDRESS = _REMIX_CONTRACT_ADDRESS;

    maximumSupply = _maximumSupply;
    maximumGoldSupply = _maximumGoldSupply;
    mintCost = _mintCost;

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(ADMIN_ROLE, msg.sender);

    mintTokenRequirement = TokenRequirementType.GOLD;
    remixHolderRequired = _remixHolderRequired;

    PAYABLE_ADDRESS_1 = payable(_payableAddress1);
    PAYABLE_ADDRESS_2 = payable(_payableAddress2);

    transactionLimit = _transactionLimit;

    walletLimitByWindow[TokenRequirementType.NONE] = 10;
    walletLimitByWindow[TokenRequirementType.GOLD] = 10;
    walletLimitByWindow[TokenRequirementType.BASIC] = 10;
    walletLimitByWindow[TokenRequirementType.ANY] = 10;

    provenanceHash = _provenanceHash;

    _pause();
  }

  // ========== Minting ==========

  // @notice Mints tokens to the caller when there is no Mint token requirement
  function mintADC(uint256 _quantity) public payable whenNotPaused nonReentrant {
    require(mintTokenRequirement == TokenRequirementType.NONE, "Mint tokens are required to mint.");
    checkMintValid(_quantity);
    mint(_quantity);
  }

  // @notice Mints tokens to the caller when Mint tokens are required
  function mintADCWithToken(uint8 numGoldTokens, uint8 numBasicTokens) public payable whenNotPaused nonReentrant {
    require(mintTokenRequirement != TokenRequirementType.NONE, "Mint tokens are not required to mint.");

    if(mintTokenRequirement == TokenRequirementType.GOLD) {
      require(numGoldTokens > 0, "Gold token must be greater than 0");
      require(numBasicTokens == 0, "only gold tokens are required to mint");
    }

    if(mintTokenRequirement == TokenRequirementType.BASIC) {
      require(numBasicTokens > 0, "Basic token must be greater than 0");
      require(numGoldTokens == 0, "only basic tokens are required to mint");
    }

    uint256 _quantity = numGoldTokens + numBasicTokens;
    checkMintValid(_quantity);

    RemixMintClub mintClubContract = RemixMintClub(MINT_TOKEN_CONTRACT_ADDRESS);

    // If Gold token is required
    if((mintTokenRequirement == TokenRequirementType.GOLD || mintTokenRequirement == TokenRequirementType.ANY) && numGoldTokens > 0) {
      mintClubContract.burn(msg.sender, GOLD_TOKEN_ID, numGoldTokens);
    }

    // If Basic token is required
    if((mintTokenRequirement == TokenRequirementType.BASIC || mintTokenRequirement == TokenRequirementType.ANY) && numBasicTokens > 0) {
      mintClubContract.burn(msg.sender, BASIC_TOKEN_ID, numBasicTokens);
    }

    mint(_quantity);
  }

  function checkMintValid(uint256 _quantity) internal {
    if(mintTokenRequirement == TokenRequirementType.GOLD) {
      require(_goldTokenIdCount + _quantity <= maximumGoldSupply, "Quantity must be less than remaining supply for Gold tokens");
    }

    require(_quantity > 0, "Quantity must be greater than 0");
    require(_tokenIdCounter.current() + _quantity <= maximumSupply, "Quantity must be less than remaining supply");

    uint16 walletLimit = getMintAllowance(msg.sender, mintTokenRequirement);

    require(numMintsPerAddress[msg.sender][mintTokenRequirement] + _quantity <= walletLimit, "Exceeds wallet limit for window");

    require(_quantity <= transactionLimit, "Too many tokens to mint");
    require(msg.value >= mintCost * _quantity, "Insufficient funds for minting");

    if(remixHolderRequired) {
      ApeDaoRemix remixContract = ApeDaoRemix(REMIX_CONTRACT_ADDRESS);
      require(remixContract.balanceOf(msg.sender) > 0, "You must be a Remix holder to mint");
    }
  }

  function mint(uint256 _quantity) internal {
    numMintsPerAddress[msg.sender][mintTokenRequirement] += _quantity;

    if(mintTokenRequirement == TokenRequirementType.GOLD) {
      _goldTokenIdCount += _quantity;
    }

    internalMint(_quantity);
  }

  function getMintAllowance(address _signer, TokenRequirementType _tokenRequirement) public view returns (uint16) {
    uint16 walletLimit = walletLimitByWindow[_tokenRequirement];

    if(_tokenRequirement == TokenRequirementType.GOLD && doubleGoldWalletHolder[_signer]) {
      walletLimit = walletLimit * 2;
    }

    return walletLimit;
  }

  function getNumMints(address _signer, TokenRequirementType _tokenRequirement) public view returns (uint256) {
    return numMintsPerAddress[_signer][_tokenRequirement];
  }

  function getDoubleGoldWalletHolder(address _address) public view returns (bool) {
    return doubleGoldWalletHolder[_address];
  }

  function getDoubleGoldWalletHolderAddresses() public view returns (address[] memory) {
    return doubleGoldWalletHolderAddresses;
  }

  function internalMint(uint256 _quantity) internal {
    for(uint8 i = 0; i < _quantity; i++) {
      _tokenIdCounter.increment(); // Increment first so that we start at token 1
      _safeMint(_msgSender(), _tokenIdCounter.current());
    }
  }

  // ========== Admin ==========

  function adminMint(uint256 _quantity) public onlyAdmin {
    require(_quantity > 0, "Quantity must be greater than 0");
    require(_tokenIdCounter.current() + _quantity <= maximumSupply, "Quantity must be less than remaining supply");

    internalMint(_quantity);
  }

  function setMintTokenRequirement(TokenRequirementType _mintTokenRequirement) public onlyAdmin {
    mintTokenRequirement = _mintTokenRequirement;
  }

  function setMaximumGoldSupply(uint16 _maximumGoldSupply) public onlyAdmin {
    maximumGoldSupply = _maximumGoldSupply;
  }

  function setMintCost(uint256 _mintCost) public onlyAdmin {
    mintCost = _mintCost;
  }

  function setDoubleGoldWalletHolders(address[] calldata _addresses) public onlyAdmin {
    for(uint8 i = 0; i < doubleGoldWalletHolderAddresses.length; i++) {
      doubleGoldWalletHolder[doubleGoldWalletHolderAddresses[i]] = false;
    }

    delete doubleGoldWalletHolderAddresses;

    for(uint8 i = 0; i < _addresses.length; i++) {
      doubleGoldWalletHolder[_addresses[i]] = true;
      doubleGoldWalletHolderAddresses.push(_addresses[i]);
    }
  }

  function setRemixHolderRequired(bool value) public onlyAdmin {
    remixHolderRequired = value;
  }

  function withdraw() public onlyAdmin {
    Address.sendValue(payable(PAYABLE_ADDRESS_1), address(this).balance * 60 / 100);
    Address.sendValue(payable(PAYABLE_ADDRESS_2), address(this).balance);
  }

  function pause() public onlyAdmin {
    _pause();
  }

  function unpause() public onlyAdmin {
    _unpause();
  }

  // ========== ERC721Enumerable Overrides ==========

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  // ========== ERC721URIStorage Overrides ==========

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function setBaseURI(string memory baseURI_) public onlyAdmin {
    baseURI = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  // ========== Modifiers ==========

  modifier onlyAdmin() {
    require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
    _;
  }
}