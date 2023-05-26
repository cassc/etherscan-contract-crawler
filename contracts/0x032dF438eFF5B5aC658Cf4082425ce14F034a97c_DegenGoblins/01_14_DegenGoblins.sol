// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./extensions/ERC721ABurnable.sol";       

//   ▄████  ▒█████   ▄▄▄▄    ██▓     ██▓ ███▄    █   ██████ 
//  ██▒ ▀█▒▒██▒  ██▒▓█████▄ ▓██▒    ▓██▒ ██ ▀█   █ ▒██    ▒ 
// ▒██░▄▄▄░▒██░  ██▒▒██▒ ▄██▒██░    ▒██▒▓██  ▀█ ██▒░ ▓██▄   
// ░▓█  ██▓▒██   ██░▒██░█▀  ▒██░    ░██░▓██▒  ▐▌██▒  ▒   ██▒
// ░▒▓███▀▒░ ████▓▒░░▓█  ▀█▓░██████▒░██░▒██░   ▓██░▒██████▒▒
//  ░▒   ▒ ░ ▒░▒░▒░ ░▒▓███▀▒░ ▒░▓  ░░▓  ░ ▒░   ▒ ▒ ▒ ▒▓▒ ▒ ░
//   ░   ░   ░ ▒ ▒░ ▒░▒   ░ ░ ░ ▒  ░ ▒ ░░ ░░   ░ ▒░░ ░▒  ░ ░
// ░ ░   ░ ░ ░ ░ ▒   ░    ░   ░ ░    ▒ ░   ░   ░ ░ ░  ░  ░  
//       ░     ░ ░   ░          ░  ░ ░           ░       ░  
//                        ░                                 

contract DegenGoblins is ERC721ABurnable, Ownable, ReentrancyGuard {
  string public _baseTokenURI;
  uint256 public _currentStageMaxMint;
  bool public _isMintLive;

  constructor() ERC721A("Degen Goblins", "DG") {
    _currentStageMaxMint = 1000;
    _isMintLive = false;

    // Team mint sir 
    _safeMint(0x43107a5211852fB3a3B09CD1d84BF2559E229e05, 25);
    _safeMint(0x2B3148aA03B4013C4A23f941BF99A4F289b9FBab, 25);
    _safeMint(0xedF82E744126129433D0A04a63876846dccf15F1, 25);
    _safeMint(0x42aBbE61e17444524FE604A47F53Dfcc3C98c528, 25);
    _safeMint(0x0a68802B712e0261e27ac81FA39656677f136Ae1, 25);

  }

  function _joinGoblinTown(address to, uint256 quantity) private {
    require(totalSupply() + quantity <= 6969, "All goblins have been minted.");
    require(numberMinted(msg.sender) < 2, "Max 2 mint per wallet.");
    _safeMint(to, quantity);
  }

  function mint() external payable {
    require( 
      totalSupply() + 1 <= _currentStageMaxMint && _isMintLive, 
      "Mint is not live."
    );
    _joinGoblinTown(msg.sender, 1);
  }

  function vaultMint() external onlyOwner {
    // one time goblins vault mint 
    _joinGoblinTown(0xedF82E744126129433D0A04a63876846dccf15F1, 200);
  }


  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function setCurrentStageMax(uint256 max) external onlyOwner {
    _currentStageMaxMint = max;
  }

  function setIsMintLive(bool state) external onlyOwner {
    _isMintLive = state;
  }

  function aidrop(address airdropAddress, uint256 quantity) external onlyOwner {
    _joinGoblinTown(airdropAddress, quantity);
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
}