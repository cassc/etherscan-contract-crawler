// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Contract that exposes the needed erc20 token functions
 */

interface ERC20Interface {
  // Send _value amount of tokens to address _to
  function transfer(address _to, uint256 _value) external returns (bool success);
  // Get the account balance of another account with address _owner
  function balanceOf(address _owner) external view returns (uint256 balance);
}

/**
 * Contract that will forward any incoming Ether to its creator
 */
contract Forwarder {
  // Address to which any funds sent to this contract will be forwarded
  address public parentAddress;
  event ForwarderDeposited(address from, uint value, bytes data);

  event TokensFlushed(
    address tokenContractAddress, // The contract address of the token
    uint value // Amount of token sent
  );

  /**
   * Create the contract, and set the destination address to that of the creator
   */
  constructor() {
    parentAddress = msg.sender;
  }

  /**
   * Modifier that will execute internal code block only if the sender is a parent of the forwarder contract
   */
  modifier onlyParent {
    require (msg.sender == parentAddress, "!parent");
    _;
  }

  /**
   * Default function; Gets called when Ether is deposited, and forwards it to the destination address
   */
  fallback() external payable {
    (bool success, ) = parentAddress.call{value: msg.value}(msg.data);
    require(success, "!receive");
    // Fire off the deposited event if we can forward it  
    emit ForwarderDeposited(msg.sender, msg.value, msg.data);
  }

  receive() external payable {
    require(false, "!receive");
  }

  /**
   * Execute a token transfer of the full balance from the forwarder token to the main wallet contract
   * @param tokenContractAddress the address of the erc20 token contract
   */
  function flushTokens(address tokenContractAddress) external onlyParent {
    ERC20Interface instance = ERC20Interface(tokenContractAddress);
    address forwarderAddress = address(this);
    uint256 forwarderBalance = instance.balanceOf(forwarderAddress);
    if (forwarderBalance == 0) {
      return;
    }
    require(instance.transfer(parentAddress, forwarderBalance), "!transfer");
    emit TokensFlushed(tokenContractAddress, forwarderBalance);
  }

  /**
   * It is possible that funds were sent to this address before the contract was deployed.
   * We can flush those funds to the destination address.
   */
  function flush() external {
    (bool success, ) = parentAddress.call{value: address(this).balance}("");
    require(success, "!flush");
  }
}