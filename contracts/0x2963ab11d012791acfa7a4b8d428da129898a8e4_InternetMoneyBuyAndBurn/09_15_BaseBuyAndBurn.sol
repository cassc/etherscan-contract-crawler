// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./interfaces/IERC20Burnable.sol";
import "./interfaces/IInternetMoneySwapRouter.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/ITIMEDividend.sol";
import "./interfaces/IBuyAndBurn.sol";
import "./Utils.sol";

/**
 * @title BaseBuyAndBurn is a contract for custodying dividend producing tokens
 * claiming said dividends, swapping a wrapped native token,
 * and burning the remaining tokens
 */
contract BaseBuyAndBurn is Multicall, Utils, IBuyAndBurn {
  using SafeERC20 for IERC20;
  error NotAllowed();
  /** the producer token, which produces dividends */
  address public immutable producer;
  /** the token to purchase on market */
  address public immutable target;
  /** the token has a burn method */
  bool public immutable targetCanBurn;
  /** the destination for non burnable tokens */
  address public immutable burnDestination;
  /** the router to swap through */
  address public immutable router;
  /**
   * @notice the deposited amount from a given address
   */
  mapping(address => uint256) public depositOf;
  /**
   * denotes that the deposited amount for a given account has been increased
   * @param account the account whos balance is being credited
   * @param amount the amount of the credit from depositing
   */
  event Deposit(address account, uint256 amount);
  /**
   * denotes that the account has withdrawn a balance
   * @param account the account whos balance is being deducted
   * @param amount the amount to deduct from the credit held in the contract
   */
  event Withdraw(address account, uint256 amount);

  constructor(
    address _producer,
    address _target,
    bool _targetCanBurn,
    address _burnDestination,
    address _router
  ) {
    producer = _producer;
    target = _target;
    targetCanBurn = _targetCanBurn;
    if (_targetCanBurn && _burnDestination != address(0)) {
      revert NotAllowed();
    }
    router = _router;
    burnDestination = _burnDestination;
  }
  /** makes this contract payable */
  receive() external payable {}
  /**
   * deposit producing tokens into this contract
   * @param amount the amount to deposit into this contract
   */
  function deposit(uint256 amount) external {
    uint256 before = IERC20(producer).balanceOf(address(this));
    IERC20(producer).safeTransferFrom(msg.sender, address(this), amount);
    uint256 delta = IERC20(producer).balanceOf(address(this)) - before;
    uint256 currentDeposit = depositOf[msg.sender];
    depositOf[msg.sender] = currentDeposit + delta;
    emit Deposit(msg.sender, delta);
  }
  /**
   * withdraw a magnitude of dividend producing tokens to a provided destination
   * @param destination where to send tokens when they have been
   * @param amount the amount to withdraw against a debt
   */
  function withdraw(address destination, uint256 amount) external {
    uint256 limit = depositOf[msg.sender];
    amount = _clamp(amount, limit);
    unchecked {
      depositOf[msg.sender] = limit - amount;
    }
    destination = destination == address(0) ? msg.sender : destination;
    IERC20(producer).safeTransfer(destination, amount);
    emit Withdraw(msg.sender, amount);
  }
  /**
   * claim dividend from the producer contract
   * @param amount amount to pass to the claim dividend method on the producer contract
   * @notice the balance is returned to help make checks on client easier
   */
  function claimDividend(uint256 amount) external returns(uint256) {
    ITIMEDividend(producer).claimDividend(payable(address(this)), amount);
    return address(this).balance;
  }
  /**
   * run a swap after converting outstanding native token to a wrapped token
   * @param minAmountOut the minimum amount to get out of a swap
   * @param deadline sets a deadline for the transaction to be invalid after
   * @notice anyone can set the min amount out, therefore
   * anyone can run this method with a 0 min amount out and sandwich the transaction
   */
  function _buy(uint256 amountIn, uint256 minAmountOut, uint256 deadline) internal {
    address _router = router;
    address payable _wNative = IInternetMoneySwapRouter(_router).wNative();
    uint256 wBalance = IWETH(_wNative).balanceOf(address(this));
    if (wBalance > 0) {
      IWETH(_wNative).withdraw(wBalance);
    }
    address[] memory path = new address[](2);
    path[0] = _wNative;
    path[1] = target;
    uint256 balance = _clamp(amountIn, address(this).balance);
    uint256 fees = (balance * IInternetMoneySwapRouter(_router).fee()) / 100_000;
    IInternetMoneySwapRouter(_router).swapNativeToV2{
      value: balance
    }(
      0,
      address(this),
      path,
      balance - fees,
      minAmountOut,
      deadline
    );
  }
  /**
   * purchases target token using the native currency
   * @param minAmountOut the minimum amount out expected
   * @param deadline when the trade should no longer be carried out
   * @notice passing 0 for deadline means that the buy will never expire
   */
  function buy(uint256 amountIn, uint256 minAmountOut, uint256 deadline) external payable {
    _buy(amountIn, minAmountOut, _clamp(deadline, block.timestamp + 1));
  }
  /**
   * burn the target token after it has been swapped
   * @notice this will allow any token sent to the contract to be burnt
   */
  function burn() external {
    address _target = target;
    uint256 balance = IERC20(_target).balanceOf(address(this));
    if (targetCanBurn) {
      IERC20Burnable(_target).burn(balance);
    } else {
      IERC20(_target).safeTransfer(burnDestination, balance);
    }
  }
}