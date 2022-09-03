pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

//  __      ________   _____           _                  _ 
//  \ \    / /  ____| |  __ \         | |                | |
//   \ \  / /| |__    | |__) | __ ___ | |_ ___   ___ ___ | |
//    \ \/ / |  __|   |  ___/ '__/ _ \| __/ _ \ / __/ _ \| |
//     \  /  | |      | |   | | | (_) | || (_) | (_| (_) | |
//      \/   |_|      |_|   |_|  \___/ \__\___/ \___\___/|_|
//      +-+-+-+-+ +-+ +-+-+-+-+ +-+-+-+ +-+-+-+-+-+-+-+-+-+
//      |I|t|'|s| |a| |v|e|r|y| |f|u|n| |p|r|o|t|o|c|o|l|.|
//      +-+-+-+-+ +-+ +-+-+-+-+ +-+-+-+ +-+-+-+-+-+-+-+-+-+                                                                                     

// VF Protocol v0 BasicSale controller contract
// This contract manages the core smart contract logic for selling ERC721 tokens for ETH (referred to as a "Handshake")
// in a zero fee, peer to peer, permissionless, and decentralized way. This contract works in concert with an ERC721 Approve pattern implemented by
// the front end of VF Protocol. The transaction pattern assumes a Buyer and Seller have already "found" each other somewhere else and 
// now want to transact some ERC721 token for protocol (unwrapped) ETH. 
//
// It works as follows:
// 1. Seller initiates a Handshake by specifying ERC-721 Token, Price, and target Buyer (Seller is prompted in frontend to give VF Protocol "transferFrom" Approval)
// 2. Buyer now has 1 hour to accept Handshake in dApp (Accept triggers a transfer of ETH to VFProtocolv0 and ERC721 is transferred upon receipt of correct amount of ETH)
// 3. Seller withdraws ETH payment from VFProtocolv0 whenever convenient for her
// 

