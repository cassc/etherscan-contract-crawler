// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

struct TokenData {
  ERC20 token;
  bool exists;
}

struct RecipientTokenData {
  TokenData token_data;
  uint8 fee_percent;
}

// Contract for processing transactions
contract PaymentsProcessor is Ownable {
  using SafeMath for uint256;
  // Mapping from token cocntract address to ERC20 object
  mapping(address => TokenData) public available_tokens;

  // Mapping from recipient address to (ERC20 , fee) object 
  mapping(address => mapping(address => RecipientTokenData)) private recipients_erc20_fees;

  // Mapping from recipient address to native coin fee 
  mapping(address => uint8) private recipients_native_coin_fees;

  // Events for logging transactions
  event ERC20Transaction(address indexed token, address indexed from, address indexed to, uint256 value);
  event NativeCoinTransaction(address from, address to, uint256 value);

  // Constructor to initialize contract with available token contracts addresses
  constructor(address[] memory token_addresses) {
    for (uint256 i = 0; i < token_addresses.length; i++) {
      available_tokens[token_addresses[i]] = TokenData(ERC20(token_addresses[i]), true);
    }
  }

  // Function to set fee percentage for a specific ERC20 token address for a given recipient
  // Returns true on success
  function setERC20Fee(address receipient, address token_address ,uint8 fee_percent) public onlyOwner returns (bool) {
    // Fee must be in range (0, 100)
    require(fee_percent < 100, "Fee percent must be less than 100%");
    require(fee_percent > 0, "Fee percent must be greater than 0%");
    require(available_tokens[token_address].exists, "Unsupported token address");
    recipients_erc20_fees[receipient][token_address] = RecipientTokenData(available_tokens[token_address], fee_percent);
    return true;
  }

  // Function to set fee percentage for a native blockchain coin for a given recipient
  // Returns true on success
  function setNativeCoinFee(address receipient, uint8 fee_percent) public onlyOwner returns (bool) {
    // Fee must be in range (0, 100)
    require(fee_percent < 100, "Fee percent must be less than 100%");
    require(fee_percent > 0, "Fee percent must be greater than 0%");
    recipients_native_coin_fees[receipient] = fee_percent;
    return true;
  }

  // Function to get the fee percentage for a specific ERC20 token address for a given recipient
  function getERC20Fee(address receipient, address token_address) public onlyOwner view returns (uint8) {
    require(available_tokens[token_address].exists, "Unsupported token address");
    return recipients_erc20_fees[receipient][token_address].fee_percent;
  }

  // Function to get the fee percentage for a native blockchain coin for a given recipient
  function getNativeCoinFee(address receipient) public onlyOwner view returns (uint8){
    return recipients_native_coin_fees[receipient];
  }

  // Function to add a new ERC20 token to mapping of available tokens
  // Returns true on success
  function addERC20Token(address token_address) public onlyOwner returns (bool) {
    require(!available_tokens[token_address].exists, "Token address already exists");
    available_tokens[token_address] = TokenData(ERC20(token_address), true);
    return true;
  }


  // Function to process ERC20 transaction for a given recipient
  function processTransactionERC20(address token_address, address from, address to, uint256 value) public {
    // Ensure that the token contract is registered with the processor
    require(available_tokens[token_address].exists, "Token contract not registered with processor");
    // Ensure that the from address has sufficient balance
    require(available_tokens[token_address].token.balanceOf(from) >= value, "Insufficient balance for sender");
    // Ensure that value is a positive number
    require(value > 0, "Tokens amount must be greater than zero");
    // Get fee percent for the givan recipient and token 
    uint8 fee_percent = recipients_erc20_fees[to][token_address].fee_percent;
    // Calculate the amount to transfer to the recipient
    uint256 fee_amount = value.mul(fee_percent).div(100);
    // Transfer the value from sender to the contract
    available_tokens[token_address].token.transferFrom(from, address(this), value);
    // Transfer fee from contract to owner
    available_tokens[token_address].token.transfer(owner(), fee_amount);
    // Transfer (value - fee) to `to` address
    available_tokens[token_address].token.transfer(to, value.sub(fee_amount));
    // Emit transaction event
    emit ERC20Transaction(token_address, from, to, value);
  }

   // Function to process native coin transaction for a given recipient
   function processTransactionNative(address payable recipient) public payable {
    // Ensure that msg.value is a positive number
    require(msg.value > 0, "Value to process must be greater than zero");
    // Get recipient fee percent
    uint8 fee_percent = recipients_native_coin_fees[recipient];
    // Calculate fee amount
    uint256 fee_amount = msg.value.mul(fee_percent).div(100);
    // Calculate the amount to transfer to the recipient
    uint256 amount_to_recipient = msg.value - fee_amount;
    // Transfer the amount to the recipient
    recipient.transfer(amount_to_recipient);
    // Transfer the fee amount to the owner
    payable(owner()).transfer(fee_amount);
    // Emit transaction event
    emit NativeCoinTransaction(msg.sender, recipient, amount_to_recipient);
  }

}