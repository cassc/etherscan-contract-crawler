pragma solidity 0.5.17;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/CEther.sol";
import "../interfaces/Comptroller.sol";

contract TestCEther is CEther {
  using SafeMath for uint;

  uint public constant PRECISION = 10 ** 18;

  uint public _exchangeRateCurrent = 10 ** (18 - 8) * PRECISION;

  mapping(address => uint) public _balanceOf;
  mapping(address => uint) public _borrowBalanceCurrent;

  Comptroller public COMPTROLLER;

  constructor(address _comptrollerAddr) public {
    COMPTROLLER = Comptroller(_comptrollerAddr);
  }

  function mint() external payable {
    _balanceOf[msg.sender] = _balanceOf[msg.sender].add(msg.value.mul(10 ** this.decimals()).div(PRECISION));
  }

  function redeemUnderlying(uint redeemAmount) external returns (uint) {
    _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(redeemAmount.mul(10 ** this.decimals()).div(PRECISION));

    msg.sender.transfer(redeemAmount);

    return 0;
  }
  
  function borrow(uint amount) external returns (uint) {
    // add to borrow balance
    _borrowBalanceCurrent[msg.sender] = _borrowBalanceCurrent[msg.sender].add(amount);

    // transfer asset
    msg.sender.transfer(amount);

    return 0;
  }
  
  function repayBorrow() external payable {
    _borrowBalanceCurrent[msg.sender] = _borrowBalanceCurrent[msg.sender].sub(msg.value);
  }

  function balanceOf(address account) external view returns (uint) { return _balanceOf[account]; }
  function borrowBalanceCurrent(address account) external returns (uint) { return _borrowBalanceCurrent[account]; }
  function exchangeRateCurrent() external returns (uint) { return _exchangeRateCurrent; }
  function decimals() external view returns (uint) { return 8; }

  function() external payable {}
}