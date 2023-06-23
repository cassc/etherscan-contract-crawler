// SPDX-License-Identifier: None
pragma solidity 0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

interface ICryptoPills {
  function balanceOf(address owner) external view returns (uint256 balance);
}

contract CryptoPillsAnthem is ERC1155, Ownable {
  bool public mintActive;
  ICryptoPills public CryptoPills =
    ICryptoPills(0x7DD04448c6CD405345D03529Bff9749fd89F8F4F);
  mapping(address => bool) public walletHasClaimed;

  constructor()
    ERC1155("ipfs://QmY8d97yae4cCqCyaD2E68fJa46TvfKTCC5K2UYhRQBenz")
  {}

  function mint() external {
    require(mintActive, "Mint not active");
    require(!walletHasClaimed[msg.sender], "Already claimed");
    require(CryptoPills.balanceOf(msg.sender) > 0, "Must own Crypto Pill");

    walletHasClaimed[msg.sender] = true;

    _mint(msg.sender, 1, 1, "");
  }

  /// @dev Allows the contract owner to enable/disable minting
  function toggleMintActive() external onlyOwner {
    mintActive = !mintActive;
  }
}