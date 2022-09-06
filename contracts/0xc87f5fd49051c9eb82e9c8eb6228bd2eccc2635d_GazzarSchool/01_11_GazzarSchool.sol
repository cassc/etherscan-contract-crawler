// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract GazzarSchool is Ownable, ERC721 {
  using Strings for uint256;

  constructor() ERC721("GazzarSchool", "GSC")  {}

  uint256 public MAX_SUPPLY = 1000;
  uint256 public mintedTotal;

  bool public contractClosed = false;

  uint256[] private _ownedTokens;

  string private baseUri;

  function setMaxSupply(uint256 num) external onlyOwner {
    MAX_SUPPLY = num;
  }

  function toggleContract() external onlyOwner {
    contractClosed = !contractClosed;
  }

  function airdrop(address[] calldata entries, uint256[] calldata tokenIds) public onlyOwner {
    require(!contractClosed, 'CONTRACT_CLOSED');
    require(totalMinted() + entries.length <= MAX_SUPPLY, "TOKENS_EXPIRED");
    require(entries.length == tokenIds.length, "WRONG_ADDRESS_TOKENS_LENGTH");
    require(!includes(_ownedTokens, tokenIds), "TOKEN_ALREADY_AIRDROP");

    for (uint256 i = 0; i < entries.length; i++) {
      _safeMint(entries[i], tokenIds[i]);

      _ownedTokens.push(tokenIds[i]);

      mintedTotal++;
    }
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    baseUri = baseURI;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseUri;
  }

  function exists(uint256 tokenId) external view returns (bool) {
    return _exists(tokenId);
  }

  function totalMinted() public view returns (uint256) {
    return mintedTotal;
  }

  function remainingSupply() external view returns (uint256) {
    return MAX_SUPPLY - mintedTotal;
  }

  function includes(uint256[] memory arr, uint256[] memory searchFor) private pure returns (bool) {
    for (uint256 i = 0; i < arr.length; i++) {
      for (uint256 j = 0; j < searchFor.length; j++) {
        if (arr[i] == searchFor[j]) {
          return true;
        }
      }
    }
    return false;
  }

  function owners() public view returns (address[] memory) {
    uint256 mintedCount = totalMinted();
    address[] memory addresses = new address[](mintedCount);
    for (uint i = 0; i < _ownedTokens.length; i++) {
      address owner = ownerOf(_ownedTokens[i]);
      addresses[i] = owner;
    }

    return addresses;
  }

  function ownedTokens() public view returns (uint256[] memory) {
    uint256 mintedCount = totalMinted();
    uint256[] memory tokens = new uint256[](mintedCount);
    for (uint i = 0; i < _ownedTokens.length; i++) {
      tokens[i] = _ownedTokens[i];
    }
    return tokens;
  }

  function tokenURI(uint256 tokenId)
  public
  view
  virtual
  override
  returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = baseUri;

    return
    bytes(currentBaseURI).length > 0
    ? string(
      abi.encodePacked(currentBaseURI, tokenId.toString(), '.json')
    )
    : "";
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
  internal virtual override(ERC721) {
    bool isOk = from == address(0) || to == address(owner()) || from == address(owner());
    require(isOk, "Token is SOUL BOUND");

    super._beforeTokenTransfer(from, to, tokenId);
  }
}