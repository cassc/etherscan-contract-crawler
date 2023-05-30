//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./math/SafeMathUint.sol";
import "./math/SafeMathInt.sol";

/// @title Dividend-Paying Token
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev A mintable ERC20 token that allows anyone to pay and distribute a target token
///  to token holders as dividends and allows token holders to withdraw their dividends.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
contract DividendToken is ERC20 {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;
  using SafeERC20 for IERC20;
  
  IERC20 public target;

  // With `magnitude`, we can properly distribute dividends even if the amount of received target is small.
  // For more discussion about choosing the value of `magnitude`,
  //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;

  // About dividendCorrection:
  // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
  // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
  //   `dividendOf(_user)` should not be changed,
  //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
  // To keep the `dividendOf(_user)` unchanged, we add a correction term:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
  //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
  //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
  // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  constructor(IERC20 target_, string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_) {
    _setupDecimals(decimals_);
    target = target_;
  }

  /// @notice Distributes target to token holders as dividends.
  /// @dev It reverts if the total supply of tokens is 0.
  /// It emits the `DividendsDistributed` event if the amount of received target is greater than 0.
  /// About undistributed target tokens:
  ///   In each distribution, there is a small amount of target not distributed,
  ///     the magnified amount of which is
  ///     `(amount * magnitude) % totalSupply()`.
  ///   With a well-chosen `magnitude`, the amount of undistributed target
  ///     (de-magnified) in a distribution can be less than 1 wei.
  ///   We can actually keep track of the undistributed target in a distribution
  ///     and try to distribute it in the next distribution,
  ///     but keeping track of such data on-chain costs much more than
  ///     the saved target, so we don't do that.
  function distributeDividends(uint amount) internal {
    require(totalSupply() > 0);
    require(amount > 0);

    magnifiedDividendPerShare = magnifiedDividendPerShare.add(
      (amount).mul(magnitude) / totalSupply()
    );

    target.safeTransferFrom(msg.sender, address(this), amount);

    emit DividendsDistributed(msg.sender, amount);
  }

  /// @notice Withdraws the target distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn target is greater than 0.
  function withdrawDividend(address user) internal {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      emit DividendWithdrawn(user, _withdrawableDividend);
      target.safeTransfer(user, _withdrawableDividend);
    }
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) public view returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) internal view returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) public view returns(uint256) {
    return withdrawnDividends[_owner];
  }


  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) public view returns(uint256) {
    return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }

  /// @dev Internal function that transfer tokens from one address to another.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param from The address to transfer from.
  /// @param to The address to transfer to.
  /// @param value The amount to be transferred.
  function _transfer(address from, address to, uint256 value) internal override {
    super._transfer(from, to, value);

    int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
    magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
    magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
  }

  /// @dev Internal function that mints tokens to an account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account that will receive the created tokens.
  /// @param value The amount that will be created.
  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  /// @dev Internal function that burns an amount of the token of a given account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account whose tokens will be burnt.
  /// @param value The amount that will be burnt.
  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  /// @dev This event MUST emit when target is distributed to token holders.
  /// @param from The address which sends target to this contract.
  /// @param weiAmount The amount of distributed target in wei.
  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount
  );

  /// @dev This event MUST emit when an address withdraws their dividend.
  /// @param to The address which withdraws target from this contract.
  /// @param weiAmount The amount of withdrawn target in wei.
  event DividendWithdrawn(
    address indexed to,
    uint256 weiAmount
  );
}