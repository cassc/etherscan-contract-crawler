// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.7.0;

import './interfaces/IContribute.sol';
import './utils/MathUtils.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';

contract Genesis is ReentrancyGuard {
  using SafeMath for uint256;
  using MathUtils for uint256;
  using SafeERC20 for IERC20;

  event Deposit(address indexed from, uint256 amount);
  event Claim(address indexed user, uint256 amount);

  /// @notice End date and time of the Genesis Mint Event (GME).
  uint256 public endTime;

  /// @notice Total tokens acquired during the GME.
  uint256 public totalTokensReceived;

  /// @notice Total invested in the GME.
  uint256 public totalInvested;

  /// @notice mUSD reserve instance.
  address public reserve;

  /// @notice Minter contract instance.
  address public contribute;

  /// @notice Balance tracker of accounts who have deposited funds.
  mapping(address => uint256) balance;

  bool private _toggle;

  modifier GMEOpen {
    require(block.timestamp <= endTime, 'GME is over');
    _;
  }

  modifier GMEOver {
    require(block.timestamp > endTime, 'GME not over');
    _;
  }

  constructor(
    address _reserve,
    address _contribute,
    uint256 _endTime
  ) public {
    reserve = _reserve;
    contribute = _contribute;
    endTime = _endTime;
  }

  /// @notice Receives mUSD from accounts participating in the GME
  /// updating their internal balance.
  /// @dev Value to be deposited needs to be approved first.
  /// @param value The reserve amount being contributed.
  function deposit(uint256 value) external GMEOpen {
    require(value >= 0.01 ether, 'Minimum contribution is 0.01');
    IERC20(reserve).safeTransferFrom(msg.sender, address(this), value);

    balance[msg.sender] = balance[msg.sender].add(value);
    totalInvested = totalInvested.add(value);

    require(_invest(value), 'Investment failed');
    totalTokensReceived = totalTokenBalance();

    emit Deposit(msg.sender, value);
  }

  /// @notice Allows anyone to conclude the GME.
  function concludeGME() external GMEOver {
    IContribute(contribute).concludeGME();
  }

  /// @notice Calculates account share and sends acquired tokens
  // to account after GME event is over.
  function claim() external nonReentrant GMEOver {
    require(balance[msg.sender] > 0, 'No tokens to claim');

    uint256 share = _calculateShare(msg.sender);
    balance[msg.sender] = 0;

    IERC20(IContribute(contribute).token()).safeTransfer(msg.sender, share);
    emit Claim(msg.sender, share);
  }

  /// @notice Calculates account share
  /// @param account Address of the account to calculate the shares from.
  /// @return Total shares of given account.
  function getShare(address account) external view returns (uint256) {
    return _calculateShare(account);
  }

  /// @notice Funds deposited per account.
  /// @param account Address of the account to retrieve the balance from.
  /// @return Total funds deposited.
  function getBalance(address account) external view returns (uint256) {
    return balance[account];
  }

  /// @notice Total funds deposited into the Genesis contract.
  /// @return Current reserve balance of this contract.
  function totalReserveBalance() public view returns (uint256) {
    return IERC20(reserve).balanceOf(address(this));
  }

  /// @notice Total tokens minted to this contract.
  /// @return Current token balance of this contract.
  function totalTokenBalance() public view returns (uint256) {
    return IERC20(IContribute(contribute).token()).balanceOf(address(this));
  }

  /// @notice Worker function which invests the deposited amount.
  /// @param _amount Value to be invested.
  /// @return True if successful.
  function _invest(uint256 _amount) internal returns (bool) {
    IERC20(reserve).safeApprove(contribute, _amount);
    IContribute(contribute).genesisInvest(_amount);
    return true;
  }

  /// @notice Calculates share of a given account.
  /// @param _account Account to calculate the share from.
  /// @return Shares of given account.
  function _calculateShare(address _account) internal view returns (uint256) {
    // userShare*tokenSupply/totalInvested
    uint256 a = balance[_account].mul(totalTokensReceived);
    uint256 b = totalInvested;
    uint256 share = a.roundedDiv(b);
    return share;
  }
}