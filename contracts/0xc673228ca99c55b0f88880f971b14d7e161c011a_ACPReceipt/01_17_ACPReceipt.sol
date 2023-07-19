//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//
//      _       ____              _                      ____   _
//     / \     / ___|_   _  _ __ (_)  ___   _   _  ___  |  _ \ | |  __ _   ___  ___
//    / _ \   | |   | | | || '__|| | / _ \ | | | |/ __| | |_) || | / _` | / __|/ _ \
//   / ___ \  | |___| |_| || |   | || (_) || |_| |\__ \ |  __/ | || (_| || (__|  __/
//  /_/   \_\  \____|\__,_||_|   |_| \___/  \__,_||___/ |_|    |_| \__,_| \___|\___|
//
//

import "hardhat/console.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ACPReceipt is ERC721AQueryable, Ownable, Pausable,IERC2981 {

  using ECDSA for bytes32;

  uint256 private _maxSupply = 9000;
  string private baseURI = "https://acuriousplace.xyz/metadata/receipt/";
  address private signerAddress = address(0x581253D20832e07a4714E6d8aD6aB029B766ec14);
  address private royaltyWallet = address(0x4967D8A51946E14006F0A4B7B16Be321b7f9CF4D);
  uint8 private royaltyPercent = 10;

  struct TokenMeta {
    // Meta flag to see if the data is set or not
    bool isSet;

    // The chosen drink for the token
    bytes32 drinkChoice;

    // The arrival time for the token
    bytes32 arrivalTime;

    // A unique id for this bar tab
    bytes32 barTabId;
  }

  // Mapping from discord user hash to address that minted
  mapping(bytes32 => address) private _usersMinted;

  // Mapping from tokenId to drink/arrival metadata
  mapping(uint256 => TokenMeta) private _tokenMetadata;

  constructor(uint256 maxSupply) ERC721A("ACP Receipt", "RECEIPT") {
    _maxSupply = maxSupply;
  }

  function mint(bytes32 drinkChoice, bytes32 arrivalTime, string calldata discordUser, address walletAddress, bytes calldata signature) external payable whenNotPaused {

    _verifyParams(drinkChoice, arrivalTime, discordUser, walletAddress, signature);

    _verifySender(walletAddress);

    bytes32 discordUserHash = keccak256(abi.encodePacked(discordUser));

    // Verify that this user hasn't already minted
    require(_usersMinted[discordUserHash] == address(0x0000000000000000), "Already minted");

    // Enforce max supply
    require(_totalMinted() < _maxSupply, "Supply cap hit");

    // Get the ID for the token about to be minted
    uint256 tokenId = _currentIndex;

    // Mint
    _safeMint(msg.sender, 1);

    // Mark this user as having minted
    _usersMinted[discordUserHash] = msg.sender;

    // Store the drink/arrival metadata for this token
    _tokenMetadata[tokenId].isSet = true;
    _tokenMetadata[tokenId].drinkChoice = drinkChoice;
    _tokenMetadata[tokenId].arrivalTime = arrivalTime;
    _tokenMetadata[tokenId].barTabId = discordUserHash;
  }

  // start token id at 1
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  /**
   * Verifies that the parameters passed to mint() were signed using our
   * private key (on the ACP server) thus validating the parameters.
   */
  function _verifyParams(bytes32 drinkChoice, bytes32 arrivalTime, string calldata discordUser, address walletAddress, bytes memory signature) private view {
    bytes32 messageHash = keccak256(abi.encodePacked(drinkChoice, arrivalTime, discordUser, walletAddress));
    address recoveredAddress = messageHash.toEthSignedMessageHash().recover(signature);
    if (recoveredAddress != signerAddress) {
      revert("Invalid signature");
    }
  }

  /**
   * Verifies that the wallet trying to mint matches the walletAddress passed to mint().
   * This essentially prevents front-running or replay of failed transactions by a
   * nefarious actor.
   */
  function _verifySender(address walletAddress) private view {
    if (msg.sender != walletAddress) {
      revert("Sender address does not match wallet address param");
    }
  }

  /**
   * This shouldn't need to be used since we set the metadata when minting
   * but it seemed prudent to include it in case there's a bug so we can fix it.
   */
  function setMetadata(uint256 tokenId, TokenMeta calldata tokenMeta) external onlyOwner {
    require(_currentIndex > tokenId, "Token has not been minted yet");
    _tokenMetadata[tokenId] = tokenMeta;
  }

  function getMetadata(uint256 tokenId) external view returns (TokenMeta memory) {
    return _tokenMetadata[tokenId];
  }

  function setBaseURI(string calldata newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function _baseURI() override internal view virtual returns (string memory) {
      return baseURI;
  }

  function setRoyaltyInfo(address addr, uint8 percent) external onlyOwner {
    royaltyWallet = addr;
    royaltyPercent = percent;
  }

  function royaltyInfo(uint256, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
    return (royaltyWallet, salePrice * royaltyPercent / 100);
  }

  /**
   * This gives us a way to change the signer address in the exceptional case
   * that our private key is compromised
   */
  function setSignerAddress(address addr) external onlyOwner {
    signerAddress = addr;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function withdraw(address payable recipient) public onlyOwner {
      uint256 balance = address(this).balance;
      recipient.transfer(balance);
  }
}