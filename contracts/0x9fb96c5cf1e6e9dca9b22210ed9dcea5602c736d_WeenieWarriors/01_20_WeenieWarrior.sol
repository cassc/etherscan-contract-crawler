/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./ERC721A.sol";
import "./GlizzyGang.sol";
import "./Mustard.sol";

contract WeenieWarriors is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdTracker;

  GlizzyGang public glizzyGang;
  Mustard public mustard;

  string public metadataURI;
  bool public revealed;

  uint256 constant maxSupply = 3333;
  uint256 constant mustardRequired = 1000 ether;

  string internal _baseTokenURI;
  string internal _placeholderURI;

  constructor() ERC721A("Weenie Warrior", "WW") {}

  function init(
    string memory _initBaseURI,
    address glizzyGangAddress,
    address mustardAddress
  ) public onlyOwner {
    setBaseTokenURI(_initBaseURI);
    glizzyGang = GlizzyGang(glizzyGangAddress);
    mustard = Mustard(mustardAddress);
  }

  modifier onlySender() {
    require(msg.sender == tx.origin);
    _;
  }

  // reveal swtivh
  function switchReveal() public onlyOwner {
    revealed = !revealed;
  }

  function createWeenieWarriors(uint256[] memory tokenIds, uint256 mintAmount)
    public
    nonReentrant
    onlySender
  {
    require(
      tokenIds.length == 2,
      "You are sending incorrect amount of token ids"
    );
    require(
      glizzyGang.ownerOf(tokenIds[0]) == msg.sender &&
        glizzyGang.ownerOf(tokenIds[1]) == msg.sender,
      "You are not the owner of these glizzys"
    );
    require(
      mustard.balanceOf(msg.sender) >= (mustardRequired * mintAmount),
      "You Don't Have enough Mustard!"
    );
    require(
      (totalSupply() + mintAmount) <= maxSupply,
      "All Weenie Warriors Are Born"
    );

    mustard.burn(
      msg.sender,
      (mustardRequired * mintAmount)
    );
    _safeMint(msg.sender, mintAmount);
  }

  function burnAllMustard() external onlyOwner {
    mustard.burn(address(this), mustard.balanceOf(address(this)));
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

    return revealed ? ERC721A.tokenURI(tokenId) : _placeholderURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseTokenURI(string memory URI) public onlyOwner {
    _baseTokenURI = URI;
  }

  function setMetadataURI(string memory URI) public onlyOwner {
    metadataURI = URI;
  }

  function setPlaceholderURI(string memory URI) public onlyOwner {
    _placeholderURI = URI;
  }

  function walletOfOwner(address address_)
    public
    view
    virtual
    returns (uint256[] memory)
  {
    uint256 _balance = balanceOf(address_);
    uint256[] memory _tokens = new uint256[](_balance);
    uint256 _index;
    uint256 _loopThrough = totalSupply();
    for (uint256 i = 0; i < _loopThrough; i++) {
      bool _exists = _exists(i);
      if (_exists) {
        if (ownerOf(i) == address_) {
          _tokens[_index] = i;
          _index++;
        }
      } else if (!_exists && _tokens[_balance - 1] == 0) {
        _loopThrough++;
      }
    }
    return _tokens;
  }
}