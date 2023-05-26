// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/*                                                              Remember Me
Afterlife.garden🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷2022
🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷
🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷
🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷
🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷
🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷
🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷
🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷
Luna Ikuta🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷Teknique
                                                             A Story About You                                                          */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract RememberMe is ERC721, ERC721Enumerable, ERC721URIStorage, IERC2981, Ownable, ReentrancyGuard {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenCounter;

  uint256 private constant SEED_MINT_LIMIT = 1;
  uint256 private constant GROWTH_INTERVALS = 1000;
  uint256 private constant MINUTES_PER_INTERVAL = 7;
  uint256 private constant SECONDS_PER_MINUTE = 60;
  uint256 private constant SECONDS_PER_INTERVAL = MINUTES_PER_INTERVAL * SECONDS_PER_MINUTE;
  // Since block.timestamp is denominated in seconds
  uint256 private constant TOTAL_GROWTH_SECONDS = GROWTH_INTERVALS * SECONDS_PER_INTERVAL;
  uint256 private constant MAX_SEED_DROPS = 50;
  string private burstURI;
  bool public isSeedMintActive = false;
  bool public isBurstURISet = false;
  uint256 public growthStartTime = 0;
  bool public mintHappened = false;
  uint256 public numSeedDrops = 0;
  bool private isOpenSeaProxyActive = true;
  address public luna;
  address public teknique;
  address private openSeaProxyRegistryAddress;
  string private _baseURIextended = "https://afterlife.mypinata.cloud/ipfs/QmUAauCxM9jFCXWDPUJrtR4PSL3fd62kCnfXJPtwse7m4t/";

  constructor(address _luna, address _teknique, address _openSeaProxyRegistryAddress) ERC721("Remember Me", "MEMORY") {
    openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
    luna = _luna;
    teknique = _teknique;
  }
 
  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    if(isBurstURISet) {
      return burstURI;
    }
    uint256 intervals = getTimeIntervalsPassed();
    return bytes(_baseURIextended).length > 0 ? string(abi.encodePacked(_baseURIextended, Strings.toString(intervals))) : "";
  }

  // * * * * * * * * * * * * * * * * * * * * * * MINTING * * * * * * * * * * * * * * * * * * * * * *
  function mint()
    external
    nonReentrant
    seedMintActive
    hasNoSeeds
  {
    _safeMint(_msgSender(), nextTokenId());
  }

  // * * * * * * * * * * * * * * * * * * * * JOURNEY CONTROL * * * * * * * * * * * * * * * * * * * *
  function openMint() external onlyAfterlife {
    require(isSeedMintActive == false, "Seed Mint Already Open");
    require(mintHappened == false, "Seed Mint Can Only Be Opened Once");
    isSeedMintActive = true;
  }

  function closeMint() external onlyAfterlife {
    require(isSeedMintActive == true, "Seed Mint Already Closed");
    isSeedMintActive = false;
    mintHappened = true;
    growthStartTime = block.timestamp;
  }

  // May 1, 2022
  // "Nothing is so painful to the human mind as a great and sudden change."
  // https://afterlife.mypinata.cloud/ipfs/QmZ6NPuW3ZmMHNRt5vpQ3NBdLYRAeR7J1K7Ga6xyYRkDnD
  function setBurstURI(string memory _burstURI) external onlyAfterlife() {
    require(!isBurstURISet, "BurstURI has already been set");
    burstURI = _burstURI;
    isBurstURISet = true;
  }

  // * * * * * * * * * * * * * * * * * * * * * * HELPERS * * * * * * * * * * * * * * * * * * * * * *
  function nextTokenId() private returns (uint256) {
    _tokenCounter.increment();
    return _tokenCounter.current();
  }

  function getTimeIntervalsPassed() private view returns (uint256) {
    if(growthStartTime == 0) {
      return 0;
    }
    uint256 timeCompare = block.timestamp;
    if(timeCompare - growthStartTime > TOTAL_GROWTH_SECONDS) {
      return GROWTH_INTERVALS;
    }
    uint256 intervalsPassed = 0;
    while(timeCompare - (SECONDS_PER_INTERVAL - 1) >= growthStartTime) {
      timeCompare -= SECONDS_PER_INTERVAL;
      intervalsPassed += 1;
    }
    return intervalsPassed;
  }

  // * * * * * * * * * * * * * * * * * * * * * MODIFIERS * * * * * * * * * * * * * * * * * * * * * *
  modifier onlyAfterlife() {
    require(_msgSender() == luna || _msgSender() == teknique, "msg.sender is not in Afterlife");
    _;
  }

  modifier onlyTeknique() {
    require(_msgSender() == teknique, "msg.sender is not Teknique");
    _;
  }
  
  modifier seedMintActive() {
    require(isSeedMintActive, "Seed Mint Is Not Active");
    _;
  }

  modifier hasNoSeeds() {
    require(balanceOf(_msgSender()) < SEED_MINT_LIMIT, "Only one seed per collector");
    _;
  }

  modifier canSeedDrop(uint256 num) {
    require( numSeedDrops + num <= MAX_SEED_DROPS, "Not enough seeds left for Seed Drop");
    _;
  }

  // * * * * * * * * * * * * * * * * * * * * * WITHDRAWING * * * * * * * * * * * * * * * * * * * * * 
  function withdraw() external onlyAfterlife {
    uint256 splitAmount = address(this).balance / 2;
    payable(luna).transfer(splitAmount);
    payable(teknique).transfer(splitAmount);
  }

  function withdrawTokens(IERC20 token) external onlyAfterlife {
    uint256 splitAmount = token.balanceOf(address(this)) / 2;
    token.transfer(luna, splitAmount);
    token.transfer(teknique, splitAmount);
  }

  // * * * * * * * * * * * * * * * * * * * * * SEED DROPS * * * * * * * * * * * * * * * * * * * * *
  function reserveForSeedDrops(uint256 numToReserve) external nonReentrant onlyAfterlife canSeedDrop(numToReserve) {
    numSeedDrops += numToReserve;
    for (uint256 i = 0; i < numToReserve; i++) {
      _safeMint(_msgSender(), nextTokenId());
    }
  }

  function seedDrop(address[] calldata addresses) external nonReentrant onlyAfterlife canSeedDrop(addresses.length) {
    uint256 numToDrop = addresses.length;
    numSeedDrops += numToDrop;
    for (uint256 i = 0; i < numToDrop; i++) {
      _safeMint(addresses[i], nextTokenId());
    }
  }

  // * * * * * * * * * * * * * * * * * * * * * FAILSAFES * * * * * * * * * * * * * * * * * * * * * *
  function setOpenSeaProxyRegistryAddress(address _openSeaProxyRegistryAddress) public onlyAfterlife {
    openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
  }

  // Disable gasless listings for security in case
  // opensea ever shuts down/is compromised
  function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive)
    external
    onlyAfterlife
  {
    isOpenSeaProxyActive = _isOpenSeaProxyActive;
  }

  function setLuna(address _luna) external onlyAfterlife {  
    luna = _luna;
  }

  function setTeknique(address _teknique) external onlyTeknique {  
    teknique = _teknique;
  }

  // * * * * * * * * * * * * * * * * * * * * * PLUMBING * * * * * * * * * * * * * * * * * * * * * *
  // Required Boilerplate Solidity overrides
  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721, ERC721Enumerable)
  {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, IERC165, ERC721Enumerable)
    returns (bool)
  {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  // Allowlist user's OpenSea proxy accounts to enable gas-less listings 
  function isApprovedForAll(address owner, address operator)
    public
    view
    override
    returns (bool)
  {
    ProxyRegistry proxyRegistry = ProxyRegistry(openSeaProxyRegistryAddress);
    if (
      isOpenSeaProxyActive && address(proxyRegistry.proxies(owner)) == operator
    ) {
      return true;
    }
    return super.isApprovedForAll(owner, operator);
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
    return (address(this), SafeMath.div(SafeMath.mul(salePrice, 10), 100));
  }
}

 // These contract definitions are used to create a reference to the OpenSea
// ProxyRegistry contract by using the registry's address (see isApprovedForAll).
contract OwnableDelegateProxy {}
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}