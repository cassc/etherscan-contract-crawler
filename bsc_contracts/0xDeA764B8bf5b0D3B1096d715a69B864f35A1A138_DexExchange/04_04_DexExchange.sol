// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;



// Learn more about the ERC20 implementation 
// on OpenZeppelin docs: https://docs.openzeppelin.com/contracts/4.x/api/access#Ownable
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DexExchange is Ownable {

  //Token Contract
 IERC20 public Token;

  // token price for BNB
  uint256 public rate ;


  // Event that log buy operation
  event BuyTokens(address buyer, uint256 amountOfBNB, uint256 amountOfTokens);
  event SellTokens(address seller, uint256 amountOfTokens, uint256 amountOfBNB);

  constructor(address _tokenAddress) {
    Token = IERC20(_tokenAddress);
  }

  /**
  * @notice Allow users to buy tokens for BNB
  */
  function buyTokens() public payable returns (uint256 tokenAmount) {
    require(msg.value > 0, "Send BNB to buy some tokens");

    uint256 amountToBuy = msg.value * rate;

    // check if the Vendor Contract has enough amount of tokens for the transaction
    uint256 vendorBalance = Token.balanceOf(address(this));
    require(vendorBalance >= amountToBuy, "Vendor contract has not enough tokens in its balance");

    // Transfer token to the msg.sender
    (bool sent) = Token.transfer(msg.sender, amountToBuy);
    require(sent, "Failed to transfer token to user");
    _setRate();

    // emit the event
    emit BuyTokens(msg.sender, msg.value, amountToBuy);

    return amountToBuy;
  }

  /**
  * @notice Allow users to sell tokens for ETH
  */
  function sellTokens(uint256 tokenAmountToSell) public {
    // Check that the requested amount of tokens to sell is more than 0
    require(tokenAmountToSell > 0, "Specify an amount of token greater than zero");

    // Check that the user's token balance is enough to do the swap
    uint256 userBalance = Token.balanceOf(msg.sender);
    require(userBalance >= tokenAmountToSell, "Your balance is lower than the amount of tokens you want to sell");

    // Check that the Vendor's balance is enough to do the swap
    uint256 amountOfBNBToTransfer = tokenAmountToSell / rate;
    uint256 contractBNBBalance = address(this).balance;
    require(contractBNBBalance >= amountOfBNBToTransfer, "Vendor has not enough funds to accept the sell request");

    (bool sent) = Token.transferFrom(msg.sender, address(this), tokenAmountToSell);
    require(sent, "Failed to transfer tokens from user to vendor");


    (sent,) = msg.sender.call{value: amountOfBNBToTransfer}("");
    require(sent, "Failed to send ETH to the user");
    _setRate();
  }

  //Add Liquidity
  function addLiquidity (uint256 tokenAmount) public payable onlyOwner{
   require(msg.value > 0 , "you can't add Liquidity for 0 value");
   (bool addTokens) = Token.transferFrom(msg.sender, address(this), tokenAmount);
   require(addTokens, "Failed to add liquidity");
   _setRate();
  }

  function _setRate  () internal { 
    uint256 contractBNBBalance = address(this).balance;
    uint256 vendorBalance = Token.balanceOf(address(this));
    uint256 newRate = vendorBalance / contractBNBBalance  ;
    rate = newRate;
  }
  function withdrawToken() public onlyOwner {
        Token.transfer(msg.sender, Token.balanceOf(address(this)));
    }

}