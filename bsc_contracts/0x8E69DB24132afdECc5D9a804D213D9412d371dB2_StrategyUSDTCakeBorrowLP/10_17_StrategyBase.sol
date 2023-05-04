// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "../utils/Ownable.sol";
import "../utils/Pausable.sol";

contract StrategyBase is Ownable, Pausable {
    address public manager;
    address public vault;
    address public strategist;

    uint256 public constant DIVISOR = 1000;
    uint256 public strategistFee = 100;
    uint256 public keeperFee = 100;

    constructor(
        address newManager,
        address newVault,
        address newStrategist
    ) {
        manager = newManager;
        vault = newVault;
        strategist = newStrategist;
    }

    // checks that caller is either owner or manager.
    modifier onlyManager() {
        require(msg.sender == owner() || msg.sender == manager, "Only Manager or Owner");
        _;
    }

    /**
     * @dev Updates address of the strat manager.
     * @param newManager new manager address.
     */
    function setManager(address newManager) external onlyManager {
        manager = newManager;
    }

    /**
     * @dev Updates parent vault.
     * @param newVault new vault address.
     */
    function setVault(address newVault) external onlyOwner {
        vault = newVault;
    }

    /**
     * @dev Updates Strategist.
     * @param newStrategist new strategist address.
     */
    function setStrategist(address newStrategist) external onlyOwner {
        strategist = newStrategist;
    }

    /**
     * @dev Updates Strategist Fee.
     * @param newStrategistFee new strategist address.
     */
    function setStrategistFee(uint256 newStrategistFee) external onlyOwner {
        strategistFee = newStrategistFee;
    }

    /**
     * @dev Function to synchronize balances before new user deposit.
     * Can be overridden in the strategy.
     */
    function beforeDeposit() external virtual {}
}