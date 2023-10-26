// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IArcadeTreasury.sol";

import {
    T_ZeroAddress,
    T_ZeroAmount,
    T_ThresholdsNotAscending,
    T_ArrayLengthMismatch,
    T_CallFailed,
    T_BlockSpendLimit,
    T_InvalidTarget,
    T_InvalidAllowance,
    T_CoolDownPeriod
} from "./errors/Treasury.sol";

/**
 * @title ArcadeTreasury
 * @author Non-Fungible Technologies, Inc.
 *
 * This contract is used to hold funds for the Arcade treasury. Each token held by this
 * contract has three thresholds associated with it: (1) large amount, (2) medium amount,
 * and (3) small amount. The only way to modify these thresholds is via the governance
 * timelock which holds the ADMIN role.
 *
 * For each spend threshold, there is a corresponding spend function which can be called by
 * only the CORE_VOTING_ROLE. In the Core Voting contract, a custom quorum for each
 * spend function shall be set to the appropriate threshold.
 *
 * In order to enable the GSC to execute smaller spends from the Treasury without going
 * through the entire governance process, the GSC has an allowance for each token. The
 * GSC can spend up to the allowance amount for each token. The GSC allowance can be updated
 * by the contract's ADMIN role. When updating the GSC's allowance for a specific token,
 * the allowance cannot be higher than the small threshold set for the token. This is to
 * force spends larger than the small threshold to always be voted on by governance.
 * Additionally, there is a cool down period between each GSC allowance update of 7 days.
 */