contract BasicSale is ReentrancyGuard, Pausable {

  event SaleInit(uint index, address seller, address buyer, uint price, address NFTContract, uint TokenID); // Logs all initiated Handshakes
  event BuyInit(uint index, address buyer, address seller, uint price, address NFTContract, uint TokenID); // Logs all accepted Handshakes
  event Withdrawals(address withdrawer, uint amountWithdrawn); //Logs all withdrawals  

  address private owner; // Authorized wallet for emergency withdrawals - hard code
  uint public index; // Handshake index 

// Core data structure for Handshake
  struct Sale {
    address seller; // NFT seller - set as msg.sender
    address buyer; // NFT Buyer - set by seller
    uint price; // In gwei
    uint saleInitTime; // Block.timestamp (used only for logging and expiration management)
    uint saleExpiration; // Block.timestamp + 1 hour for sale acceptance (used only for logging and expiration management)
    address nftContract; // NFT Contract - set by msg.sender via frontend UX
    uint tokenId; // NFT Contract token ID - set by msg.sender via frontend UX
    bool offerAccepted; // Triggered when buyer accepts Handshake
    bool offerCanceled; // Triggered when seller cancels Handshake
  }

  mapping (uint => Sale) sales; //Map of index : Handshakes struct <- has all transaction data inside
  mapping (address => uint) balances; //Map of seller wallet addresses : Withdrawalable ETH <- only increased by buyers accepting Handshakes 
  // Can call balanceOf to see if balance exists for wallet address

  // Set emergency multisig owner
  constructor() payable {
    owner = payable(address(0xe5D45e93d3Fb7c9f1c1F68fD7Af0b8e42C0806aB)); // Hard code owner address for emergency pause/withdrawal of errant ETH caught be "receive"
  }

  // Sets function only accessible by owner 
  modifier OnlyOwner {
    require(msg.sender == owner,"Not owner of contract");
    _;
  }

  // Emergency Pause functions only accessible by owner
  function pause() public OnlyOwner {
    _pause();
  }

// Emergency unpause functions only accessible by owner
  function unpause() public OnlyOwner {
    _unpause();
  }


  // Seller Creates Handshake with all pertinent transaction data
  function saleInit(address _buyer, uint _price, address _nftContract, uint _tokenId) public nonReentrant() whenNotPaused() {
      require(_buyer!=address(0), "Null Buyer Address");  //Checks if buyer address isn't 0 address
      require(_buyer!=msg.sender, "Seller cannot be Buyer"); //Checks if seller is buyer
      require(_price > 0, "Need non-zero price"); //Checks if price is non-zero
      require(_nftContract!=address(0), "Null Contract address"); //Checks that NFT contract isn't 0 address
      require(IERC721(_nftContract).ownerOf(_tokenId)==msg.sender, "Sender not owner or Token does not exist"); //Checks that msg.sender is token owner and if token exists 

      // Sale Struct from above
      Sale memory thisSale = Sale({
        seller: msg.sender, 
        buyer:_buyer,
        price: _price, // in GWEI
        saleInitTime: block.timestamp, // Manipulatable, but exactly 60 min isn't crucial
        saleExpiration: block.timestamp + 1 hours, // 1 hour to accept sale from Handshake creation
        nftContract: _nftContract,
        tokenId: _tokenId,
        offerAccepted: false,
        offerCanceled: false
      });

      sales[index] = thisSale; //Assign individual Handshake struct to location in handshakes mapping 
      index += 1; //Increment handshakes index for next Handshake
      emit SaleInit(index-1, msg.sender, thisSale.buyer, thisSale.price, thisSale.nftContract, thisSale.tokenId); //Emits Handshake initiation for subgraph tracking
      
      
  }

  // CAUTION: Now Approval for ERC721 transfer needs to happen with frontend interaction via JS so VFProtocolv0 contract can transfer
  
  // This is how the Buyer accepts the handshake (pass along index and send appropriate amount of ETH to VFProtocolv0)
 
  function buyInit(uint _index) public payable nonReentrant() whenNotPaused() {
    require(_index<index,"Index out of bounds"); //Checks if index exists
    require(IERC721(sales[_index].nftContract).getApproved(sales[_index].tokenId)==address(this),"Seller hasn't Approved VFP to Transfer"); //Confirms Approval pattern is met
    require(!sales[_index].offerAccepted, "Already Accepted"); // Check to ensure this Handshake hasn't already been accepted/paid
    require(!sales[_index].offerCanceled, "Offer Canceled"); // Checks to ensure seller didn't cancel offer
    require(block.timestamp<sales[_index].saleExpiration,"Time Expired"); // Checks to ensure 60 minute time limit hasn't passed
    require(sales[_index].buyer==msg.sender,"Not authorized buyer"); // Checks to ensure redeemer is whitelisted buyer
    require(msg.value==sales[_index].price,"Not correct amount of ETH"); // Checks to ensure enough ETH is sent to pay seller
    sales[_index].offerAccepted = true; // Sets acceptance to true after acceptance

    balances[sales[_index].seller] += msg.value; //Updates withdrawable ETH for seller after VFProtocolv0 receives ETH
    IERC721(sales[_index].nftContract).transferFrom(sales[_index].seller, sales[_index].buyer, sales[_index].tokenId); //Transfers NFT to buyer after payment
    emit BuyInit(_index, sales[_index].buyer,sales[_index].seller, sales[_index].price, sales[_index].nftContract, sales[_index].tokenId); //Emits Handshake Acceptance
  }

// Withdraw function for sellers to receive their payments. Seller submits index of ANY transaction on which they are seller, then runs checks and allow withdrawals
  function withdraw() external nonReentrant() whenNotPaused() {
    require(balances[msg.sender]>0,"No balance to withdraw"); //Checks if msg.sender has a balance
    uint withdrawAmount = balances[msg.sender]; //Locks withdraw amount
    balances[msg.sender] = 0; //Resets balance (Checks - Effects - Transfers pattern)
    (bool sent, bytes memory data) = payable(msg.sender).call{value: withdrawAmount}(""); //Sends ETH balance to seller
        require(sent, "Failed to send Ether"); //Reverts if it fails
    emit Withdrawals(msg.sender, withdrawAmount);
  }

  // Cancel function allows a seller to cancel handshake
  function cancel(uint _index) external  whenNotPaused() {
    require(_index<index,"Index out of bounds"); // Checks to ensure index exists
    require(sales[_index].seller==msg.sender,"Not authorized seller"); //Checks to ensure only seller can cancel Handshake
    require(sales[_index].offerAccepted==false,"Offer Already Accepted"); //Checks to ensure offer hasn't been accepted
    require(block.timestamp<sales[_index].saleExpiration,"Time Expired"); //Checks to see if time expired to avoid gas wastage
    sales[_index].offerCanceled = true;
  }

  // BalanceOf function returns the redeemable balance of a given address
  // Might make sense to only let YOU check your OWN balance? (Not sure if this is a good idea)
  function balanceOf(address requester) external view returns (uint256) {
        require(requester != address(0), "ERC721: address zero is not a valid owner");
        return balances[requester];
    }


  //Receive function to handle unknown transactions
  receive() external payable whenNotPaused() {
    balances[owner] += msg.value; //Catches stray ETH sent to contract
  } 


}