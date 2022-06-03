// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract WokePass is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  bool public areYouWoke = false;
  bool public comingOut = false;
  uint256 constant public Wokies = 5001;
  uint256 constant public passerPerWallet = 11;
  mapping(address => uint256) public wokiesWoken;

  constructor(
  ) ERC721A("wokepass.xyz", "WOKE") {
  }

  modifier callerIsNoContract() {
    require(tx.origin == msg.sender, "Play nice Wokie!");
    _;
  }

  modifier ableToWoke() {
    require(areYouWoke, "WokeGate is closed!");
    _;
  }

  function getWoke(uint256 quantity) external nonReentrant callerIsNoContract ableToWoke
  {
    require(quantity < passerPerWallet, "Dont Snitch Them All!");
    require(totalSupply() + quantity < Wokies, "Too many Wokies!");
    require(wokiesWoken[msg.sender] + quantity < passerPerWallet, "Leave some for Greta!");
    wokiesWoken[msg.sender] += quantity;
    _safeMint(msg.sender, quantity);
  }

  function pissOffElon() public onlyOwner {
    areYouWoke = true;
  }

  function stopClimateChange() public onlyOwner {
    areYouWoke = false;
  }

  function revealPasses() public onlyOwner {
    comingOut = true;
  }

  function fundWokism() public payable onlyOwner {
	  (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		  require(success, "Who did this?");
	}

  string private _uriIdentifiesAs;

  function _baseURI() internal view virtual override returns (string memory) {
    return _uriIdentifiesAs;
  }

  function setBaseURI(string calldata newRainbow) external onlyOwner {
    _uriIdentifiesAs = newRainbow;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "Not Woke Yet!");

    string memory baseURI = _baseURI();
    string memory json = ".json";

    if(comingOut){
      return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(), json))
        : '';
    }else{
      return baseURI;
    }
  }

  function wokePassesSnitched(address _address) public view returns (uint256){
    return wokiesWoken[_address];
  }
}