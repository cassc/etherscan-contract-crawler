// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

contract UGMerch is ERC721A, Ownable {
  using Strings for uint256;

  string public baseURI;
  bool public claimPeriodActive;
  uint256 public maxSupply;
  mapping(address => uint256) public redemptionAddresses;
  mapping(uint256 => bool) public blockedTokenIds;

  constructor(
    string memory name,
    string memory symbol
  ) ERC721A(name, symbol) {
    baseURI = "localhost:3000";
    claimPeriodActive = false;
    maxSupply = 1000;
    redemptionAddresses[address(0x000000000000000000000000000000000000dEaD)] = 1;
  }

  modifier isClaimPeriodActive() {
    require(
      claimPeriodActive == true,
      "Claim period is not active!"
    );
    _;
  }

  modifier isOwnerOf(uint256 tokenId) {
    require(
      ownerOf(tokenId) == msg.sender,
      "You are not the owner of this token!"
    );
    _;
  }

  modifier isRedemptionAddress(address redemptionAddress) {
    require(
      redemptionAddresses[redemptionAddress] == 1,
      "This address is not a valid redemption address!"
    );
    _;
  }

  modifier isUnblockedTokenId(uint256 tokenId) {
    require(
      blockedTokenIds[tokenId] != true,
      "This token ID is blocked!"
    );
    _;
  }

  function addRedemptionAddress(address newRedemptionAddress) public onlyOwner {
    redemptionAddresses[newRedemptionAddress] = 1;
  }

  function airdrop(address[] memory recipients) public onlyOwner {
    for (uint256 i = 0; i < recipients.length; i++) {
      _mint(recipients[i], 1);
    }
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function addBlockedTokenId(uint256 tokenId) public onlyOwner {
    blockedTokenIds[tokenId] = true;
  }

  // Create a function called redeem
  // It accepts a uint256 tokenId, checking that the caller is the owner of the token and that the claim period is active
  // It transfers the token to the redemption address
  function redeem(uint256 tokenId, address redemptionAddress)
    public
    isOwnerOf(tokenId)
    isClaimPeriodActive
    isRedemptionAddress(redemptionAddress)
    isUnblockedTokenId(tokenId)
  {
    safeTransferFrom(msg.sender, redemptionAddress, tokenId);
  }

  function removeBlockedTokenId(uint256 tokenId) public onlyOwner {
    blockedTokenIds[tokenId] = false;
  }

  function removeRedemptionAddress(address redemptionAddress) public onlyOwner {
    redemptionAddresses[redemptionAddress] = 0;
  }

  function setBaseURI(string memory newBaseURI) public onlyOwner {
    baseURI = newBaseURI;
  }

  function setClaimPeriodActive(bool active) public onlyOwner {
    claimPeriodActive = active;
  }

  // Max Supply probably doesn't matter here, I think it's likely safe to remove
  function setMaxSupply(uint256 newMaxSupply) public onlyOwner {
    require(
      newMaxSupply > totalSupply(),
      "New max supply must be greater than the current supply!"
    );
    maxSupply = newMaxSupply;
  }

  // Just in case someone sends ETH to the contract
  function withdrawMoney() external onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  // Modify ERC721A's _beforeTokenTransfers to prevent transfers to any address other than the redemption address unless it's being minted for the first time
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 tokenId,
    uint256 quantity
  ) internal virtual override {
    require(
      from == address(0) || redemptionAddresses[to] == 1,
      "This token can only be transferred to the redemption address!"
    );

    if(blockedTokenIds[tokenId] == true) {
      revert("This token ID is blocked!");
    }

    super._beforeTokenTransfers(from, to, tokenId, 1);
  }

  // Modify ERC721A's tokenURI to return just the baseURI
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    return _baseURI();
  }
}