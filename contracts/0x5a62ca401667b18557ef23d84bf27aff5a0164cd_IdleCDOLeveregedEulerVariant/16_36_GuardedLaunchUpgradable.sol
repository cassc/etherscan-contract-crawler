//SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @notice This abstract contract is used to add an updatable limit on the total value locked
/// that the contract can have. It also have an emergency method that allows the owner to pull
/// funds into predefined recovery address
/// @dev Inherit this contract and add the _guarded method to the child contract
abstract contract GuardedLaunchUpgradable is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  // ERROR MESSAGES:
  // 0 = is 0
  // 1 = already initialized
  // 2 = Contract limit reached

  // TVL limit in underlying value
  uint256 public limit;
  // recovery address
  address public governanceRecoveryFund;

  /// @param _limit TVL limit. (0 means unlimited)
  /// @param _governanceRecoveryFund recovery address
  /// @param _owner owner address
  function __GuardedLaunch_init(uint256 _limit, address _governanceRecoveryFund, address _owner) internal {
    require(_governanceRecoveryFund != address(0), '0');
    require(_owner != address(0), '0');
    // Initialize inherited contracts
    OwnableUpgradeable.__Ownable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
    // Initialize state variables
    limit = _limit;
    governanceRecoveryFund = _governanceRecoveryFund;
    // Transfer ownership
    transferOwnership(_owner);
  }

  /// @notice this check should be called inside the child contract on deposits to check that the
  /// TVL didn't exceed a threshold
  /// @param _amount new amount to deposit
  function _guarded(uint256 _amount) internal view {
    uint256 _limit = limit;
    if (_limit == 0) {
      return;
    }
    require(getContractValue() + _amount <= _limit, '2');
  }

  /// @dev Check that the second function is not called in the same tx from the same tx.origin
  function _checkOnlyOwner() internal view {
    require(owner() == msg.sender, '6');
  }

  /// @notice abstract method, should return the TVL in underlyings
  function getContractValue() public virtual view returns (uint256);

  /// @notice set contract TVL limit
  /// @param _limit limit in underlying value, 0 means no limit
  function _setLimit(uint256 _limit) external {
    _checkOnlyOwner();
    limit = _limit;
  }

  /// @notice Emergency method, tokens gets transferred to the governanceRecoveryFund address
  /// @param _token address of the token to transfer
  /// @param _value amount to transfer
  function transferToken(address _token, uint256 _value) external {
    _checkOnlyOwner();
    IERC20Upgradeable(_token).safeTransfer(governanceRecoveryFund, _value);
  }
}