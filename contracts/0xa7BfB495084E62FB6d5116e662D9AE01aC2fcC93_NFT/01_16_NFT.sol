// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";

contract NFT is ERC721, ERC2981, Ownable, PullPayment {
// ---------------------------------------------------
//    _____              __                     _      
//   / ____|            / _|                   (_)     
//  | (___  _   _ _ __ | |_ ___  _ __ _ __ ___  _  ___ 
//   \___ \| | | | '_ \|  _/ _ \| '__| '_ ` _ \| |/ __|
//   ____) | |_| | | | | || (_) | |  | | | | | | | (__ 
//  |_____/ \__, |_| |_|_| \___/|_|  |_| |_| |_|_|\___|
//           __/ |                                     
//          |___/                                      
// ---------------------------------------------------
//   _    _     _              ___     _ _          _ 
//  | |  (_)_ _(_)_ _  __ _   / __|___| | |___ __ _/ |
//  | |__| \ V / | ' \/ _` | | (__/ -_) | (_-< \ V / |
//  |____|_|\_/|_|_||_\__, |  \___\___|_|_/__/  \_/|_|
//                    |___/                           
// ---------------------------------------------------

  using Counters for Counters.Counter;

  bytes public constant NFT_PROVENANCE = hex"734f9cf247dc1ee31e21c08600e3f586a011d0a2c9109fa95f4bf03175007e32";
  uint256 public constant TOTAL_SUPPLY = 80;
  // The price doubles with each 10 tokens minted.
  uint256 public constant BASE_PRICE = 0.01 ether;  

  Counters.Counter private currentTokenId;

  /// @dev Base token URI used as a prefix by tokenURI().
  string public baseTokenURI;
  bool public baseTokenURIFrozen = false;

  /// @dev The string for the contract metadata URI returned by contractURI().
  string public contractMetadataURI;

  constructor(uint96 feeNumerator, string memory _baseTokenURI, string memory _contractMetadataURI, address[] memory initialMint) ERC721("Living Cells Original", "LC") {
    // Set initial data from constructor
    setRoyaltyInfo(msg.sender, feeNumerator);
    baseTokenURI = _baseTokenURI;
    contractMetadataURI = _contractMetadataURI;

    // Mint first n tokens to specific addresses
    require(initialMint.length < TOTAL_SUPPLY, "Can not execute initial mint more than supply");
    for (uint256 index = 0; index < initialMint.length; index++) {
      currentTokenId.increment();
      uint256 newItemId = currentTokenId.current();
      _safeMint(initialMint[index], newItemId);
    }
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool){
    return super.supportsInterface(interfaceId);
  }

  function contractURI() public view returns (string memory) {
    return contractMetadataURI;
  }

  function tokenPrice(uint256 tokenId) public pure returns (uint256) {
    return BASE_PRICE * (2 ** ((tokenId-1)/10));
  }

  function nextTokenId() public view returns (uint256) {
    return currentTokenId.current() + 1;
  }

  function mintTo(address recipient) public payable returns (uint256) {
    uint256 tokenId = currentTokenId.current();
    require(tokenId < TOTAL_SUPPLY, "Max supply reached");
    require(msg.value >= tokenPrice(tokenId+1), "Transaction value did not meet the mint price");

    currentTokenId.increment();
    uint256 newItemId = currentTokenId.current();
    _safeMint(recipient, newItemId);
    return newItemId;
  }

  /// @dev Returns the base URI, overriding to return baseTokenURI
  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  /// @dev Sets the base token URI prefix.
  function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
    require(!baseTokenURIFrozen, "Base token URI frozen, no longer editable");
    baseTokenURI = _baseTokenURI;
  }

  /// @dev Set the royalty infomation
  function setRoyaltyInfo(address receiver, uint96 feeNumerator) public onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  /// @dev Sets the contract metadata URI.
  function setContractURI(string memory _contractMetadataURI) public onlyOwner {
    contractMetadataURI = _contractMetadataURI;
  }

  /// @dev Freezes the base token URI making it immutable even by the owner.
  function freezeBaseTokenURI() public onlyOwner {
    baseTokenURIFrozen = true;
  }

  /// @dev Overridden in order to make it an onlyOwner function
  function withdrawPayments(address payable payee) public override onlyOwner virtual {
      super.withdrawPayments(payee);
  }
}