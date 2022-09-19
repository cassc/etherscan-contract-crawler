// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
  * @title  Payment Router V1
  * @notice Routes payments of ETH or ERC20 tokens to specified receipient and
  *         takes fee if set.
  * @dev    The makePayment function acts as a transfer proxy for sending tokens. 
  *         The Payment event emitted uses an ID to tie payments to offchain records.
  */
contract PaymentRouterV1 is Ownable {
  using SafeMath for uint256;

  uint256 public feeBp;
  address public nativeAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  event Payment(
    address indexed from,
    address indexed to,
    address token,
    uint256 amount,
    uint256 fee,
    bytes32 indexed id
  );

  /**
    * @notice Transfers ETH or tokens to specified receipient and takes fee if set.
    * @dev    Amount param is used for a soft validation rule to help prevent 
    *         calls where user updates amount in wallet.
    * @param  tokenAddress  Address of token to send.
    * @param  amount        amount of tokens to send.
    * @param  recipient     Who to send the tokens to.
    * @param  id            Offchain ID to tie payment to offchain record.
   */
  function makePayment(
    address tokenAddress,
    uint256 amount,
    address payable recipient,
    bytes32 id
  ) public payable {
    // Calculate fee and subtract from amount.
    uint256 fee = feeFor(amount);
    uint256 amountMinusFee = amount.sub(fee);

    if (tokenAddress == nativeAddress) {
      require(msg.value == amount, "ETH sent not equal amount");
      // Send amount minus fee to recipient.
      (bool sent, ) = recipient.call{value: amountMinusFee}("");
      require(sent, "Failed to send Ether");
    } else {
      sendERC20(tokenAddress, amountMinusFee, fee, recipient);
    }

    emit Payment(msg.sender, recipient, tokenAddress, amount, fee, id);
  }

  /**
    * @notice Transfers ERC20 token to specified receipient and takes fee if set.
    * @param  tokenAddress    Address of ERC20 token to send.
    * @param  amountMinusFee  Amount of tokens to send to recipient.
    * @param  fee             Amount of tokens to send to this contract.
    * @param  recipient       Who to send the tokens to.
    */
  function sendERC20(
    address tokenAddress,
    uint256 amountMinusFee,
    uint256 fee,
    address recipient
  )private {
    IERC20 token = IERC20(tokenAddress);
    // Transfer amount minus fee to recipient
    require(token.transferFrom(msg.sender, recipient, amountMinusFee), "Failed ERC20 transfer");
    // Transfer fee to this contract.
    token.transferFrom(msg.sender, address(this), fee);
  }

  /**
    * @notice Sets fee basis points to take from each transfer.
    * @dev    Can only be called by this contract's owner.
    * @param  newNativeAddress Native asset address.
    */
  function setNativeAddress(address newNativeAddress) external onlyOwner {
    nativeAddress = newNativeAddress;
  }
  
  /**
  * @notice Sets native asset address.
  * @dev    Can only be called by this contract's owner.
  * @param  newFeeBp Fee percentage in basis points.
  */
  function setFeeBp(uint256 newFeeBp) external onlyOwner {
    feeBp = newFeeBp;
  }

  /**
    * @notice Gets fee value for given amount and contracts current fee percentage.
    * @param  amount The amount to get the fee for.
    */
  function feeFor(uint256 amount) public view returns (uint256) {
    return amount.mul(feeBp).div(10000);
  }

  /**
    * @notice Withdraws ETH fees collected by contract.
    * @dev    Can only be called by this contract's owner.
    * @param  to The address to withdraw the fees to.
    */
  function withdraw(address payable to) external onlyOwner {
    uint amount = address(this).balance;

    (bool success, ) = to.call{value: amount}("");
    require(success, "Failed to send Ether");
  }

  /**
    * @notice Withdraws ERC20 token fees collected by contract.
    * @dev    Can only be called by this contract's owner.
    * @param  tokenAddress  The ERC20 token to withdraw fees for.
    * @param  amount        The amount of token to withdraw.
    * @param  to            The address to withdraw the fees to.
    */
  function withdrawToken(address tokenAddress, uint256 amount, address to) external onlyOwner {
    IERC20 token = IERC20(tokenAddress);
    token.transfer(to, amount);
  }
}