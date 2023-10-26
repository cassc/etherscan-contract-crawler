// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libraries/BoundedHistory.sol";
import "./external/council/libraries/Storage.sol";

import "./libraries/HashedStorageReentrancyBlock.sol";

import "./interfaces/IBaseVotingVault.sol";

import { BVV_NotManager, BVV_NotTimelock, BVV_ZeroAddress, BVV_UpperLimitBlock } from "./errors/Governance.sol";

/**
 * @title BaseVotingVault
 * @author Non-Fungible Technologies, Inc.
 *
 * This contract is a base voting vault contract for use with Arcade voting vaults.
 * It includes basic voting vault functions like querying vote power, setting
 * the timelock and manager addresses, and getting the contracts token balance.
 */
abstract contract BaseVotingVault is HashedStorageReentrancyBlock, IBaseVotingVault {
    // ======================================== STATE ==================================================

    // Bring libraries into scope
    using BoundedHistory for BoundedHistory.HistoricalBalances;

    // ============================================ STATE ===============================================

    /// @notice The token used for voting in this vault.
    IERC20 public immutable token;

    /// @notice Number of blocks after which history can be pruned.
    uint256 public immutable staleBlockLag;

    /// @dev Max length of any voting history. Prevents gas exhaustion
    ///      attacks from having too-large history.
    uint256 public constant MAX_HISTORY_LENGTH = 256;

    // ============================================ EVENTS ==============================================

    // Event to track delegation data
    event VoteChange(address indexed from, address indexed to, int256 amount);

    // ========================================== CONSTRUCTOR ===========================================

    /**
     * @notice Deploys a base voting vault, setting immutable values for the token
     *         and staleBlockLag.
     *
     * @param _token                     The external erc20 token contract.
     * @param _staleBlockLag             The number of blocks before which the delegation history is forgotten.
     */
    constructor(IERC20 _token, uint256 _staleBlockLag) {
        if (address(_token) == address(0)) revert BVV_ZeroAddress("token");
        if (_staleBlockLag >= block.number) revert BVV_UpperLimitBlock(_staleBlockLag);

        token = _token;
        staleBlockLag = _staleBlockLag;
    }

    // ==================================== TIMELOCK FUNCTIONALITY ======================================

    /**
     * @notice Timelock-only timelock update function.
     * @dev Allows the timelock to update the timelock address.
     *
     * @param timelock_                  The new timelock.
     */
    function setTimelock(address timelock_) external onlyTimelock {
        if (timelock_ == address(0)) revert BVV_ZeroAddress("timelock");

        Storage.set(Storage.addressPtr("timelock"), timelock_);
    }

    /**
     * @notice Timelock-only manager update function.
     * @dev Allows the timelock to update the manager address.
     *
     * @param manager_                   The new manager address.
     */
    function setManager(address manager_) external onlyTimelock {
        if (manager_ == address(0)) revert BVV_ZeroAddress("manager");

        Storage.set(Storage.addressPtr("manager"), manager_);
    }

    // ======================================= VIEW FUNCTIONS ===========================================

    /**
     * @notice Loads the voting power of a user.
     *
     * @param user                       The address we want to load the voting power of.
     * @param blockNumber                Block number to query the user's voting power at.
     *
     * @return votes                     The number of votes.
     */
    function queryVotePower(address user, uint256 blockNumber, bytes calldata) external override returns (uint256) {
        // Get our reference to historical data
        BoundedHistory.HistoricalBalances memory votingPower = _votingPower();

        // Find the historical data and clear everything more than 'staleBlockLag' into the past
        return votingPower.findAndClear(user, blockNumber, block.number - staleBlockLag);
    }

    /**
     * @notice Loads the voting power of a user without changing state.
     *
     * @param user                       The address we want to load the voting power of.
     * @param blockNumber                Block number to query the user's voting power at.
     *
     * @return votes                     The number of votes.
     */
    function queryVotePowerView(address user, uint256 blockNumber) external view returns (uint256) {
        // Get our reference to historical data
        BoundedHistory.HistoricalBalances memory votingPower = _votingPower();

        // Find the historical datum
        return votingPower.find(user, blockNumber);
    }

    /**
     * @notice A function to access the storage of the timelock address.
     * @dev The timelock can access all functions with the onlyTimelock modifier.
     *
     * @return timelock                  The timelock address.
     */
    function timelock() public view returns (address) {
        return _timelock().data;
    }

    /**
     * @notice A function to access the storage of the manager address.
     *
     * @dev The manager can access all functions with the onlyManager modifier.
     *
     * @return manager                   The manager address.
     */
    function manager() public view returns (address) {
        return _manager().data;
    }

    // =========================================== HELPERS ==============================================

    /**
     * @notice A function to access the storage of the token value
     *
     * @return balance                    A struct containing the balance uint.
     */
    function _balance() internal pure returns (Storage.Uint256 storage) {
        return Storage.uint256Ptr("balance");
    }

    /**
     * @notice A function to access the storage of the timelock address.
     *
     * @dev The timelock can access all functions with the onlyTimelock modifier.
     *
     * @return timelock                   A struct containing the timelock address.
     */
    function _timelock() internal view returns (Storage.Address storage) {
        return Storage.addressPtr("timelock");
    }

    /**
     * @notice A function to access the storage of the manager address.
     *
     * @dev The manager can access all functions with the onlyManager modifier.
     *
     * @return manager                    A struct containing the manager address.
     */
    function _manager() internal view returns (Storage.Address storage) {
        return Storage.addressPtr("manager");
    }

    /**
     * @notice Returns the historical voting power tracker.
     *
     * @return votingPower              Historical voting power tracker.
     */
    function _votingPower() internal pure returns (BoundedHistory.HistoricalBalances memory) {
        // This call returns a storage mapping with a unique non overwrite-able storage location.
        return BoundedHistory.load("votingPower");
    }

    /**
     * @notice Modifier to check that the caller is the manager.
     */
    modifier onlyManager() {
        if (msg.sender != manager()) revert BVV_NotManager();

        _;
    }

    /**
     * @notice Modifier to check that the caller is the timelock.
     */
    modifier onlyTimelock() {
        if (msg.sender != timelock()) revert BVV_NotTimelock();

        _;
    }
}