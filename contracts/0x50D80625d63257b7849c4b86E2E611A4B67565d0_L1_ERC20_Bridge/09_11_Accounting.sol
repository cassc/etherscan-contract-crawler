// SPDX-License-Identifier: MIT

/***
 *      ______             _______   __                                             
 *     /      \           |       \ |  \                                            
 *    |  $$$$$$\ __    __ | $$$$$$$\| $$  ______    _______  ______ ____    ______  
 *    | $$$\| $$|  \  /  \| $$__/ $$| $$ |      \  /       \|      \    \  |      \ 
 *    | $$$$\ $$ \$$\/  $$| $$    $$| $$  \$$$$$$\|  $$$$$$$| $$$$$$\$$$$\  \$$$$$$\
 *    | $$\$$\$$  >$$  $$ | $$$$$$$ | $$ /      $$ \$$    \ | $$ | $$ | $$ /      $$
 *    | $$_\$$$$ /  $$$$\ | $$      | $$|  $$$$$$$ _\$$$$$$\| $$ | $$ | $$|  $$$$$$$
 *     \$$  \$$$|  $$ \$$\| $$      | $$ \$$    $$|       $$| $$ | $$ | $$ \$$    $$
 *      \$$$$$$  \$$   \$$ \$$       \$$  \$$$$$$$ \$$$$$$$  \$$  \$$  \$$  \$$$$$$$
 *                                                                                  
 *                                                                                  
 *                                                                                  
 */
 
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @dev Accounting is an abstract contract that encapsulates the most critical logic in the HyperLoop contracts.
 * The accounting system works by using two balances that can only increase `_credit` and `_debit`.
 * A executor's available balance is the total credit minus the total debit. The contract exposes
 * two external functions that allows a executor to stake and unstake and exposes two internal
 * functions to its child contracts that allow the child contract to add to the credit 
 * and debit balance. In addition, child contracts can override `_additionalDebit` to account
 * for any additional debit balance in an alternative way. Lastly, it exposes a modifier,
 * `requirePositiveBalance`, that can be used by child contracts to ensure the executor does not
 * use more than its available stake.
 */

abstract contract Accounting is ReentrancyGuard {
    using SafeMath for uint256;

    mapping(address => bool) private _isExecutor;

    mapping(address => uint256) private _credit;
    mapping(address => uint256) private _debit;

    event Stake (
        address indexed account,
        uint256 amount
    );

    event Unstake (
        address indexed account,
        uint256 amount
    );

    event ExecutorAdded (
        address indexed newExecutor
    );

    event ExecutorRemoved (
        address indexed previousExecutor
    );

    /* ========== Modifiers ========== */

    modifier onlyExecutor {
        require(_isExecutor[msg.sender], "ACT: Caller is not executor");
        _;
    }

    modifier onlyGovernance {
        _requireIsGovernance();
        _;
    }

    /// @dev Used by parent contract to ensure that the Executor is solvent at the end of the transaction.
    modifier requirePositiveBalance {
        _;
        require(getCredit(msg.sender) >= getDebitAndAdditionalDebit(msg.sender), "ACT: Not enough available credit");
    }

    /// @dev Sets the Executor addresses
    constructor(address[] memory executors) public {
        for (uint256 i = 0; i < executors.length; i++) {
            require(_isExecutor[executors[i]] == false, "ACT: Cannot add duplicate executor");
            _isExecutor[executors[i]] = true;
            emit ExecutorAdded(executors[i]);
        }
    }

    /* ========== Virtual functions ========== */
    /**
     * @dev The following functions are overridden in L1Loop and L2Loop
     */
    function _transferFromBridge(address recipient, uint256 amount) internal virtual;
    function _transferToBridge(address from, uint256 amount) internal virtual;
    function _requireIsGovernance() internal virtual;

    /**
     * @dev This function can be optionally overridden by a parent contract to track any additional
     * debit balance in an alternative way.
     */
    function _additionalDebit(address /*executor*/) internal view virtual returns (uint256) {
        this; // Silence state mutability warning without generating any additional byte code
        return 0;
    }

    /* ========== Public/external getters ========== */

    /**
     * @dev Check if address is a Executor
     * @param maybeExecutor The address being checked
     * @return true if address is a Executor
     */
    function getIsExecutor(address maybeExecutor) public view returns (bool) {
        return _isExecutor[maybeExecutor];
    }

    /**
     * @dev Get the Executor's credit balance
     * @param executor The owner of the credit balance being checked
     * @return The credit balance for the Executor
     */
    function getCredit(address executor) public view returns (uint256) {
        return _credit[executor];
    }

    /**
     * @dev Gets the debit balance tracked by `_debit` and does not include `_additionalDebit()`
     * @param executor The owner of the debit balance being checked
     * @return The debit amount for the Executor
     */
    function getRawDebit(address executor) external view returns (uint256) {
        return _debit[executor];
    }

    /**
     * @dev Get the Executor's total debit
     * @param executor The owner of the debit balance being checked
     * @return The Executor's total debit balance
     */
    function getDebitAndAdditionalDebit(address executor) public view returns (uint256) {
        return _debit[executor].add(_additionalDebit(executor));
    }

    /* ========== Executor external functions ========== */

    /** 
     * @dev Allows the Executor to deposit tokens and increase its credit balance
     * @param executor The address being staked on
     * @param amount The amount being staked
     */
    function stake(address executor, uint256 amount) external payable nonReentrant {
        require(_isExecutor[executor] == true, "ACT: Address is not executor");
        _transferToBridge(msg.sender, amount);
        _addCredit(executor, amount);

        emit Stake(executor, amount);
    }

    /**
     * @dev Allows the caller to withdraw any available balance and add to their debit balance
     * @param amount The amount being unstaked
     */
    function unstake(uint256 amount) external requirePositiveBalance nonReentrant {
        _addDebit(msg.sender, amount);
        _transferFromBridge(msg.sender, amount);

        emit Unstake(msg.sender, amount);
    }

    /**
     * @dev Add Executor to allowlist
     * @param executor The address being added as a Executor
     */
    function addExecutor(address executor) external onlyGovernance {
        require(_isExecutor[executor] == false, "ACT: Address is already executor");
        _isExecutor[executor] = true;

        emit ExecutorAdded(executor);
    }

    /**
     * @dev Remove Executor from allowlist
     * @param executor The address being removed as a Executor
     */
    function removeExecutor(address executor) external onlyGovernance {
        require(_isExecutor[executor] == true, "ACT: Address is not executor");
        _isExecutor[executor] = false;

        emit ExecutorRemoved(executor);
    }

    /* ========== Internal functions ========== */

    function _addCredit(address executor, uint256 amount) internal {
        _credit[executor] = _credit[executor].add(amount);
    }

    function _addDebit(address executor, uint256 amount) internal {
        _debit[executor] = _debit[executor].add(amount);
    }
}