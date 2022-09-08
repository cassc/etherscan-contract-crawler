// SPDX-License-Identifier: ISC

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Treasury is Ownable {

  address public secondAccountWithdraw;
  uint public splitPercentage; // 50 -> 5%, 25 -> 2,5%

  /**
   * @notice Constructor
   * @param _secondAccountWithdraw set discount for vip token
   */
  constructor(address _secondAccountWithdraw, uint _splitPercentage) {
    secondAccountWithdraw = _secondAccountWithdraw;
    splitPercentage = _splitPercentage;
  }

  /**
   * @notice Withdraw generated rewards in _token
   * @param _token Payment token to withdraw, address 0 for ETH
   */
  function withdraw(address _token) external onlyOwner {
    uint balance;
       if (_token == address(0)) {
      if (secondAccountWithdraw != address(0)) {
        balance = address(this).balance;
        uint amountSplit = ((balance / 100) * splitPercentage ) / 10;

        payable(secondAccountWithdraw).transfer(amountSplit);
      }
      balance = address(this).balance;
      payable(msg.sender).transfer(balance);
    } else {
      if (secondAccountWithdraw != address(0)) {
        IERC20(_token).balanceOf(address(this));
        uint amountSplit = ((balance / 100) * splitPercentage ) / 10;

        IERC20(_token).transfer(secondAccountWithdraw, amountSplit);
      }
      balance = IERC20(_token).balanceOf(address(this));
      IERC20(_token).transfer(msg.sender, balance);
    }
  }

  /**
   * @notice Set second account for split withdraw
   * @param _secondAccountWithdraw second account to split
   */


   function setAccountAndPercentage(address _secondAccountWithdraw, uint _splitPercentage) external onlyOwner{
     secondAccountWithdraw = _secondAccountWithdraw;
     splitPercentage = _splitPercentage;
   }
  function setSecondAccountWithdraw(address _secondAccountWithdraw) external onlyOwner {
    secondAccountWithdraw = _secondAccountWithdraw;
  }
    function setSplitPercentage(uint _splitPercentage) external onlyOwner {
    splitPercentage = _splitPercentage;
  }

  

  event Received(address, uint);

  receive() external payable {
    emit Received(msg.sender, msg.value);
  }

}