// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "ConfirmedOwner.sol";
import "KeeperCompatibleInterface.sol";
import "Pausable.sol";
import "SafeERC20.sol";
import "Address.sol";
import "EnumerableSet.sol";

/**
 * @title The GasStationV2 Contract
 * @author 0xtritium.eth
 * @notice Custom implementation of Chainlink's EthBalanceMonitor. Ether
 * transferred is not limited anymore by topUpAmountWei, and a sweep function
 * makes it possible to retrieve ERC-20 tokens.  Allows better recipient management.
 * see https://docs.chain.link/chainlink-automation/utility-contracts/
 */
contract GasStationV2 is ConfirmedOwner, Pausable, KeeperCompatibleInterface {
    using EnumerableSet for EnumerableSet.AddressSet;
    // observed limit of 45K + 10k buffer
    uint256 private constant MIN_GAS_FOR_TRANSFER = 55_000;

    event FundsAdded(uint256 amountAdded, uint256 newBalance, address sender);
    event FundsWithdrawn(uint256 amountWithdrawn, address payee);
    event TopUpSucceeded(address indexed recipient);
    event TopUpFailed(address indexed recipient, uint256 amount);
    event KeeperUpdated(address oldAddress, address newAddress);
    event MinWaitPeriodUpdated(uint256 oldMinWaitPeriod, uint256 newMinWaitPeriod);
    event ERC20Swept(address indexed token, address payee, uint256 amount);
    event RecipientAdded(address recipient, uint96 minBalanceWei, uint96 topUpToAmountWei, bool update);
    event RecipientRemoved(address recipient);
    event RemoveNonexistentRecipient(address recipient);

    error BalanceTooHigh(address recipient, uint256 balance);
    error OnlyKeeperRegistry();
    error ZeroAddress();

    struct Target {
        bool isActive;
        uint96 minBalanceWei;
        uint96 topUpToAmountWei;
        uint56 lastTopUpTimestamp; // enough space for 2 trillion years
    }

    address public KeeperAddress;
    uint256 public MinWaitPeriodSeconds;

    EnumerableSet.AddressSet internal WatchList;
    mapping(address => Target) public recipientConfigs;

    /**
     * @param keeperAddress The address of the keeper registry contract
   * @param minWaitPeriodSeconds The minimum wait period for addresses between funding
   */
    constructor(address keeperAddress, uint256 minWaitPeriodSeconds) ConfirmedOwner(msg.sender) {
        setKeeperAddress(keeperAddress);
        setMinWaitPeriodSeconds(minWaitPeriodSeconds);
    }

    /**
   * @notice Adds/updates a list of recipients with the same configuration
   * @param recipients A list of recipients to be setup with the defined params amounts
   * @param minBalanceWei The balance that should cause a topup if a recipient falls under it.
   * @param topUpToAmountWei The wei amount that a wallet should be topped up to on topup.
   */
    function addRecipients(address[] calldata recipients, uint96 minBalanceWei, uint96 topUpToAmountWei) public onlyOwner {
        for (uint i = 0; i < recipients.length; i++) {
            bool update = WatchList.add(recipients[i]);
            // enumerableSet returns false if Already Exists
            Target memory target;
            target.isActive = true;
            target.minBalanceWei = minBalanceWei;
            target.topUpToAmountWei = topUpToAmountWei;
            // Clears any last run time stamp
            recipientConfigs[recipients[i]] = target;
            emit RecipientAdded(recipients[i], minBalanceWei, topUpToAmountWei, update);
        }
    }

    /**
   * @notice Removes Recipients
   */    function removeRecipients(address[] calldata recipients) public onlyOwner {
        for (uint i = 0; i < recipients.length; i++) {
            if (WatchList.remove(recipients[i])) {
                recipientConfigs[recipients[i]].isActive = false;
                emit RecipientRemoved(recipients[i]);
            } else {
                emit RemoveNonexistentRecipient(recipients[i]);
            }
        }
    }

    /**
   * @notice Gets a list of addresses that are under funded
   * @return list of addresses that are underfunded
   */
    function getUnderfundedAddresses() public view returns (address[] memory) {
        address[] memory watchList = getRecipientsList();
        address[] memory needsFunding = new address[](watchList.length);
        uint256 count = 0;
        uint256 minWaitPeriod = MinWaitPeriodSeconds;
        uint256 balance = address(this).balance;
        Target memory target;
        for (uint256 idx = 0; idx < WatchList.length(); idx++) {
            address recipient = WatchList.at(idx);
            target = recipientConfigs[recipient];
            if (recipient.balance < target.minBalanceWei) {// Wallet needs funding
                uint256 delta = target.topUpToAmountWei - recipient.balance;
                if (
                    target.lastTopUpTimestamp + minWaitPeriod <= block.timestamp && // Not too fast
                    balance >= delta // we have the bags
                ) {
                    needsFunding[count] = watchList[idx];
                    count++;
                    balance -= delta;
                }
            }
        }
        if (count != watchList.length) {
            assembly {
                mstore(needsFunding, count)
            }
        }
        return needsFunding;
    }

    /**
     * @notice Send funds to the addresses provided
   * @param needsFunding the list of addresses to fund (addresses must be pre-approved)
   */
    function topUpExact(address[] memory needsFunding) internal whenNotPaused {
        uint256 minWaitPeriodSeconds = MinWaitPeriodSeconds;
        Target memory target;
        for (uint256 idx = 0; idx < needsFunding.length; idx++) {
            target = recipientConfigs[needsFunding[idx]];
            uint256 delta = target.topUpToAmountWei - needsFunding[idx].balance;
            if (
                target.isActive &&
                target.lastTopUpTimestamp + minWaitPeriodSeconds <= block.timestamp // Not too fast
            // skip we have bags check as it will revert anyway + should never happen is not a security issue
            ) {
                bool success = payable(needsFunding[idx]).send(delta);
                if (needsFunding[idx].balance > target.topUpToAmountWei) {// We're not overfunding
                    revert BalanceTooHigh(needsFunding[idx], needsFunding[idx].balance);
                }
                if (success) {
                    recipientConfigs[needsFunding[idx]].lastTopUpTimestamp = uint56(block.timestamp);
                    emit TopUpSucceeded(needsFunding[idx]);
                } else {
                    emit TopUpFailed(needsFunding[idx], delta);
                }
            }
            if (gasleft() < MIN_GAS_FOR_TRANSFER) {
                emit TopUpFailed(needsFunding[idx], delta);
                return;
            }
        }
    }

    /**
     * @notice Get list of addresses that are underfunded and return keeper-compatible payload
   * @return upkeepNeeded signals if upkeep is needed, performData is an abi encoded list of addresses that need funds
   */
    function checkUpkeep(bytes calldata)
    external
    view
    override
    whenNotPaused
    returns (bool upkeepNeeded, bytes memory performData)
    {
        address[] memory needsFunding = getUnderfundedAddresses();
        upkeepNeeded = needsFunding.length > 0;
        performData = abi.encode(needsFunding);
        return (upkeepNeeded, performData);
    }

    /**
     * @notice Called by keeper to send funds to underfunded addresses
   * @param performData The abi encoded list of addresses to fund
   */
    function performUpkeep(bytes calldata performData) external override onlyKeeperRegistry whenNotPaused {
        address[] memory needsFunding = abi.decode(performData, (address[]));
        topUpExact(needsFunding);
    }

    /**
     * @notice Withdraws the contract balance
   * @param amount The amount of eth (in wei) to withdraw
   * @param payee The address to pay
   */
    function withdraw(uint256 amount, address payable payee) external onlyOwner {
        if (payee == address(0)) {
            revert ZeroAddress();
        }
        emit FundsWithdrawn(amount, payee);
        payee.transfer(amount);
    }

    /**
     * @notice Sweep the full contract's balance for a given ERC-20 token
   * @param token The ERC-20 token which needs to be swept
   * @param payee The address to pay
   */
    function sweep(address token, address payee) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        emit ERC20Swept(token, payee, balance);
        SafeERC20.safeTransfer(IERC20(token), payee, balance);
    }

    /**
     * @notice Receive funds
   */
    receive() external payable {
        emit FundsAdded(msg.value, address(this).balance, msg.sender);
    }

    /**
     * @notice Sets the keeper registry address
   */
    function setKeeperAddress(address keeperAddress) public onlyOwner {
        emit KeeperUpdated(KeeperAddress, keeperAddress);
        KeeperAddress = keeperAddress;
    }

    /**
     * @notice Sets the minimum wait period (in seconds) for addresses between funding
   */
    function setMinWaitPeriodSeconds(uint256 period) public onlyOwner {
        emit MinWaitPeriodUpdated(MinWaitPeriodSeconds, period);
        MinWaitPeriodSeconds = period;
    }

    /**
     * @notice Gets the keeper registry address
   */
    function getKeeperAddress() external view returns (address keeperAddress) {
        return KeeperAddress;
    }


    function getRecipientsList() public view returns (address[] memory) {
        uint256 len = WatchList.length();
        address[] memory recipients = new address[](len);
        for (uint i; i < len; i++) {
            recipients[i] = WatchList.at(i);
        }
        return recipients;
    }


    /**
     * @notice Pauses the contract, which prevents executing performUpkeep
   */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract
   */
    function unpause() external onlyOwner {
        _unpause();
    }

    modifier onlyKeeperRegistry() {
        if (msg.sender != KeeperAddress) {
            revert OnlyKeeperRegistry();
        }
        _;
    }
}