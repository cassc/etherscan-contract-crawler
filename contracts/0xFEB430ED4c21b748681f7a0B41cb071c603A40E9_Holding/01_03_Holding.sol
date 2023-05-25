pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Holding {
  using SafeMath for uint256;

  uint256 public unlocked;
  address public recipient;
  address public token;
  address public owner; 

  constructor(address _token, address _recipient) {
    owner = msg.sender;
    token = _token;
    recipient = _recipient;
  }

  function unlock(uint256 unlockAmount) public onlyOwner {
    require(unlockAmount <= IERC20(token).balanceOf(address(this)), "unlock > balance"); 
    unlocked = unlockAmount;
  }

  function sendToken(uint256 amount) public onlyOwner {
    require(amount <= unlocked, "more than unlocked");
    IERC20(token).transfer(recipient, amount);       
    unlocked = unlocked.sub(amount);
  }

  function changeRecipient(address newRecipient) public onlyOwner {
    require(newRecipient != address(0));
    recipient  = newRecipient;
  }

  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }

  modifier onlyOwner {
      require(msg.sender == owner, "only owner");
      _;
  }

}