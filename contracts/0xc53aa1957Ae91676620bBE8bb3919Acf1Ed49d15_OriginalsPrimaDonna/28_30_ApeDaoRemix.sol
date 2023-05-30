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

// @chrishol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ApeDaoRemix is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable, ReentrancyGuard {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdCounter;

  string public baseURI;
  string public provenanceHash;
  address public apedTokenAddress;
  uint256 public constant mintPrice = 200000000000000000; // 0.2 ETH
  uint256 public constant maximumSupply = 50 * 111; // 50 editions of 111
  uint256 public constant maximumMintLimit = 5; // Maximum 5 per transaction
  uint256[3] public apedTokensForTier;

  mapping(uint256 => uint256) internal apedTokensClaimedByToken;
  mapping(uint256 => uint8) internal tokenTier;
  mapping(address => uint256) internal amountPreMintableByAddress;
  mapping(address => uint256) internal restrictedTokensMinted;

  /* Distribution of APED Tokens */

  function claimApedTokens(uint256[] memory _tokenIds) public nonReentrant {
    require(distributionActive);
    require(_tokenIds.length <= 20, "Can only claim 20 per tx");

    uint256 totalClaimable = 0;
    for (uint8 i = 0; i < _tokenIds.length; i++) {
      require(_isApprovedOrOwner(_msgSender(), _tokenIds[i]), "Token not approved");

      uint256 amount = getClaimableApedTokens(_tokenIds[i]);
      totalClaimable += amount;
      apedTokensClaimedByToken[_tokenIds[i]] += amount;
    }

    require(totalClaimable > 0, "Nothing to claim");
    IERC20(apedTokenAddress).transfer(_msgSender(), totalClaimable); // Assumes enough APED in the contract
  }

  function getClaimableApedTokens(uint256 _tokenId) public view returns (uint256) {
    require(_exists(_tokenId), "Token not minted");

    return max(apedTokensForTier[tokenTier[_tokenId]] - apedTokensClaimedByToken[_tokenId], 0);
  }

  /* Configuration of APED Token Distribution */

  function setTokenTiers(uint256[] memory _tokenIds, uint8 _tier) public onlyOwner {
    require(_tier <= 2); // Only three possible tiers
    for (uint8 i = 0; i < _tokenIds.length; i++) {
      tokenTier[_tokenIds[i]] = _tier;
    }
  }

  bool public distributionActive = false;

  function toggleDistributionActive() public onlyOwner {
    distributionActive = !distributionActive;
  }

  /* Constructor */

  constructor(address _apeDaoContract, string memory _provenance) ERC721("APE DAO REMIX!", "APEDREMIX") {
    pause(); // Start with main sale paused

    provenanceHash = _provenance;
    apedTokenAddress = _apeDaoContract;

    apedTokensForTier[0] =  10000000000000000000; // 10 APED per basic token
    apedTokensForTier[1] =  50000000000000000000; // 50 APED per silver token
    apedTokensForTier[2] = 250000000000000000000; // 250 APED per gold token
  }

  /* Minting */

  bool public walletRestrictionActive = true;

  function toggleWalletRestrictionActive() public onlyOwner {
    walletRestrictionActive = !walletRestrictionActive;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  event ApeDaoRemixMinted(
    address account,
    uint256 tokenId
  );

  function mintApeDaoRemix(uint256 _quantity) public payable whenNotPaused nonReentrant {
    require(_tokenIdCounter.current() + _quantity <= maximumSupply, "Not enough left");
    require(_quantity <= maximumMintLimit, "Max 5 per tx");
    require(mintPrice * _quantity <= msg.value, "Not enough ETH");

    // Limit to 10 mints per address until we take the handbrake off
    if (walletRestrictionActive) {
      require(restrictedTokensMinted[_msgSender()] + _quantity <= 10, "Only 10 per address");

      restrictedTokensMinted[_msgSender()] += _quantity;
    }

    mint(_quantity);
  }

  function mint(uint256 _quantity) internal {
    for(uint8 i = 0; i < _quantity; i++) {
      _tokenIdCounter.increment(); // Increment first so that we start at token 1
      _safeMint(_msgSender(), _tokenIdCounter.current());

      emit ApeDaoRemixMinted(_msgSender(), _tokenIdCounter.current());
    }
  }

  /* Pre-Minting - For APED holders */

  bool public preMintingActive = false;

  function togglePreMintingActive() public onlyOwner {
    preMintingActive = !preMintingActive;
  }

  function preMint(uint256 _quantity) public payable nonReentrant {
    require(preMintingActive);
    require(_tokenIdCounter.current() + _quantity <= maximumSupply, "Not enough left");
    require(_quantity < amountPreMintableByAddress[_msgSender()] + 1, "Over allowance");
    require(_quantity <= maximumMintLimit, "Max 5 per tx");
    require(mintPrice * _quantity <= msg.value, "Not enough ETH");

    amountPreMintableByAddress[_msgSender()] -= _quantity;

    mint(_quantity);
  }

  function pushPreMinters(address[] memory _preMinters, uint256 _amount) public onlyOwner {
    for(uint8 i = 0; i < _preMinters.length; i++) {
      amountPreMintableByAddress[_preMinters[i]] += _amount;
    }
  }

  function getAmountPreMintable(address _userAddress) public view returns (uint256 amountPreMintable) {
    amountPreMintable = amountPreMintableByAddress[_userAddress];
  }

  /* Owner Minting - Allow a small number of pre-mints without ETH payment required */

  function ownerMint(uint256 _quantity) public onlyOwner {
    require(_tokenIdCounter.current() + _quantity <= 10);
    mint(_quantity);
  }

  /* Helpers */

  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  /* Open Zeppelin Overrides and Default Methods */

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
    _setTokenURI(_tokenId, _tokenURI);
  }

  function setBaseURI(string memory baseURI_) public onlyOwner {
    baseURI = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function withdraw() public onlyOwner {
    Address.sendValue(payable(0xCa52757875aBDFc1DDed370828DFc2bE2d4D53c4), address(this).balance * 2 / 100);
    Address.sendValue(payable(0xA7Ab7a265F274FA664187698932D3CaBb851023d), address(this).balance);
  }

  function withdrawTokens(IERC20 token) public onlyOwner {
		require(address(token) != address(0));
		token.transfer(_msgSender(), token.balanceOf(address(this)));
	}

  receive() external payable {}
}