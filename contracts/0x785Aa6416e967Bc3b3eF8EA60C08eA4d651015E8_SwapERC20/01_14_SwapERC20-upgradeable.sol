// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract SwapERC20 is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {

  ERC20Upgradeable public paymentToken;
  ERC20Upgradeable public contractToken;
  // token price for PTN
  uint256 private tokensPerPTN;

  // Event that log buy operation
  event BuyTokens(address buyer, uint256 amountOfPTN, uint256 amountOfTokens);
  event WithdrawTokens(address receiver, uint256 amountOfTokens);
  event NewTokenPrice(uint256 newPrice);

    function initialize(ERC20Upgradeable _paymentToken, ERC20Upgradeable _contractToken) initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
         paymentToken = _paymentToken;
         contractToken = _contractToken;
    }

  /**
  * @notice Allow users to buy token for PTN
  */
  function buyTokens(uint256 amount) external nonReentrant {
    require(amount > 0, "Send payment tokens to buy some tokens");
    
    uint8 contractTokenDecimals = contractToken.decimals();
    uint256 totalPaymentAmount = (amount * tokensPerPTN) / (10 ** contractTokenDecimals);
    require(totalPaymentAmount > 0, "Insufficient Payment Amount");

    // check if the Contract has enough amount of tokens for the transaction
    uint256 vendorBalance = contractToken.balanceOf(address(this));
    require(vendorBalance >= amount, "Vendor contract has not enough tokens in its balance");

    (bool received) = paymentToken.transferFrom(msg.sender, owner(), totalPaymentAmount);
    if(received) {
        // Transfer token to the msg.sender
        (bool sent) = contractToken.transfer(msg.sender, amount);
        require(sent, "Failed to transfer token to user");
    } else {
        revert("Failed to transfer tokens from user");
    }

    // emit the event
    emit BuyTokens(msg.sender, totalPaymentAmount, amount);
  }

  function setSwapPrice(uint256 newPrice) external onlyOwner {
      require(newPrice > 0, "Price cannot be zero");
      tokensPerPTN = newPrice;

      emit NewTokenPrice(newPrice);
  }

  function getSwapPrice() external view returns(uint256) {
      return tokensPerPTN;
  }

  /**
  * @notice Allow the owner of the contract to withdraw PTN
  */
  function withdraw(uint256 amount) public onlyOwner nonReentrant {
    uint256 contractBalance = contractToken.balanceOf(address(this));
    require(amount <= contractBalance, "Owner has not balance to withdraw");

    (bool sent) = contractToken.transfer(owner(), amount);
    require(sent, "Failed to transfer token to user");

    emit WithdrawTokens(msg.sender, amount);
  }

    //uups upgradable
     function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}