// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.7.0;

import './interfaces/IVault.sol';
import './interfaces/IMStable.sol';
import './mock/NexusMock.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';

contract Vault is IVault, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event FundMigration(uint256 value);

  /// @notice mStable governance proxy contract.
  /// It should not change.
  address public nexusGovernance;

  /// @notice mStable savingsContract contract.
  /// It can be changed through governance.
  address public savingsContract;

  /// @notice mUSD address.
  address public override reserve;

  /// @notice Balance tracker of accounts who have deposited funds.
  mapping(address => uint256) balance;

  constructor(address _reserve, address _nexus) public {
    reserve = _reserve;
    nexusGovernance = _nexus;
    savingsContract = _fetchMStableSavings();
    _approveMax(reserve, savingsContract);
  }

  /// @notice Deposits reserve into savingsAccount.
  /// @dev It is part of Vault's interface.
  /// @param amount Value to be deposited.
  /// @return True if successful.
  function deposit(uint256 amount) public override returns (bool) {
    require(amount > 0, 'Amount must be greater than 0');

    IERC20(reserve).safeTransferFrom(msg.sender, address(this), amount);
    balance[msg.sender] = balance[msg.sender].add(amount);

    _sendToSavings(amount);

    return true;
  }

  /// @notice Redeems reserve from savingsAccount.
  /// @dev It is part of Vault's interface.
  /// @param amount Value to be redeemed.
  /// @return True if successful.
  function redeem(uint256 amount) public override nonReentrant returns (bool) {
    require(amount > 0, 'Amount must be greater than 0');
    require(amount <= balance[msg.sender], 'Not enough funds');

    balance[msg.sender] = balance[msg.sender].sub(amount);

    _redeemFromSavings(msg.sender, amount);

    return true;
  }

  /// @notice Returns balance in reserve from the savings contract.
  /// @dev It is part of Vault's interface.
  /// @return Reserve amount in the savings contract.
  function getBalance() public override view returns (uint256) {
    uint256 _balance = IMStable(savingsContract).creditBalances(address(this));

    if (_balance > 0) {
      _balance = _balance.mul(IMStable(savingsContract).exchangeRate()).div(1e18);
    }

    return _balance;
  }

  /// @notice Allows anyone to migrate all reserve to new savings contract.
  /// @dev It is only triggered if the savingsContract has been changed by governance.
  function migrateSavings() external {
    address currentSavingsContract = _fetchMStableSavings();
    require(currentSavingsContract != savingsContract, 'Already using latest Savings Contract');
    _swap();
  }

  function _approveMax(address token, address spender) internal {
    uint256 max = uint256(-1);
    IERC20(token).safeApprove(spender, max);
  }

  // @notice Gets the current mStable Savings Contract address.
  // @return address of mStable Savings Contract.
  function _fetchMStableSavings() internal view returns (address) {
    address manager = IMStable(nexusGovernance).getModule(keccak256('SavingsManager'));
    return IMStable(manager).savingsContracts(reserve);
  }

  // @notice Worker function to send funds to savings account.
  // @param _amount The amount to send.
  function _sendToSavings(uint256 _amount) internal {
    if (IERC20(reserve).allowance(address(this), savingsContract) < _amount) {
      _approveMax(reserve, savingsContract);
    }

    IMStable(savingsContract).depositSavings(_amount);
  }

  // @notice Worker function to redeems funds from savings account.
  // @param _account The account to redeem to.
  // @param _amount The amount to redeem.
  function _redeemFromSavings(address _account, uint256 _amount) internal {
    // transform amount to credits with a hack because of rouding issues
    uint256 credits = _amount.mul(1e18).div(IMStable(savingsContract).exchangeRate()).add(1);
    // redeem the amount in credits
    uint256 credited = IMStable(savingsContract).redeem(credits);

    IERC20(reserve).safeTransfer(_account, credited);
  }

  /// @notice Worker function that swaps the reserve to a new savings contract.
  function _swap() internal {
    uint256 _balance = getBalance();
    _redeemFromSavings(address(this), _balance);
    savingsContract = _fetchMStableSavings();
    _approveMax(reserve, savingsContract);
    _sendToSavings(_balance);
    emit FundMigration(_balance);
  }
}