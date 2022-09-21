// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract BalancePass is ERC721AQueryable, Ownable {
  /* ================== EVENTS ========================== */
  event NftMinted(address indexed user, uint256 tokenId);

  /* ================== STATE VARIABLES ================== */

  string public baseTokenURI;
  uint256 maxMint;

  bool public whitelistMintStatus;

  mapping(uint8 => uint256[][]) public tokenTypeArray;

  /* ================= INITIALIZATION =================== */
  /** 
     @notice one time initialize for the Pass Nonfungible Token
     @param _maxMint  uint256 the max number of mints on this chain
     @param _baseTokenURI string token metadata URI
     */
  constructor(
    uint256 _maxMint,
    string memory _baseTokenURI,
    bool _whitelistMintStatus
  ) ERC721A("BalancePass", "BALANCE-PASS") {
    maxMint = _maxMint;
    baseTokenURI = _baseTokenURI;
    whitelistMintStatus = _whitelistMintStatus;
  }

  /* ================ POLICY FUNCTIONS ================= */
  /** 
     @notice Set the baseTokenURI
    */
  /// @param _baseTokenURI to set
  function setBaseURI(string memory _baseTokenURI) external onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  /**
        @notice set Max mint for nft
        @param _max uint256
     */
  function setMaxMint(uint256 _max) external onlyOwner {
    maxMint = _max;
  }

  /**
        @notice set token types of token ID
        @param _tokenIdInfo uint256 2d array 
        @param _tokenType uint8 0: Platinum 1: Silver 2: Gold
     */
  function setTokenType(uint256[][] memory _tokenIdInfo, uint8 _tokenType)
    external
    onlyOwner
  {
    tokenTypeArray[_tokenType] = _tokenIdInfo;
  }

  /**
        @notice set mintstatus  true: whitelistmint false: public mint
        @param status bool
     */
  function setWhitelistMintStatus(bool status) external onlyOwner {
    whitelistMintStatus = status;
  }

  /* =============== USER FUNCTIONS ==================== */

  /**
        @notice mint whitelist user
        @param _user address
        @return tokenId uint256
     */
  function mint_whitelist_gh56gui(address _user)
    external
    payable
    returns (uint256)
  {
    require(whitelistMintStatus, "Not whitelist mint");
    require(totalSupply() <= maxMint, "BalancePass: Max limit reached");
    uint256 tokenId = _nextTokenId();

    //mint balancepass nft
    _mint(_user, 1);

    emit NftMinted(_user, tokenId);
    return tokenId;
  }

  /** 
        @notice mint whitelist user
        @param _user address
        @return tokenId uint256
     */
  function mint_public_gh56gui(address _user)
    external
    payable
    returns (uint256)
  {
    require(!whitelistMintStatus, "WhiteList mint period");
    require(totalSupply() <= maxMint, "BalancePass: Max limit reached");

    uint256 tokenId = _nextTokenId();

    //mint balancepass nft
    _mint(_user, 1);

    emit NftMinted(_user, tokenId);
    return tokenId;
  }

  /* =============== VIEW FUNCTIONS ==================== */
  /// @notice Get the base URI
  function baseURI() public view returns (string memory) {
    return baseTokenURI;
  }

  /**
     @notice return tokenURI of specific token ID
     @param tokenId uint256
     @return // string
     */
  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721A, IERC721A)
    returns (string memory)
  {
    string memory tokenURISuffix = string(
      abi.encodePacked(toString(tokenId), ".json")
    );
    string memory _tokenURI = string(
      abi.encodePacked(baseTokenURI, "/", tokenURISuffix)
    );
    return _tokenURI;
  }

  /**
        @notice return tokenTypes based on tokenId
        @param _tokenId uint256
        @return // string
     */
  function getTokenType(uint256 _tokenId) public view returns (string memory) {
    for (uint8 i = 0; i < 3; i++) {
      uint256[][] memory temp = tokenTypeArray[i];
      for (uint256 j = 0; j < temp.length; j++) {
        if (_tokenId >= temp[j][0] && _tokenId < temp[j][1])
          if (i == 0) return "Platinum";
          else if (i == 1) return "Silver";
          else return "Gold";
      }
    }
    return "Undefined";
  }

  /// @notice current Token ID
  function currentTokenId() external view returns (uint256) {
    return _nextTokenId();
  }

  /* =================== SUPPORT FUNCTION =================== */
  /**
   * @dev Converts a `uint256` to its ASCII `string` decimal representation.
   */
  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT licence
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }
}