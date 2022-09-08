//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./IExternalBalanceIncentives.sol";
import "./LockBalanceIncentives.sol";

/// @title Balance incentives reward a balance over a period of time.
/// @notice Balances for accounts are updated by the balanceUpdater by calling changeBalance.
///         Accounts can claim tokens by calling claim
contract ExternalBalanceIncentives is LockBalanceIncentives, IExternalBalanceIncentives {
    /// @notice The address that can update balances in the contract
    address public balanceUpdaterAddress;

    /// @dev Reserves storage for future upgrades. Each contract will use exactly storage slot 1000 until 2000.
    ///      When adding new fields to this contract, one must decrement this counter proportional to the
    ///      number of uint256 slots used.
    //slither-disable-next-line unused-state
    uint256[986] private _____contractGap;

    /// @notice Only for testing our contract gap mechanism, never use in prod.
    //slither-disable-next-line constable-states,unused-state
    uint256 private ___storageMarker;

    function initialize(address _treasury, address _rewardsToken) external initializer {
        LockBalanceIncentives.initializeLockBalanceIncentives(_treasury, _rewardsToken);
    }

    /// @notice Updates the balance of an account
    /// @param _account the account to update
    /// @param _balance the new balance of the account
    function updateBalance(address _account, uint256 _balance)
        external
        override
        onlyBalanceUpdater
    {
        super.changeBalance(_account, _balance);
    }

    /// @notice Updates the address that can make balance updates
    /// @param _balanceUpdaterAddress The new address for the balance updater
    function setBalanceUpdaterAddress(address _balanceUpdaterAddress) external onlyOwner {
        require(_balanceUpdaterAddress != address(0), "Zero address");

        emit BalanceUpdaterAddressChange(balanceUpdaterAddress, _balanceUpdaterAddress);

        balanceUpdaterAddress = _balanceUpdaterAddress;
    }

    /// @dev Prevents calling a function from anyone except the balanceUpdaterAddress
    modifier onlyBalanceUpdater() {
        require(msg.sender == balanceUpdaterAddress, "Only balance updater");
        _;
    }

    /// @notice Emitted when the balanceUpdateAddress is changed
    /// @param oldBalanceUpdaterAddress The old address
    /// @param newBalanceUpdaterAddress The new address
    event BalanceUpdaterAddressChange(
        address oldBalanceUpdaterAddress,
        address newBalanceUpdaterAddress
    );
}