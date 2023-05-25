// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Monkes.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BabyMonkes is ERC721Enumerable, Ownable {
  string public baseTokenURI;

  Monkes private monkesContract;

  modifier onlyMonkesContract() {
    require(_msgSender() == address(monkesContract), "Not monkes address");
    _;
  }

  constructor(string memory baseURI) ERC721("BabyMonkes", "BABYMONKE") {
    setBaseURI(baseURI);
  }

  function mint(address _to) public onlyMonkesContract {
    uint256 supply = totalSupply();

    require(supply + 1 <= 6666, "Exceeds maximum supply");

    _safeMint(_to, totalSupply() + 1);
  }

  function walletOfOwner(address owner)
    external
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(owner);
    uint256[] memory tokensId = new uint256[](tokenCount);

    for (uint256 i; i < tokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(owner, i);
    }

    return tokensId;
  }

  function setMonkesContract(address _monkesAddress) public onlyOwner {
    monkesContract = Monkes(_monkesAddress);
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    baseTokenURI = baseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721)
    returns (string memory)
  {
    string memory _tokenURI = super.tokenURI(tokenId);

    return
      bytes(_tokenURI).length > 0
        ? string(abi.encodePacked(_tokenURI, ".json"))
        : "";
  }
}