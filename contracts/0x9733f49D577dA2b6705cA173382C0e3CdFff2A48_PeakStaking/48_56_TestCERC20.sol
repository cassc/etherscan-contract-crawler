pragma solidity 0.5.17;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "../interfaces/CERC20.sol";
import "../interfaces/Comptroller.sol";

contract TestCERC20 is CERC20 {
  using SafeMath for uint;

  uint public constant PRECISION = 10 ** 18;
  uint public constant MAX_UINT = 2 ** 256 - 1;

  address public _underlying;
  uint public _exchangeRateCurrent = 10 ** (18 - 8) * PRECISION;

  mapping(address => uint) public _balanceOf;
  mapping(address => uint) public _borrowBalanceCurrent;

  Comptroller public COMPTROLLER;

  constructor(address __underlying, address _comptrollerAddr) public {
    _underlying = __underlying;
    COMPTROLLER = Comptroller(_comptrollerAddr);
  }

  function mint(uint mintAmount) external returns (uint) {
    ERC20Detailed token = ERC20Detailed(_underlying);
    require(token.transferFrom(msg.sender, address(this), mintAmount));

    _balanceOf[msg.sender] = _balanceOf[msg.sender].add(mintAmount.mul(10 ** this.decimals()).div(PRECISION));
    
    return 0;
  }

  function redeemUnderlying(uint redeemAmount) external returns (uint) {
    _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(redeemAmount.mul(10 ** this.decimals()).div(PRECISION));

    ERC20Detailed token = ERC20Detailed(_underlying);
    require(token.transfer(msg.sender, redeemAmount));

    return 0;
  }
  
  function borrow(uint amount) external returns (uint) {
    // add to borrow balance
    _borrowBalanceCurrent[msg.sender] = _borrowBalanceCurrent[msg.sender].add(amount);

    // transfer asset
    ERC20Detailed token = ERC20Detailed(_underlying);
    require(token.transfer(msg.sender, amount));

    return 0;
  }
  
  function repayBorrow(uint amount) external returns (uint) {
    // accept repayment
    ERC20Detailed token = ERC20Detailed(_underlying);
    uint256 repayAmount = amount == MAX_UINT ? _borrowBalanceCurrent[msg.sender] : amount;
    require(token.transferFrom(msg.sender, address(this), repayAmount));

    // subtract from borrow balance
    _borrowBalanceCurrent[msg.sender] = _borrowBalanceCurrent[msg.sender].sub(repayAmount);

    return 0;
  }

  function balanceOf(address account) external view returns (uint) { return _balanceOf[account]; }
  function borrowBalanceCurrent(address account) external returns (uint) { return _borrowBalanceCurrent[account]; }
  function underlying() external view returns (address) { return _underlying; }
  function exchangeRateCurrent() external returns (uint) { return _exchangeRateCurrent; }
  function decimals() external view returns (uint) { return 8; }
}