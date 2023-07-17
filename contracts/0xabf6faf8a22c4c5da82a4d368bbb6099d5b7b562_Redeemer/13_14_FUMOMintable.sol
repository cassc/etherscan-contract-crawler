// SPDX-License-Identifier: AGPL-3.0-only+VPL
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*
  It saves bytecode to revert on custom errors instead of using require
  statements. We are just declaring these errors for reverting with upon various
  conditions later in this contract.
*/
error SenderIsNotMinter ();
error MintingPermanentlyLocked ();
error MinterPermanentlyLocked ();
error BaseURIPermanentlyLocked ();

/**
  @custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
  @title A contract for minting new FUMO tokens.
  @author cheb <evmcheb.eth>
  @author Tim Clancy <tim-clancy.eth>
  
  This token contract allows for privileged callers to mint new FUMO.

  @custom:date Jun 28th, 2023
*/
contract FUMOMintable is ERC721, Ownable {
  using Strings for uint256;

  /// The current tokenId
  uint256 public nextTokenId = 1;

  /// The base URI for all tokens
  string public __baseURI;

  /// The permissioned minter (FUMO redemption contract).
  address public minter;

  /// Whether minting is permanently locked.
  bool public mintLocked;

  /// Whether the minting address is permanently locked
  bool public minterLocked;

  /// Whether the base URI is permanently locked.
  bool public baseURILocked;

  /**
    Construct a new instance of the FUMO ERC-721 token.

    @param _minter The initial address permitted to mint.
  */
  constructor (
    address _minter
  ) ERC721("FUMO NFT", "FUMO") {
    minter = _minter;
  }

  /**
    Return the token metadata URI for the specific token `_tokenId`.

    @param _tokenId The ID of the token to retrive a metadata URI for.

    @return result The completed token URI.
  */
  function tokenURI (
    uint256 _tokenId
  ) public view virtual override returns (string memory result) {
    result = __baseURI;
    if (bytes(result).length != 0) {
      result = string(abi.encodePacked(__baseURI, _tokenId.toString()));
    }
  }

  /**
    Returns whether `tokenId` exists.

    @param _tokenId The ID of the token to check existence for.

    @return _ Whether or not the token `_tokenId` exists.
  */
  function exists (
    uint256 _tokenId
  ) external view returns (bool) {
    return _ownerOf(_tokenId) != address(0);
  }

  /**
   * @dev Returns if the `tokenIds` exist.
   */
  function exist(uint256[] memory tokenIds) external view returns (bool[] memory results) {
      uint256 n = tokenIds.length;
      results = new bool[](n);
      for (uint256 i; i < n; ++i) {
          results[i] = _ownerOf(tokenIds[i]) != address(0);
      }
  }

  /**
    A permissioned minting function. This function may only be called by the
    admin-specified minter.

    @param _to The recipient of the minted item.
  */
  function mint (
    address _to
  ) public {
    if (msg.sender != minter) { revert SenderIsNotMinter(); }
    if (mintLocked) { revert MintingPermanentlyLocked(); }
    _safeMint(_to, nextTokenId);
    nextTokenId += 1;
  }

  /**
    Allow the administrator to set the minter.
  */
  function setMinter (
    address _minter
  ) external onlyOwner {
    if (minterLocked) { revert MinterPermanentlyLocked(); }
    minter = _minter;
  }

  /**
    Allow the admin to set the base URI.
  */
  function setBaseURI (
    string memory _baseURI
  ) external onlyOwner {
    if (baseURILocked) { revert BaseURIPermanentlyLocked(); }
    __baseURI = _baseURI;
  }

  /**
    Permanently lock the minter from being changed.
  */
  function lockMinter() external onlyOwner {
    minterLocked = true;
  }

  /**
    Permanently lock minting.
  */
  function lockMint() external onlyOwner {
    mintLocked = true;
  }

  /**
    Permanently lock the base URI.
  */
  function lockBaseURI() external onlyOwner {
    baseURILocked = true;
  }
}