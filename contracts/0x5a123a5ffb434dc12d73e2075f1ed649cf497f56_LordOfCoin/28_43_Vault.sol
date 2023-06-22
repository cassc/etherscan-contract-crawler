// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import './interfaces/IVault.sol';
import './interfaces/IMStable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

/// @dev Ownable is used because solidity complain trying to deploy a contract whose code is too large when everything is added into Lord of Coin contract.
/// The only owner function is `init` which is to setup for the first time after deployment.
/// After init finished, owner will be renounced automatically. owner() function will return 0x0 address.
contract Vault is Ownable {
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
    address public musd;

    /// @notice LoC address
    address public controller;

    constructor(address _musd, address _nexus) public {
        // Set mUSD address
        musd = _musd;
        // Set nexus governance address
        nexusGovernance = _nexus;
        // Get mStable savings contract
        savingsContract = _fetchMStableSavings();
        // Approve savings contract to spend mUSD on this contract
        _approveMax(musd, savingsContract);
    }

    /* ========== Modifiers ========== */

    modifier onlyController {
        require(msg.sender == controller, 'Controller only');
        _;
    }

    /* ========== Owner Only ========== */

    /// @notice Setup for the first time after deploy and renounce ownership immediately.
    function init(address _controller) external onlyOwner {
        // Set Lord of coin
        controller = _controller;

        // Renounce ownership immediately after init
        renounceOwnership();
    }

    /* ========== Controller Only ========== */

    /// @notice Deposits reserve into savingsAccount.
    /// @dev It is part of Vault's interface.
    /// @param amount Value to be deposited.
    function deposit(uint256 amount) external onlyController {
        require(amount > 0, 'Cannot deposit 0');

        // Transfer mUSD from sender to this contract
        IERC20(musd).safeTransferFrom(msg.sender, address(this), amount);
        // Send to savings account
        IMStable(savingsContract).depositSavings(amount);
    }

    /// @notice Redeems reserve from savingsAccount.
    /// @dev It is part of Vault's interface.
    /// @param amount Value to be redeemed.
    function redeem(uint256 amount) external onlyController {
        require(amount > 0, 'Cannot redeem 0');

        // Redeem the amount in credits
        uint256 credited = IMStable(savingsContract).redeem(_getRedeemInput(amount));
        // Send credited amount to sender
        IERC20(musd).safeTransfer(msg.sender, credited);
    }

    /* ========== View ========== */

    /// @notice Returns balance in reserve from the savings contract.
    /// @dev It is part of Vault's interface.
    /// @return balance Reserve amount in the savings contract.
    function getBalance() public view returns (uint256 balance) {
        // Get balance in credits amount
        balance = IMStable(savingsContract).creditBalances(address(this));
        // Convert credits to reserve amount
        if (balance > 0) {
            balance = balance.mul(IMStable(savingsContract).exchangeRate()).div(1e18);
        }
    }

    /* ========== Mutative ========== */

    /// @notice Allows anyone to migrate all reserve to new savings contract.
    /// @dev Only use if the savingsContract has been changed by governance.
    function migrateSavings() external {
        address currentSavingsContract = _fetchMStableSavings();
        require(currentSavingsContract != savingsContract, 'Already on latest contract');
        _swapSavingsContract();
    }

    /* ========== Internal ========== */

    /// @notice Convert amount to mStable credits amount for redeem.
    function _getRedeemInput(uint256 amount) internal view returns (uint256 credits) {
        // Add 1 because the amounts always round down
        // e.g. i have 51 credits, e4 10 = 20.4
        // to withdraw 20 i need 20*10/4 = 50 + 1
        credits = amount.mul(1e18).div(IMStable(savingsContract).exchangeRate()).add(1);
    }

    /// @notice Approve spender to max.
    function _approveMax(address token, address spender) internal {
        uint256 max = uint256(- 1);
        IERC20(token).safeApprove(spender, max);
    }

    /// @notice Gets the current mStable Savings Contract address.
    /// @return address of mStable Savings Contract.
    function _fetchMStableSavings() internal view returns (address) {
        address manager = IMStable(nexusGovernance).getModule(keccak256('SavingsManager'));
        return IMStable(manager).savingsContracts(musd);
    }

    /// @notice Worker function that swaps the reserve to a new savings contract.
    function _swapSavingsContract() internal {
        // Get all savings balance
        uint256 balance = getBalance();
        // Redeem the amount in credits
        uint256 credited = IMStable(savingsContract).redeem(_getRedeemInput(balance));

        // Get new savings contract
        savingsContract = _fetchMStableSavings();
        // Approve new savings contract as mUSD spender
        _approveMax(musd, savingsContract);

        // Send to new savings account
        IMStable(savingsContract).depositSavings(credited);

        // Emit event
        emit FundMigration(balance);
    }
}