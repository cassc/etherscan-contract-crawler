//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./DogeXInterface.sol";

contract DOGEXJR is ERC721Enumerable, Ownable {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIdTracker;

  uint256 public constant MAX_SUPPLY = 10000;
  mapping(uint256 => uint256) public dogesUsed;

  string public baseTokenURI;

  DogeXInterface public dogeX;

  constructor(string memory _URI, address _dogeX) ERC721("DOGEXJR", "DOGEXJR") {
    setBaseURI(_URI);
    setDogeX(_dogeX);
  }

  function claim(uint256[] memory _tokenIds) public payable {
    uint256 total = _totalSupply();
    require(
      total.add(_tokenIds.length) <= MAX_SUPPLY,
      "DOGEXJR: Max supply is minted!"
    );
    require(total <= MAX_SUPPLY, "DOGEXJR: Max supply is minted!");
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      uint256 _tokenId = _tokenIds[i];
      require(
        dogeX.ownerOf(_tokenId) == msg.sender,
        "DOGEXJR: You don't own the doge you are trying to claim!"
      );
      require(dogesUsed[_tokenId] == 0, "DOGEXJR: Doge is already claimed!");
      dogesUsed[_tokenId] = 1;
      _mintAnElement(msg.sender);
    }
  }

  function _mintAnElement(address _to) private {
    _tokenIdTracker.increment();
    _safeMint(_to, _tokenIdTracker.current());
  }

  function _totalSupply() internal view returns (uint256) {
    return _tokenIdTracker.current();
  }

  function totalMint() public view returns (uint256) {
    return _totalSupply();
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    baseTokenURI = baseURI;
  }

  function setDogeX(address _dogeX) public onlyOwner {
    dogeX = DogeXInterface(_dogeX);
  }

  function walletOfOwner(address _owner)
    external
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(_owner);

    uint256[] memory tokensId = new uint256[](tokenCount);
    for (uint256 i = 0; i < tokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }

    return tokensId;
  }

  function isUsed(uint tokenId) external view returns (uint) {
    return dogesUsed[tokenId];
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)),
          ".json"
        )
      );
  }
}