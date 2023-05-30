// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
* On-chain marketplace pricing state/logic for PixelverseItem ERC1155 tokens.
* Admins will be able to mint supplies of ERC1155 tokens to this address 
* and sell them here for purchase in PIXL as an official "Primary Sale".
* All sale proceeds go to the contract which can be redeemed by the owner.
*/
contract PixelMarketplace is IERC1155Receiver, ReentrancyGuard, AccessControl, Ownable {

  bytes32 public constant SELLER_ROLE = keccak256("SELLER_ROLE");

  IERC1155 public pixelverseItem;
  IERC20 public pixlToken;

  mapping(uint256 => uint256) public tokenIdToPixlPrice;

  // NOTE: You'll also need to run setPixelverseItemContract before creating listings.
  constructor(IERC20 pixlTokenAddress) Ownable() {
    pixlToken = pixlTokenAddress;
    _setupRole(SELLER_ROLE, msg.sender);
  }

  /* 
  * Places a PixelverseItem "for sale" on the marketplace, priced in $PIXL. 
  * NOTE: SINCE THIS IS A CONTRACT-ONLY OPERATION, SUPPLY THE AMOUNT IN "WHOLE" $PIXL.
  * SOLIDITY WILL MULTIPLY THE 10^18 TO ENSURE LESS FAT-FINGERING/HUMAN ERROR.
  * 
  * NOTE: To fetch market prices, utilize the public `tokenIdToPixlPrice`. 
  * The client must manually dictates what tokenIds will be shown at a time.
  * This is to save gas for read-path calls.
  */
  function createMarketListing(
    uint256 tokenId,
    uint256 priceInPixlInteger
  ) public nonReentrant {
    require(hasRole(SELLER_ROLE, msg.sender), "User must have SELLER_ROLE to list items for sale");
    require(address(pixelverseItem) != 0x0000000000000000000000000000000000000000, 
      "Please configure sellable ERC1155 contract via setPixelverseItemContract.");
    require(priceInPixlInteger > 0, "Price must be at least 1 $PIXL. BE SURE TO USE THE INTEGER VALUE.");

    tokenIdToPixlPrice[tokenId] = priceInPixlInteger * 1e18;
  }

  /* 
  * Creates the sale of a PixelverseItem from the "seller" to the msg.sender.
  * Transfers ownership of "amount" instances of an ERC1155 with a given id, 
  * and $PIXL from the buyer to the contract based on the tokens price.
  */
  function createMarketSale(uint256 tokenId, uint256 amount) public nonReentrant {
    require(address(pixelverseItem) != 0x0000000000000000000000000000000000000000, 
      "Please configure sellable ERC1155 contract via setPixelverseItemContract.");
    require(amount > 0, "Purchasable amount must be non-zero.");

    uint price = tokenIdToPixlPrice[tokenId] * amount;
    uint supply = pixelverseItem.balanceOf(address(this), tokenId);
    require(price > 0, "This item is not listed for sale!");
    require(supply > 0, "This item is sold out.");

    uint256 buyerPixlBalance = pixlToken.balanceOf(msg.sender);
    require(buyerPixlBalance >= price, "Insufficient funds: Not enough $PIXL for sale price");


    pixlToken.transferFrom(msg.sender, address(this), price);
    pixelverseItem.safeTransferFrom(address(this), msg.sender, tokenId, amount, "0x0");
  }


  /*********** ADMIN FUNCTIONS ************/


  /* 
  * Sets the ERC1155 contract which the Marketplace is holding and selling.
  * 
  * In conjunction with `deleteMarketListing` and `withdrawAllPixl`, allows owner to  
  * migrate Marketplace to sell items from a different ERC1155 NFT contract.
  */
  function setPixelverseItemContract(IERC1155 _contract) public onlyOwner {
    pixelverseItem = _contract;
  }

  /* 
  * Delete item price listing from Marketplace. 
  * Only do this if its sold out and you don't want to it show up on the site again.
  */
  function deleteMarketListing(uint256 _tokenId) public nonReentrant {
    require(hasRole(SELLER_ROLE, msg.sender), "User must have SELLER_ROLE to delete listed items");
    delete tokenIdToPixlPrice[_tokenId];
  }


  function withdrawPixl(uint256 _amount) public onlyOwner {
    uint256 pixlBalance = pixlToken.balanceOf(address(this));
    require(pixlBalance >= _amount, "Insufficient funds: not enough $PIXL");
    pixlToken.transfer(msg.sender, _amount);
  }

  function withdrawAllPixl() public onlyOwner {
    uint256 pixlBalance = pixlToken.balanceOf(address(this));
    require(pixlBalance > 0, "No $PIXL within this contract");
    pixlToken.transfer(msg.sender, pixlBalance);
  }


  function withdrawItems(uint256 _tokenId, uint256 _amount) public onlyOwner {
    uint256 contractBalance = pixelverseItem.balanceOf(address(this), _tokenId);
    require(contractBalance >= _amount, "Insufficient funds: not enough unsold Items");
    pixelverseItem.safeTransferFrom(address(this), msg.sender, _tokenId, _amount, "0x0");
  }

  function withdrawAllItems(uint256 _tokenId) public onlyOwner {
    uint256 contractBalance = pixelverseItem.balanceOf(address(this), _tokenId);
    require(contractBalance > 0, "No unsold Items left on the contract!");
    pixelverseItem.safeTransferFrom(address(this), msg.sender, _tokenId, contractBalance, "0x0");
  }


  // Just in case anyone sends us any random shitcoins ;)
  function withdrawErc20(address erc20Contract, uint256 _amount) public onlyOwner {
    uint256 erc20Balance = pixlToken.balanceOf(address(this));
    require(erc20Balance >= _amount, "Insufficient funds: not enough ERC20");
    IERC20(erc20Contract).transfer(msg.sender, _amount);
  }


  // Required for SC to hold ERC1155. Copypasta from OZ cuz node bein caca.
  // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/utils/ERC1155Holder.sol
  function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

}