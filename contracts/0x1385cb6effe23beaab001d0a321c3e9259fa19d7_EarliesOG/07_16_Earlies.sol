// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./extensions/ERC721ABurnable.sol";
/*
 * @title Earlies Society ERC721A Non-Fungible Token
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 * ███████╗ █████╗ ██████╗ ██╗     ██╗███████╗███████╗
 * ██╔════╝██╔══██╗██╔══██╗██║     ██║██╔════╝██╔════╝
 * █████╗  ███████║██████╔╝██║     ██║█████╗  ███████╗
 * ██╔══╝  ██╔══██║██╔══██╗██║     ██║██╔══╝  ╚════██║
 * ███████╗██║  ██║██║  ██║███████╗██║███████╗███████║
 * ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚══════╝╚══════╝
*/
                                                   

contract Earlies is ERC721ABurnable, Ownable, ReentrancyGuard {
  uint256 public constant price = 120000000000000000; 


  
  // // metadata URI
  uint256 private mintPerWallet = 14;
  uint256 public maxSupply = 9999;

  mapping(address => bool) private whitelistedOrRaffledAddresses;
  string public _baseTokenURI;
  bool public isMintLive = false;
  bool public isPublicMintLive = false;

  modifier isWhitelistedOrRaffled(address _address) {
    require(whitelistedOrRaffledAddresses[_address], "Sorry you need to be whitelisted or raffled. Public mint is not open yet.");
    _;
  }

  constructor() ERC721A("TES - Founder Cards", "TESFC") {}

  function mint(uint256 quantity) external payable isWhitelistedOrRaffled(msg.sender) {
    require(isMintLive, "Minting is not currently live.");
    require(quantity <= mintPerWallet, "You are not allowed to mint more than 14 NFTs per wallet.");
    require(
      numberMinted(msg.sender) + quantity <= mintPerWallet,
      "You are not allowed to mint more than 14 NFTs per wallet."
    );
    require(totalSupply() + quantity <= maxSupply, "There are not enough NFTs left to mint the desired amount.");
    
    require(price * quantity <= msg.value, "Not enough ETH sent.");
    _safeMint(msg.sender, quantity);
  }

  function publicMint(uint256 quantity) external payable {
    require(isMintLive, "Minting is not currently live.");
    require(isPublicMintLive, "Public mint is not currently live.");
    require(quantity <= mintPerWallet, "You are not allowed to mint more than 14 NFTs per wallet.");
    require(
      numberMinted(msg.sender) + quantity <= mintPerWallet,
      "You are not allowed to mint more than 14 NFTs per wallet."
    );
    require(totalSupply() + quantity <= maxSupply, "There are not enough NFTs left to mint the desired amount.");
    
    require(price * quantity <= msg.value, "Not enough ETH sent.");
    _safeMint(msg.sender, quantity);
  }


  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function setMintStatus(bool status) external onlyOwner {
    isMintLive = status;
  }

  function setPublicMintStatus(bool status) external onlyOwner {
    isPublicMintLive = status;
  }

  function setMintPerWallet(uint256 amount) external onlyOwner {
    mintPerWallet = amount;
  }

  function setMaxSupply(uint256 amount) external onlyOwner {
    maxSupply = amount;
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

  struct TeamMint {
    uint256 amount;
    address teamAddress;
  }
  // Team, Engineers, Artists, Marketing, Ecc...
  function teamMint(TeamMint[] memory teamMintData) external onlyOwner {
    for (uint256 i = 0; i < teamMintData.length; i++) {
      require(totalSupply() + teamMintData[i].amount <= maxSupply, "Not enough NFTs left to mint the desired amount.");
      _safeMint(teamMintData[i].teamAddress, teamMintData[i].amount);
    }
  }

  function seedWhitelistAndRaffle(address[] memory addresses) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      whitelistedOrRaffledAddresses[addresses[i]] = true;
    }
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
}