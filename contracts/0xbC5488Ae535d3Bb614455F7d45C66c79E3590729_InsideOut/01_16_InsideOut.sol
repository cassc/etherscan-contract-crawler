/**
	░░░░██╗░░░░██╗  ██╗███╗░░██╗░██████╗██╗██████╗░███████╗  ░█████╗░██╗░░░██╗████████╗
	░░░██╔╝░░░██╔╝  ██║████╗░██║██╔════╝██║██╔══██╗██╔════╝  ██╔══██╗██║░░░██║╚══██╔══╝
	░░██╔╝░░░██╔╝░  ██║██╔██╗██║╚█████╗░██║██║░░██║█████╗░░  ██║░░██║██║░░░██║░░░██║░░░
	░██╔╝░░░██╔╝░░  ██║██║╚████║░╚═══██╗██║██║░░██║██╔══╝░░  ██║░░██║██║░░░██║░░░██║░░░
	██╔╝░░░██╔╝░░░  ██║██║░╚███║██████╔╝██║██████╔╝███████╗  ╚█████╔╝╚██████╔╝░░░██║░░░
	╚═╝░░░░╚═╝░░░░  ╚═╝╚═╝░░╚══╝╚═════╝░╚═╝╚═════╝░╚══════╝  ░╚════╝░░╚═════╝░░░░╚═╝░░░
**/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./InsideOutInterface.sol";

/**
 * @dev Errors thrown by this contract.
 */
error MintingIsPaused();
error InsufficientBalance();
error SoldOut();

contract InsideOut is InsideOutInterface {
  using Counters for Counters.Counter;

  /**
   * @dev The number of tokens that have been sold.
   */
  Counters.Counter private _totalSupply;

  /**
   * @dev The number of tokens that can be sold.
   */
  uint256 public constant MAX_SUPPLY = 5555;

  bool public isPaused = false;
  uint256 public mintPrice = 0 ether;

  constructor(string memory _initBaseURI)
    payable
    InsideOutInterface(_initBaseURI)
  {}

  /**
   * @dev Main minting function.
   */
  function mintIO() internal {
    _totalSupply.increment();
    uint256 tokenId = _totalSupply.current();
    _safeMint(msg.sender, tokenId);
  }

  /**
   * @dev Mints InsideOut Token
   */
  function mint() external payable {
    if (isPaused) {
      revert MintingIsPaused();
    }

    if (_totalSupply.current() > MAX_SUPPLY) {
      revert SoldOut();
    }

    if (msg.sender == owner()) {
      mintIO();
      return;
    }

    if (msg.value < mintPrice) {
      revert InsufficientBalance();
    }

    require(
      balanceOf(msg.sender) == 0,
      "ERC721: Can only mint one NFT at time!"
    );

    mintIO();
  }

  // @dev Below are the functions that can only be called by the owner.

  /**
   * @dev Updates the minting price.
   * @param _newMintPrice The new price.
   */
  function updateMintPrice(uint256 _newMintPrice) external onlyOwner {
    mintPrice = _newMintPrice;
  }

  /**
   * @dev Pauses the minting.
   * @param _paused True if the minting should be paused.
   */
  function setPaused(bool _paused) external onlyOwner {
    isPaused = _paused;
  }

  /**
   * @dev Sets the base URI to whatever the owner wants.
   * @param _newBaseURI The new base URI.
   */
  function setBaseURI(string memory _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;
  }

  /**
   * @dev Withdraws the funds from the contract. And will be used to
   * fulfill the roadmap and future updates.
   */
  function withdrawFunds() external payable onlyOwner {
    (bool os, ) = payable(address(0xF83C26B36f0a64aD1444f932D3145E8cd8396bE2))
      .call{value: address(this).balance}("");
    require(os);
  }
}