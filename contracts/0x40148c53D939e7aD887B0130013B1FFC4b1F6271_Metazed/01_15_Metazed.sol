// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "./roles/AccessOperatable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Metazed is ERC721A, AccessOperatable, Ownable {
  string baseURI;
  string public baseExtension = "";
  using Strings for uint256;

  uint256 public constant MAX_ELEMENTS = 3333;

  constructor() ERC721A("Metazed", "ISM") {
    baseURI = "https://gateway.pinata.cloud/ipfs/bafybeiaofstokz7i7dmtuw6hslsyzpge4e4bqnglkqjn5oeyrnsob5c264/";
  }

  function mint(address to, uint256 quantity) external onlyOperator {
    require(totalSupply() <= MAX_ELEMENTS, "Exceed Max Elements");
    _safeMint(to, quantity);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  // public
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      ERC721A._exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return
      bytes(currentBaseURI).length > 0
        ? string(
          abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)
        )
        : "";
  }

  function setBaseURI(string memory _newBaseURI) public onlyOperator {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension)
    public
    onlyOperator
  {
    baseExtension = _newBaseExtension;
  }

  function withdraw(address withdrawAddress) public onlyOperator {
    uint256 balance = address(this).balance;
    require(balance > 0);
    (bool success, ) = withdrawAddress.call{ value: address(this).balance }("");
    require(success, "Transfer failed.");
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721A, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}