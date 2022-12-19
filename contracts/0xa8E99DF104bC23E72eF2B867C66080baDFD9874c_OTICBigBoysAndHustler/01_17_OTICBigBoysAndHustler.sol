// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./AirdropHustler.sol";
import "./AirdropBigBoys.sol";

contract OTICBigBoysAndHustler is
  ERC721Enumerable,
  Ownable,
  AirdropHustler,
  AirdropBigBoys
{
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private _hustlerTokenIds;
  Counters.Counter private _bigBoysTokenIds;

  string public baseTokenURI;
  uint256 public maxSupply = 93;
  uint256 public bigBoysSupply = 7;
  uint256 public hustlerSupply = 86;

  constructor(string memory baseURI)
    ERC721("OTIC Big Boys And Hustler", "OTIC-BigBoysAndHustler")
  {
    setBaseURI(baseURI);
    for (uint256 i = 0; i < bigBoysSupply; i++) {
      _hustlerTokenIds.increment();
    }
  }

  function setBaseURI(string memory _baseTokenURI) public onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(_tokenId), "Token is not exist");

    string memory currentBaseURI = _baseURI();
    return
      bytes(currentBaseURI).length > 0
        ? string(
          abi.encodePacked(currentBaseURI, Strings.toString(_tokenId), ".json")
        )
        : "";
  }

  /** Administrators */
  function updateSupplyHustler(uint256 _supply) public onlyOwner {
    uint256 current = _hustlerTokenIds.current();
    require(_supply >= current, "supply must greater than current");
    hustlerSupply = _supply;
  }

  function updateSupplyBigBoys(uint256 _supply) public onlyOwner {
    uint256 current = _bigBoysTokenIds.current();
    require(_supply >= current, "supply must greater than current");
    bigBoysSupply = _supply;
  }

  function mintNftHustler(address addr) private {
    uint256 currentTokenId = _hustlerTokenIds.current();
    require(currentTokenId < hustlerSupply, "NFT run out of supply!");
    _safeMint(addr, currentTokenId);
    _hustlerTokenIds.increment();
  }

  function mintNftBigBoys(address addr) private {
    uint256 currentTokenId = _bigBoysTokenIds.current();
    require(currentTokenId < bigBoysSupply, "NFT run out of supply!");
    _safeMint(addr, currentTokenId);
    _bigBoysTokenIds.increment();
  }

  function distributeAirdropHustler() public onlyOwner {
    for (uint256 i = 0; i < addressesForAirdropHustler.length; i++) {
      address addr = addressesForAirdropHustler[i];
      if (
        addressToAllowedAirdropHustler[addr] &&
        !addressHasReceiveAirdropHustler[addr]
      ) {
        uint256 qty = addressToAllowedAirdropQtyHustler[addr];
        for (uint256 i = 0; i < qty; i++) {
          mintNftHustler(addr);
        }
        addressHasReceiveAirdropHustler[addr] = true;
        addressToAllowedAirdropQtyHustler[addr] = 0;
      }
    }
  }

  function distributeAirdropBigBoys() public onlyOwner {
    for (uint256 i = 0; i < addressesForAirdropBigBoys.length; i++) {
      address addr = addressesForAirdropBigBoys[i];
      if (
        addressToAllowedAirdropBigBoys[addr] &&
        !addressHasReceiveAirdropBigBoys[addr]
      ) {
        uint256 qty = addressToAllowedAirdropQtyBigBoys[addr];
        for (uint256 i = 0; i < qty; i++) {
          mintNftBigBoys(addr);
        }
        addressHasReceiveAirdropBigBoys[addr] = true;
        addressToAllowedAirdropQtyBigBoys[addr] = 0;
      }
    }
  }

  /**
   * @notice Get a list of token id owned
   * @param _owner the address of the token owner
   * @return array of token id
   */
  function tokensOfOwner(address _owner)
    external
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](tokenCount);
    for (uint256 i = 0; i < tokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }

    return tokenIds;
  }
}