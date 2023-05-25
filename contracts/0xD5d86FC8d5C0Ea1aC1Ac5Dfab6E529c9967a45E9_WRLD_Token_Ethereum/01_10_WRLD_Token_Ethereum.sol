// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract WRLD_Token_Ethereum is ERC20, ERC20Capped, Ownable, ReentrancyGuard {
  using ECDSA for bytes32;

  bool public claimEnabled = false;
  uint private maxClaims = 1;
  mapping(address => uint8) private claimCount;
  mapping(bytes => bool) private usedClaimSignatures;

  constructor()
  ERC20("NFT Worlds", "WRLD")
  ERC20Capped(5000000000 ether) {}

  function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount);
  }

  function claim(uint256 _amount, uint8 _claimNonce, bytes calldata _signature) external nonReentrant {
    require(verifyOwnerSignature(
      keccak256(abi.encode(msg.sender, _amount, _claimNonce)),
      _signature
    ), "Invalid Signature");

    require(claimEnabled, "Claiming is not enabled.");

    require(!usedClaimSignatures[_signature], "You have already claimed your WRLD tokens.");

    require(claimCount[msg.sender] < maxClaims, "You have already claimed the maximum amount.");

    _mint(msg.sender, _amount);

    usedClaimSignatures[_signature] = true;
    claimCount[msg.sender]++;
  }

  /**
   * Note: A second claim is scheduled for February 2022.
   * Another snapshot in February of wallets that hold at least
   * one NFT World will be eligible for the second airdrop.
   * NFT Worlds Contract: https://etherscan.io/address/0xBD4455dA5929D5639EE098ABFaa3241e9ae111Af
   */

  function enableSecondClaim() external onlyOwner {
    maxClaims = 2;
  }

  function toggleClaim(bool _claimEnabled) external onlyOwner {
    claimEnabled = _claimEnabled;
  }

  /**
   * Overrides
   */

  function _mint(address to, uint256 amount) internal override(ERC20, ERC20Capped) {
    super._mint(to, amount);
  }

  /**
   * Security
   */

  function verifyOwnerSignature(bytes32 hash, bytes memory signature) private view returns(bool) {
    return hash.toEthSignedMessageHash().recover(signature) == owner();
  }
}