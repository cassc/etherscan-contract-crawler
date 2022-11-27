// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OriginsNFT is ERC721, ERC721Enumerable, Ownable {
  /// @dev Emitted when a new reference id (e.g. Toucan retirement transaction) is added
  event ReferenceIdAdded(
    uint256 index,
    string referenceId
  );

  /// @dev Emitted when the base URI is updated
  event BaseURIUpdated(
    string newBaseURI
  );

  /// @dev Emitted when the minter address is updated
  event MinterUpdated(
    address newMinter
  );

  /// @dev All reference ids
  string[] public referenceIds;

  /// @dev The base URI for token URIs
  string public baseURI = "/";

  uint256 constant public MAX_SUPPLY = 1020;
  address public minter;

  modifier onlyMinter() {
    require(msg.sender == minter, "Only minter can call");
    _;
  }

  modifier onlyMinterOrOwner() {
    require(msg.sender == minter || msg.sender == owner(), "Only minter and owner can call");
    _;
  }

  constructor(
  )
  ERC721("Origins Collection", "ORIGINS")
  {
  }

  // PUBLIC VIEWS

  /// @dev How many reference ids are there in total
  function numReferenceIds()
  external
  view
  returns (uint256)
  {
    return referenceIds.length;
  }

  // MINTER API

  /// @dev Mint the next token to address. Only callable by minter and/or owner.
  function safeMint(
    address to
  )
  external
  onlyMinterOrOwner
  returns(uint256 mintedTokenId)
  {
    uint256 numMinted = totalSupply();
    require(numMinted < MAX_SUPPLY, "Max supply already minted");
    mintedTokenId = numMinted + 1;
    _safeMint(to, mintedTokenId);
  }

  /// @dev Mint the next N token to address. Only callable by minter and/or owner.
  function safeMintMultiple(
    address to,
    uint256 numTokens
  )
  external
  onlyMinterOrOwner
  returns(uint256 lastMintedTokenId)
  {
    require(numTokens > 0, "Must mint at least one token");
    uint256 numMinted = totalSupply();
    require(numMinted + numTokens <= MAX_SUPPLY, "Insufficient supply");
    lastMintedTokenId = 0;
    for (uint256 i = 1; i <= numTokens; i++) {
      lastMintedTokenId = numMinted + i;
      _safeMint(to, lastMintedTokenId);
    }
  }

  // ADMIN API

  /// @dev Associate an external carbon credit reference id with this contract
  function addReferenceId(
    string calldata referenceId
  )
  external
  onlyOwner
  {
    referenceIds.push(referenceId);
    emit ReferenceIdAdded(
      referenceIds.length - 1,
      referenceId
    );
  }

  /// @dev Utility method to withdraw ERC20 mistakenly send to the contract
  function withdrawERC20(
    address token,
    uint256 amount
  )
  external
  onlyOwner
  {
    IERC20(token).transfer(msg.sender, amount);
  }

  /// @dev Utility method to withdraw ERC721 mistakenly sent to the contract
  function withdrawERC721(
    address token,
    uint256 tokenId,
    bytes calldata data
  )
  external
  onlyOwner
  {
    IERC721(token).safeTransferFrom(
      address(this),
      msg.sender,
      tokenId,
      data
    );
  }

  /// @dev Update the ERC721 metadata base URI
  function setBaseURI(
    string calldata newBaseURI
  )
  external
  onlyOwner
  {
    baseURI = newBaseURI;
    emit BaseURIUpdated(
      newBaseURI
    );
  }

  /// @dev Update launchpad address, in case it needs to change
  function setMinter(
    address newMinter
  )
  external
  onlyOwner
  {
    minter = newMinter;
    emit MinterUpdated(
      newMinter
    );
  }

  // Internal functions

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  // The following functions are overrides required by Solidity.

  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
  internal
  override(ERC721, ERC721Enumerable)
  {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
  public
  view
  override(ERC721, ERC721Enumerable)
  returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}