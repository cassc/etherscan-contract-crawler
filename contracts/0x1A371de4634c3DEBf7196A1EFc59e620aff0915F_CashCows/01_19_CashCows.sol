// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//-------------------------------------------------------------------------------------------
//
//   /$$$$$$                      /$$              /$$$$$$                                   
//  /$$__  $$                    | $$             /$$__  $$                                  
// | $$  \__/  /$$$$$$   /$$$$$$$| $$$$$$$       | $$  \__/  /$$$$$$  /$$  /$$  /$$  /$$$$$$$
// | $$       |____  $$ /$$_____/| $$__  $$      | $$       /$$__  $$| $$ | $$ | $$ /$$_____/
// | $$        /$$$$$$$|  $$$$$$ | $$  \ $$      | $$      | $$  \ $$| $$ | $$ | $$|  $$$$$$ 
// | $$    $$ /$$__  $$ \____  $$| $$  | $$      | $$    $$| $$  | $$| $$ | $$ | $$ \____  $$
// |  $$$$$$/|  $$$$$$$ /$$$$$$$/| $$  | $$      |  $$$$$$/|  $$$$$$/|  $$$$$/$$$$/ /$$$$$$$/
//  \______/  \_______/|_______/ |__/  |__/       \______/  \______/  \_____/\___/ |_______/
//
//-------------------------------------------------------------------------------------------
//
// Moo.

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./CashCowsAbstract.sol";

/**
 * @dev Specifics of the Cash Cows collection
 */
contract CashCows is ReentrancyGuard, CashCowsAbstract { 
  // ============ Constants ============

  //additional roles
  bytes32 private constant _MINTER_ROLE = keccak256("MINTER_ROLE");
  
  //max amount that can be minted in this collection
  uint16 public constant MAX_SUPPLY = 7777;
  //the sale price per token
  uint256 public constant MINT_PRICE = 0.005 ether;

  //maximum amount that can be purchased per wallet in the public sale
  uint256 public constant MAX_PER_WALLET = 9;

  // ============ Storage ============

  //mapping of address to amount minted
  mapping(address => uint256) public minted;
  //flag for if the mint is open to the public
  bool public mintOpened;
  //maximum amount free per wallet in the public sale
  uint256 public maxFreePerWallet = 1;

  // ============ Deploy ============

  /**
   * @dev Sets the base token uri
   */
  constructor(
    string memory preview, 
    address admin
  ) CashCowsAbstract(preview, admin) {}
  
  // ============ Read Methods ============

  /**
   * @dev Returns the token collection name.
   */
  function name() external pure returns(string memory) {
    return "Cash Cows Crew";
  }

  /**
   * @dev Returns the token collection symbol.
   */
  function symbol() external pure returns(string memory) {
    return "MOO";
  }

  // ============ Write Methods ============

  /**
   * @dev Mints new tokens for the `recipient`. Its token ID will be 
   * automatically assigned
   */
  function mint(uint256 quantity) external payable nonReentrant {
    address recipient = _msgSender();
    //no contracts sorry..
    if (recipient.code.length > 0
      //has the sale started?
      || !mintOpened
      //the quantity here plus the current amount already minted 
      //should be less than the max purchase amount
      || (quantity + minted[recipient]) > MAX_PER_WALLET
      //the quantity being minted should not exceed the max supply
      || (super.totalSupply() + quantity) > MAX_SUPPLY
    ) revert InvalidCall();

    //if there are still some free
    if (minted[recipient] < maxFreePerWallet) {
      //find out how much left is free
      uint256 freeLeft = maxFreePerWallet - minted[recipient];
      //if some of the quantity still needs to be paid
      if (freeLeft < quantity 
        // and what is sent is less than what needs to be paid 
        && ((quantity - freeLeft) * MINT_PRICE) > msg.value
      ) revert InvalidCall();
    //the value sent should be the price times quantity
    } else if ((quantity * MINT_PRICE) > msg.value) 
      revert InvalidCall();

    minted[recipient] += quantity;
    _safeMint(recipient, quantity);
  }

  /**
   * @dev Allows anyone to mint tokens that was approved by the owner
   */
  function mint(
    uint256 quantity, 
    uint256 maxMint, 
    uint256 maxFree, 
    bytes memory proof
  ) external payable nonReentrant {
    address recipient = _msgSender();

    //free cannot be more than max
    if (maxMint < maxFree
      //the quantity here plus the current amount already minted 
      //should be less than the max purchase amount
      || (quantity + minted[recipient]) > maxMint
      //the quantity being minted should not exceed the max supply
      || (super.totalSupply() + quantity) > MAX_SUPPLY
      //make sure the minter signed this off
      || !hasRole(_MINTER_ROLE, ECDSA.recover(
        ECDSA.toEthSignedMessageHash(
          keccak256(abi.encodePacked(
            "mint", 
            recipient, 
            maxMint,
            maxFree
          ))
        ),
        proof
      ))
    ) revert InvalidCall();

    //if there are still some free
    if (minted[recipient] < maxFree) {
      //find out how much left is free
      uint256 freeLeft = maxFree - minted[recipient];
      //if some of the quantity still needs to be paid
      if (freeLeft < quantity 
        // and what is sent is less than what needs to be paid 
        && ((quantity - freeLeft) * MINT_PRICE) > msg.value
      ) revert InvalidCall();
    //the value sent should be the price times quantity
    } else if ((quantity * MINT_PRICE) > msg.value) 
      revert InvalidCall();

    minted[recipient] += quantity;
    _safeMint(recipient, quantity);
  }

  // ============ Admin Methods ============

  /**
   * @dev Allows the _MINTER_ROLE to mint any to anyone (in the case of 
   * a no sell out)
   */
  function mint(
    address recipient,
    uint256 quantity
  ) external onlyRole(_MINTER_ROLE) nonReentrant {
    //the quantity being minted should not exceed the max supply
    if ((super.totalSupply() + quantity) > MAX_SUPPLY) 
      revert InvalidCall();

    _safeMint(recipient, quantity);
  }

  /**
   * @dev Starts the sale
   */
  function openMint(bool yes) external onlyRole(_CURATOR_ROLE) {
    mintOpened = yes;
  }

  /**
   * @dev Allows the admin to change the public max free
   */
  function setMaxFree(uint256 max) external onlyRole(_CURATOR_ROLE) {
    maxFreePerWallet = max;
  }

  /**
   * @dev Allows the proceeds to be withdrawn. This wont be allowed
   * until the metadata has been set to discourage rug pull
   */
  function withdraw(address recipient) external onlyOwner nonReentrant {
    //cannot withdraw without setting a base URI first
    if (address(_metadata) == address(0)) revert InvalidCall();
    payable(recipient).transfer(address(this).balance);
  }
}