// SPDX-License-Identifier: MIT

/**
 * ███████╗██╗   ██╗ ██████╗ ██╗    ██╗   ██╗███████╗     █████╗ ██╗
 * ██╔════╝██║   ██║██╔═══██╗██║    ██║   ██║██╔════╝    ██╔══██╗██║
 * █████╗  ██║   ██║██║   ██║██║    ██║   ██║█████╗      ███████║██║
 * ██╔══╝  ╚██╗ ██╔╝██║   ██║██║    ╚██╗ ██╔╝██╔══╝      ██╔══██║██║
 * ███████╗ ╚████╔╝ ╚██████╔╝███████╗╚████╔╝ ███████╗    ██║  ██║██║
 * ╚══════╝  ╚═══╝   ╚═════╝ ╚══════╝ ╚═══╝  ╚══════╝    ╚═╝  ╚═╝╚═╝
 */

/**
 * @title A token migration contract for Evolve Ai
 * @author TG: @moondan1337
 * @notice This contract's intended purpose is for users to deposit their entire balance of token A and receive token B to a desired wallet address. Token A and token B should have the same supply
 * and decimals to avoid any errors.
 */

pragma solidity 0.8.17;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EvolveAIMigrator is ReentrancyGuard, Ownable {
  /*|| === STATE VARIABLES === ||*/
  IERC20 public immutable tokenToDeposit; /// Token to send to the contract
  IERC20 public immutable tokenToSend; /// Token to send to the user
  bool public enabled; /// Migration enabled

  /*|| === MAPPINGS === ||*/
  mapping(address => uint) public addressToAmount;

  /*|| === CONSTRUCTOR === ||*/
  constructor(address _tokenToDeposit, address _tokenToSend) {
    tokenToDeposit = IERC20(_tokenToDeposit);
    tokenToSend = IERC20(_tokenToSend);
    enabled = true;
  }

  /*|| === EXTERNAL FUNCTIONS === ||*/
  /**
   * @notice Deposits all of the old tokens from the senders wallet to the contract and in return sends the number of tokens deposited in new tokens to the given address.
   * @param _address receiving address of new tokens
   * @dev to ensure migration continuity, the difference between the balance of the contract before and after tokens are deposited is the amount sent to the given address.
   */
  function depositAllTokens(address _address) external nonReentrant {
    require(enabled, "Migration not enabled");

    uint senderBalance = tokenToDeposit.balanceOf(msg.sender);

    require(senderBalance > 0, "Zero balance");
    require(senderBalance <= tokenToSend.balanceOf(address(this)), "Not enough tokens in the contract");

    uint balanceBefore = tokenToDeposit.balanceOf(address(this));

    /// Transfer tokens from sender to contract
    tokenToDeposit.transferFrom(msg.sender, address(this), senderBalance);

    /// Log tokens received to use as value to transfer to _address.
    uint tokensRecieved = tokenToDeposit.balanceOf(address(this)) - balanceBefore;

    /// Transfer new tokens to _address
    tokenToSend.transfer(_address, tokensRecieved);

    /// Map amount received to _address
    addressToAmount[_address] = tokensRecieved;
  }

  /**
   * @notice Claims all tokens deposited into the contract. Only owner function.
   */
  function claimDepositedTokens() external onlyOwner {
    /// Transfer all deposited tokens to owner
    tokenToDeposit.transfer(msg.sender, tokenToDeposit.balanceOf(address(this)));
  }

  /**
   * @notice Claims all tokensToSend from the contract. This should only be called when the migration is complete. Only owner function.
   */
  function claimTokensToSend() external onlyOwner {
    /// Transfer all tokens to send to the owner
    tokenToSend.transfer(msg.sender, tokenToSend.balanceOf(address(this)));
  }

  /**
   * @notice Enable contract deposits. Only owner function.
   */
  function enable() external onlyOwner {
    require(enabled == false, "Already enabled");
    enabled = true;
  }

  /**
   * @notice Disable contract deposits. Only owner function.
   */
  function disable() external onlyOwner {
    require(enabled == true, "Already disabled");
    enabled = false;
  }

  /**
   * @notice Claim ETH in contract. Only owner function.
   */
  function claimETH() external onlyOwner {
    (bool sent, ) = (msg.sender).call{ value: address(this).balance }("");
    require(sent, "Failed to send Ether");
  }

  /**
   * @notice Returns number of deposited tokens in contract. Quality of life.
   */
  function tokenToDepositBalance() external view returns (uint) {
    return tokenToDeposit.balanceOf(address(this));
  }

  /**
   * @notice Returns number of tokens to send in contract. Quality of life.
   */
  function tokenToSendBalance() external view returns (uint) {
    return tokenToSend.balanceOf(address(this));
  }
}