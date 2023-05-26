// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IAvatar {
  function ownerOf(uint256 tokenId) external view returns (address owner);
  function tokensOfOwner(address owner) external view returns (uint256[] memory);
  function totalSupply() external view returns (uint total);
}

contract PortraitToken is ERC721URIStorage, ERC721Enumerable, Ownable, ERC721Pausable {
  using Strings for uint256;

  // ID for ERC-2981 Royalty fee standard
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  // File extension for metadata file
  string constant Extension = ".json";

  // The base domain for the tokenURI
  string private _baseTokenURI;

  // The avatar contract address
  address private _avatarContractAddr;

  // Royalty percentage fee
  uint96 private _royaltyPercent;

  // minting limit
  uint96 private _mintLimit;

  // minting paused - the tokens still can be traded
  bool private _mintPaused;

  string public constant APPLICABLE_LICENSING_TERMS = "https://nft.habbo.com/terms/";

  /**
   * name: the token's name
   * token: the token symbol
   * baseTokenURI: the base domain for each token URI
   * limit: the maximum number of profile pictures can be minted
   */
  constructor(string memory name, string memory token, string memory baseTokenURI, address avatarContractAddr) ERC721(name, token) {
    _baseTokenURI = baseTokenURI;
    _avatarContractAddr = avatarContractAddr;

    // initial default values
    _royaltyPercent = 500;
    _mintLimit = 100;
    _mintPaused = false;
  }

  /** Return the mintable tokens for the user */
  function getMintableTokens() public view returns (uint[] memory tokens) {
    IAvatar avatar = IAvatar(_avatarContractAddr);
    uint256[] memory ownerTokens = avatar.tokensOfOwner(msg.sender);
    uint size = ownerTokens.length;

    // calculate the length of non-exist tokens
    for (uint i = 0; i < ownerTokens.length; i++) {
      if (_exists(ownerTokens[i])) {
        size--;
      }
    }

    uint[] memory mintableTokens = new uint[](size);
    uint j = 0;

    for (uint i = 0; i < ownerTokens.length; i++) {
      if (!_exists(ownerTokens[i])) {
        mintableTokens[j++] = ownerTokens[i];
      }
    }

    return mintableTokens;
  }

  /** Check if a profile picture can be mint */
  function isMintable(uint tokenId) public view returns (bool mintable) {
    IAvatar avatar = IAvatar(_avatarContractAddr);
    uint tokenLimit = avatar.totalSupply();

    return tokenId > 0 && tokenId <= tokenLimit && !_exists(tokenId);
  }

  /** Mint a profile picture with tokenId */
  function mintPFP(uint tokenId) public {
    require(!paused(), "Token mint while paused");
    require(!_mintPaused, "Token minting is paused");
    IAvatar avatar = IAvatar(_avatarContractAddr);

    // this ensures token does exist
    address tokenOwner = avatar.ownerOf(tokenId);

    // only token owner can mint this and token is not minted
    require(!_exists(tokenId), "Token was minted");
    require(msg.sender == tokenOwner, "Not the token owner");

    _mintToken(msg.sender, tokenId);
  }

  /** Mint all profile pictures that mintable to the user */
  function mintAllPFP(uint limit) public {
    require(!paused(), "Token mint while paused");
    require(!_mintPaused, "Token minting is paused");
    require(limit <= _mintLimit, "Limit exceed");
    IAvatar avatar = IAvatar(_avatarContractAddr);

    // owner's tokens
    uint256[] memory tokens = avatar.tokensOfOwner(msg.sender);
    uint len = tokens.length;
    uint count = 0;

    for (uint i = 0; i < len; i++) {
      uint tokenId = tokens[i];

      // only mint new token
      if (!_exists(tokenId) && count < limit) {
        _mintToken(msg.sender, tokenId);
        count++;
      }
    }
  }

  function _mintToken(address user, uint tokenId) internal {
    _safeMint(user, tokenId);
    _setTokenURI(tokenId, string(abi.encodePacked(tokenId.toString(), Extension)));
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Pausable, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
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

  /// ONLY OWNER FUNCTIONS ///

  // Withdraw all money to sender's account, only owner can call this
  function withdrawMoney() public onlyOwner {
    address payable to = payable(msg.sender);
    to.transfer(address(this).balance);
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

  // Get the current royalty fee
  function getRoyaltyPercent() public view onlyOwner returns (uint) {
    return _royaltyPercent;
  }

  // Update the base URI for token
  function updateBaseTokenURI(string memory baseTokenURI) public onlyOwner {
    _baseTokenURI = baseTokenURI;
  }

  // Update the royalty fee
  function updateRoyaltyPercent(uint96 royaltyPercent) public onlyOwner {
    _royaltyPercent = royaltyPercent;
  }

  // Update the minting limit
  function updateMintLimit(uint96 limit) public onlyOwner {
    _mintLimit = limit;
  }

  function setMintPaused(bool paused) public onlyOwner {
    _mintPaused = paused;
  }

  function isMintPaused() public view onlyOwner returns (bool) {
    return _mintPaused;
  }

  function applicableLicensingTerms() public pure returns (string memory) {
    return APPLICABLE_LICENSING_TERMS;
  }
}