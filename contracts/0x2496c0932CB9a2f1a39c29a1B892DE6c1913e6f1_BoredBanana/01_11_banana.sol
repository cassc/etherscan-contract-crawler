// SPDX-License-Identifier: None
// twitter: @BoredBananaNFT

pragma solidity ^0.8.4;

import "./libs/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**********************************************
 * There are only 9876 bored bananas
 * Maybe the Bored Ape like it
 * buy it, sell it, or eat it
 **********************************************/

contract BoredBanana is ERC721A, Ownable {
  using Strings for uint256;
  uint256 constant MINT_PRICE = 0.01 ether;
  uint256 constant MAX_SUPPLY = 9876;
  uint256 constant MAX_PER_TRANSACTION = 10;

  bool public paused = true;

  string tokenBaseUri;
  string tokenEatenBaseUri;

  mapping(uint256 => bool) private _eaten;

  constructor() ERC721A("BoredBanana", "BB") {
  }

  function mint(uint256 _quantity) external payable {
    require(!paused, "minting is paused");

    uint256 _totalSupply = totalSupply();

    require(_totalSupply + _quantity <= MAX_SUPPLY, "max supply exceeded");
    require(_quantity <= MAX_PER_TRANSACTION, "max per tx exceed");
    require(msg.value >= _quantity * MINT_PRICE, "0.01 ether for each banana");

    _safeMint(msg.sender, _quantity);
  }

  function isEaten(uint id) external view returns (bool) {
    return _eaten[id];
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view override returns (string memory) {
    return tokenBaseUri;
  }
  function _baseURIEaten() internal view returns (string memory) {
    return tokenEatenBaseUri;
  }

  function setBaseURI(string calldata _newBaseUri) external onlyOwner {
    tokenBaseUri = _newBaseUri;
  }
  function setEatenBaseURI(string calldata _newEatenBaseUri) external onlyOwner {
    tokenEatenBaseUri = _newEatenBaseUri;
  }
  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    if(_eaten[tokenId] == false){
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    } else {
        string memory baseURI = _baseURIEaten();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }
  }

  function flipSale() external onlyOwner {
    paused = !paused;
  }

  function ownerMint() external onlyOwner {
    require(totalSupply() == 0, "already minted");

    _safeMint(msg.sender, 10);
  }

  function withdraw() external onlyOwner {
    require(
      payable(owner()).send(address(this).balance),
      "withdraw ether"
    );
  }
  function eat(uint id) external {
      require(ownerOf(id) == msg.sender, "only the banana owner can eat it");
      _eaten[id] = true;
  }
}