contract ArcadeTreasury is IArcadeTreasury, AccessControlEnumerable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice access control roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant GSC_CORE_VOTING_ROLE = keccak256("GSC_CORE_VOTING");
    bytes32 public constant CORE_VOTING_ROLE = keccak256("CORE_VOTING");

    /// @notice constant which represents ether
    address internal constant ETH_CONSTANT = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// @notice constant which represents the minimum amount of time between allowance sets
    uint48 public constant SET_ALLOWANCE_COOL_DOWN = 7 days;

    /// @notice the last timestamp when the allowance was set for a token
    mapping(address => uint48) public lastAllowanceSet;

    /// @notice mapping of token address to spend thresholds
    mapping(address => SpendThreshold) public spendThresholds;

    /// @notice mapping of token address to GSC allowance amount
    mapping(address => uint256) public gscAllowance;

    /// @notice mapping to track the amount spent in a block by threshold level, including approvals
    mapping(uint256 => mapping(uint256 => uint256)) public blockExpenditure;

    /// @notice event emitted when a token's spend thresholds are updated
    event SpendThresholdsUpdated(address indexed token, SpendThreshold thresholds);

    /// @notice event emitted when a token is spent
    event TreasuryTransfer(address indexed token, address indexed destination, uint256 amount);

    /// @notice event emitted when a token amount is approved for spending
    event TreasuryApproval(address indexed token, address indexed spender, uint256 amount);

    /// @notice event emitted when the GSC allowance is updated for a token
    event GSCAllowanceUpdated(address indexed token, uint256 amount);

    /**
     * @notice contract constructor
     *
     * @param _timelock              address of the timelock contract
     */
    constructor(address _timelock) {
        if (_timelock == address(0)) revert T_ZeroAddress("timelock");

        _setupRole(ADMIN_ROLE, _timelock);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(GSC_CORE_VOTING_ROLE, ADMIN_ROLE);
        _setRoleAdmin(CORE_VOTING_ROLE, ADMIN_ROLE);
    }

    // =========== ONLY AUTHORIZED ===========

    // ===== TRANSFERS =====

    /**
     * @notice function for the GSC to spend tokens from the treasury. The amount to be
     *         spent must be less than or equal to the GSC's allowance for that specific token.
     *
     * @param token             address of the token to spend
     * @param amount            amount of tokens to spend
     * @param destination       address to send the tokens to
     */
    function gscSpend(
        address token,
        uint256 amount,
        address destination
    ) external onlyRole(GSC_CORE_VOTING_ROLE) nonReentrant {
        if (destination == address(0)) revert T_ZeroAddress("destination");
        if (amount == 0) revert T_ZeroAmount();
        uint256 smallThreshold = spendThresholds[token].small;
        if (smallThreshold == 0) revert T_InvalidTarget(token);

        // Will underflow if amount is greater than remaining allowance
        gscAllowance[token] -= amount;

        _spend(token, amount, destination, smallThreshold);
    }

    /**
     * @notice function to spend a small amount of tokens from the treasury. This function
     *         should have the lowest quorum of the three spend functions.
     *
     * @param token             address of the token to spend
     * @param amount            amount of tokens to spend
     * @param destination       address to send the tokens to
     */
    function smallSpend(
        address token,
        uint256 amount,
        address destination
    ) external onlyRole(CORE_VOTING_ROLE) nonReentrant {
        if (destination == address(0)) revert T_ZeroAddress("destination");
        if (amount == 0) revert T_ZeroAmount();
        uint256 smallThreshold = spendThresholds[token].small;
        if (smallThreshold == 0) revert T_InvalidTarget(token);

        _spend(token, amount, destination, smallThreshold);
    }

    /**
     * @notice function to spend a medium amount of tokens from the treasury. This function
     *         should have the middle quorum of the three spend functions.
     *
     * @param token             address of the token to spend
     * @param amount            amount of tokens to spend
     * @param destination       address to send the tokens to
     */
    function mediumSpend(
        address token,
        uint256 amount,
        address destination
    ) external onlyRole(CORE_VOTING_ROLE) nonReentrant {
        if (destination == address(0)) revert T_ZeroAddress("destination");
        if (amount == 0) revert T_ZeroAmount();
        uint256 mediumThreshold = spendThresholds[token].medium;
        if (mediumThreshold == 0) revert T_InvalidTarget(token);

        _spend(token, amount, destination, mediumThreshold);
    }

    /**
     * @notice function to spend a large amount of tokens from the treasury. This function
     *         should have the highest quorum of the three spend functions.
     *
     * @param token             address of the token to spend
     * @param amount            amount of tokens to spend
     * @param destination       address to send the tokens to
     */
    function largeSpend(
        address token,
        uint256 amount,
        address destination
    ) external onlyRole(CORE_VOTING_ROLE) nonReentrant {
        if (destination == address(0)) revert T_ZeroAddress("destination");
        if (amount == 0) revert T_ZeroAmount();
        uint256 largeThreshold = spendThresholds[token].large;
        if (largeThreshold == 0) revert T_InvalidTarget(token);

        _spend(token, amount, destination, largeThreshold);
    }

    // ===== APPROVALS =====

    /**
     * @notice function for the GSC to approve tokens to be pulled from the treasury. The amount to
     *         be approved must be less than or equal to the GSC's allowance for that specific token.
     *
     * @param token             address of the token to approve
     * @param spender           address which can take the tokens
     * @param amount            amount of tokens to approve
     */
    function gscApprove(
        address token,
        address spender,
        uint256 amount
    ) external onlyRole(GSC_CORE_VOTING_ROLE) nonReentrant {
        if (spender == address(0)) revert T_ZeroAddress("spender");
        if (token == address(0)) revert T_ZeroAddress("token");
        uint256 smallThreshold = spendThresholds[token].small;
        if (smallThreshold == 0) revert T_InvalidTarget(token);

        // get spender's current allowance
        uint256 currentAllowance = IERC20(token).allowance(address(this), spender);

        // if amount is greater than current allowance, decrease gscAllowance by the difference
        if (amount > currentAllowance) {
            gscAllowance[token] -= amount - currentAllowance;
            _approve(token, spender, amount, currentAllowance, smallThreshold);
        }
        // if amount is less than current allowance, increase gscAllowance by the difference
        if (amount < currentAllowance) {
            gscAllowance[token] += currentAllowance - amount;
            _approve(token, spender, amount, currentAllowance, smallThreshold);
        }
    }

    /**
     * @notice function to approve a small amount of tokens from the treasury. This function
     *         should have the lowest quorum of the three approve functions.
     *
     * @param token             address of the token to approve
     * @param spender           address which can take the tokens
     * @param amount            amount of tokens to approve
     */
    function approveSmallSpend(
        address token,
        address spender,
        uint256 amount
    ) external onlyRole(CORE_VOTING_ROLE) nonReentrant {
        if (spender == address(0)) revert T_ZeroAddress("spender");
        if (token == address(0)) revert T_ZeroAddress("token");
        uint256 smallThreshold = spendThresholds[token].small;
        if (smallThreshold == 0) revert T_InvalidTarget(token);

        // get spender's current allowance
        uint256 currentAllowance = IERC20(token).allowance(address(this), spender);

        _approve(token, spender, amount, currentAllowance, smallThreshold);
    }

    /**
     * @notice function to approve a medium amount of tokens from the treasury. This function
     *         should have the middle quorum of the three approve functions.
     *
     * @param token             address of the token to approve
     * @param spender           address which can take the tokens
     * @param amount            amount of tokens to approve
     */
    function approveMediumSpend(
        address token,
        address spender,
        uint256 amount
    ) external onlyRole(CORE_VOTING_ROLE) nonReentrant {
        if (spender == address(0)) revert T_ZeroAddress("spender");
        if (token == address(0)) revert T_ZeroAddress("token");
        uint256 mediumThreshold = spendThresholds[token].medium;
        if (mediumThreshold == 0) revert T_InvalidTarget(token);

        // get spender's current allowance
        uint256 currentAllowance = IERC20(token).allowance(address(this), spender);

        _approve(token, spender, amount, currentAllowance, mediumThreshold);
    }

    /**
     * @notice function to approve a large amount of tokens from the treasury. This function
     *         should have the highest quorum of the three approve functions.
     *
     * @param token             address of the token to approve
     * @param spender           address which can take the tokens
     * @param amount            amount of tokens to approve
     */
    function approveLargeSpend(
        address token,
        address spender,
        uint256 amount
    ) external onlyRole(CORE_VOTING_ROLE) nonReentrant {
        if (spender == address(0)) revert T_ZeroAddress("spender");
        if (token == address(0)) revert T_ZeroAddress("token");
        uint256 largeThreshold = spendThresholds[token].large;
        if (largeThreshold == 0) revert T_InvalidTarget(token);

        // get spender's current allowance
        uint256 currentAllowance = IERC20(token).allowance(address(this), spender);

        _approve(token, spender, amount, currentAllowance, largeThreshold);
    }

    // ============== ONLY ADMIN ==============

    /**
     * @notice function to set the spend/approve thresholds for a token. This function is only
     *         callable by the contract admin.
     *
     * @param token             address of the token to set the thresholds for
     * @param thresholds        struct containing the thresholds to set
     */
    function setThreshold(address token, SpendThreshold memory thresholds) external onlyRole(ADMIN_ROLE) {
        // verify that the token is not the zero address
        if (token == address(0)) revert T_ZeroAddress("token");
        // verify small threshold is not zero
        if (thresholds.small == 0) revert T_ZeroAmount();

        // enforce cool down period
        if (uint48(block.timestamp) < lastAllowanceSet[token] + SET_ALLOWANCE_COOL_DOWN) {
            revert T_CoolDownPeriod(block.timestamp, lastAllowanceSet[token] + SET_ALLOWANCE_COOL_DOWN);
        }

        // verify thresholds are ascending from small to large
        if (thresholds.large <= thresholds.medium || thresholds.medium <= thresholds.small) {
            revert T_ThresholdsNotAscending();
        }

        // if gscAllowance is greater than new small threshold, set it to the new small threshold
        if (thresholds.small < gscAllowance[token]) {
            gscAllowance[token] = thresholds.small;

            emit GSCAllowanceUpdated(token, thresholds.small);
        }

        // update allowance state
        lastAllowanceSet[token] = uint48(block.timestamp);
        // Overwrite the spend limits for specified token
        spendThresholds[token] = thresholds;

        emit SpendThresholdsUpdated(token, thresholds);
    }

    /**
     * @notice function to set the GSC allowance for a token. This function is only callable
     *         by the contract admin. The new allowance must be less than or equal to the small
     *         spend threshold for that specific token. There is a cool down period of 7 days
     *         after this function has been called where it cannot be called again. Once the cooldown
     *         period is over the allowance can be updated by the admin again.
     *
     * @param token             address of the token to set the allowance for
     * @param newAllowance      new allowance amount to set
     */
    function setGSCAllowance(address token, uint256 newAllowance) external onlyRole(ADMIN_ROLE) {
        if (token == address(0)) revert T_ZeroAddress("token");
        if (newAllowance == 0) revert T_ZeroAmount();

        // enforce cool down period
        if (uint48(block.timestamp) < lastAllowanceSet[token] + SET_ALLOWANCE_COOL_DOWN) {
            revert T_CoolDownPeriod(block.timestamp, lastAllowanceSet[token] + SET_ALLOWANCE_COOL_DOWN);
        }

        uint256 spendLimit = spendThresholds[token].small;
        // new limit cannot be more than the small threshold
        if (newAllowance > spendLimit) {
            revert T_InvalidAllowance(newAllowance, spendLimit);
        }

        // update allowance state
        lastAllowanceSet[token] = uint48(block.timestamp);
        gscAllowance[token] = newAllowance;

        emit GSCAllowanceUpdated(token, newAllowance);
    }

    /**
     * @notice function to execute arbitrary calls from the treasury. This function is only
     *         callable by the contract admin. All calls are executed in order, and if any of them fail
     *         the entire transaction is reverted.
     *
     * @param targets           array of addresses to call
     * @param calldatas         array of bytes data to use for each call
     */
    function batchCalls(
        address[] memory targets,
        bytes[] calldata calldatas
    ) external onlyRole(ADMIN_ROLE) nonReentrant {
        if (targets.length != calldatas.length) revert T_ArrayLengthMismatch();
        // execute a package of low level calls
        for (uint256 i = 0; i < targets.length; ++i) {
            if (spendThresholds[targets[i]].small != 0) revert T_InvalidTarget(targets[i]);
            (bool success, ) = targets[i].call(calldatas[i]);
            // revert if a single call fails
            if (!success) revert T_CallFailed();
        }
    }

    // =============== HELPERS ===============

    /**
     * @notice Helper function to send tokens from the treasury. This function is used by the
     *         small, medium, and large transfer functions to send tokens to their destination.
     *
     * @param token             address of the token to spend
     * @param amount            amount of tokens to spend
     * @param destination       recipient of the transfer
     * @param limit             max tokens that can be spent/approved in a single block for this threshold
     */
    function _spend(address token, uint256 amount, address destination, uint256 limit) internal {
        // check that after spending we will not have spent more than the block limit
        uint256 spentThisBlock = blockExpenditure[block.number][limit];
        if (amount + spentThisBlock > limit) revert T_BlockSpendLimit();
        blockExpenditure[block.number][limit] = amount + spentThisBlock;

        // transfer tokens
        if (address(token) == ETH_CONSTANT) {
            // will out-of-gas revert if recipient is a contract with logic inside receive()
            payable(destination).transfer(amount);
        } else {
            IERC20(token).safeTransfer(destination, amount);
        }

        emit TreasuryTransfer(token, destination, amount);
    }

    /**
     * @notice Helper function to approve tokens from the treasury. This function is used by the
     *         approve functions to either increase or decrease a token approval for the specified
     *         spender.
     *
     * @param token               address of the token to approve
     * @param spender             address to approve
     * @param amount              amount of tokens to approve
     * @param currentAllowance    current allowance for the spender
     * @param limit               max tokens that can be spent/approved in a single block for this threshold
     */
    function _approve(
        address token,
        address spender,
        uint256 amount,
        uint256 currentAllowance,
        uint256 limit
    ) internal {
        // check that after approving we will not have spent more than the block limit
        uint256 spentThisBlock = blockExpenditure[block.number][limit];
        if (amount + spentThisBlock > limit) revert T_BlockSpendLimit();
        blockExpenditure[block.number][limit] = amount + spentThisBlock;

        // approve tokens
        if (amount < currentAllowance) {
            // if the new allowance is less than the current allowance, decrease it
            IERC20(token).safeDecreaseAllowance(spender, currentAllowance - amount);
            emit TreasuryApproval(token, spender, amount);
        }
        if (amount > currentAllowance) {
            // if the new allowance is more than the current allowance, increase it
            IERC20(token).safeIncreaseAllowance(spender, amount - currentAllowance);
            emit TreasuryApproval(token, spender, amount);
        }
    }

    /// @notice do not execute code on receiving ether
    receive() external payable {}
}