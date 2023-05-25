/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../library/AddArrayLib.sol";

import "../interfaces/ITradeExecutor.sol";
import "../interfaces/IVault.sol";

/// @title vault (Brahma Vault)
/// @author 0xAd1 and Bapireddy
/// @notice Minimal vault contract to support trades across different protocols.
contract Vault is IVault, ERC20Permit, ReentrancyGuard {
    using AddrArrayLib for AddrArrayLib.Addresses;
    using SafeERC20 for IERC20;
    /*///////////////////////////////////////////////////////////////
                                 CONSTANTS
    //////////////////////////////////////////////////////////////*/
    /// @notice The maximum number of blocks for latest update to be valid.
    /// @dev Needed for processing deposits/withdrawals.
    uint256 constant BLOCK_LIMIT = 50;
    /// @dev minimum balance used to check when executor is removed.
    uint256 constant DUST_LIMIT = 10**6;
    /// @dev The max basis points used as normalizing factor.
    uint256 constant MAX_BPS = 10000;
    /// @dev The max amount of seconds in year.
    /// accounting for leap years there are 365.25 days in year.
    ///  365.25 * 86400 = 31557600.0
    uint256 constant MAX_SECONDS = 31557600;

    /*///////////////////////////////////////////////////////////////
                                IMMUTABLES
    //////////////////////////////////////////////////////////////*/
    /// @notice The underlying token the vault accepts.
    address public immutable override wantToken;
    uint8 private immutable tokenDecimals;

    /*///////////////////////////////////////////////////////////////
                            MUTABLE ACCESS MODFIERS
    //////////////////////////////////////////////////////////////*/
    /// @notice boolean for enabling deposit/withdraw solely via batcher.
    bool public batcherOnlyDeposit;

    /// @notice boolean for enabling emergency mode to halt new withdrawal/deposits into vault.
    bool public emergencyMode;

    // @notice address of batcher used for batching user deposits/withdrawals.
    address public batcher;
    /// @notice keeper address to move funds between executors.
    address public override keeper;
    /// @notice Governance address to add/remove  executors.
    address public override governance;
    address public pendingGovernance;

    /// @notice Creates a new Vault that accepts a specific underlying token.
    /// @param _wantToken The ERC20 compliant token the vault should accept.
    /// @param _name The name of the vault token.
    /// @param _symbol The symbol of the vault token.
    /// @param _keeper The address of the keeper to move funds between executors.
    /// @param _governance The address of the governance to perform governance functions.
    constructor(
        string memory _name,
        string memory _symbol,
        address _wantToken,
        address _keeper,
        address _governance
    ) ERC20(_name, _symbol) ERC20Permit(_name) {
        tokenDecimals = IERC20Metadata(_wantToken).decimals();
        wantToken = _wantToken;
        keeper = _keeper;
        governance = _governance;
        // to prevent any front running deposits
        batcherOnlyDeposit = true;
    }

    function decimals() public view override returns (uint8) {
        return tokenDecimals;
    }

    /*///////////////////////////////////////////////////////////////
                       USER DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/
    /// @notice Initiates a deposit of want tokens to the vault.
    /// @param amountIn The amount of want tokens to deposit.
    /// @param receiver The address to receive vault tokens.
    function deposit(uint256 amountIn, address receiver)
        public
        override
        nonReentrant
        ensureFeesAreCollected
        returns (uint256 shares)
    {
        /// checks for only batcher deposit
        onlyBatcher();
        isValidAddress(receiver);
        require(amountIn > 0, "ZERO_AMOUNT");
        // calculate the shares based on the amount.
        shares = totalSupply() > 0
            ? (totalSupply() * amountIn) / totalVaultFunds()
            : amountIn;
        require(shares != 0, "ZERO_SHARES");
        IERC20(wantToken).safeTransferFrom(msg.sender, address(this), amountIn);
        _mint(receiver, shares);
    }

    /// @notice Initiates a withdrawal of vault tokens to the user.
    /// @param sharesIn The amount of vault tokens to withdraw.
    /// @param receiver The address to receive the vault tokens.
    function withdraw(uint256 sharesIn, address receiver)
        public
        override
        nonReentrant
        ensureFeesAreCollected
        returns (uint256 amountOut)
    {
        /// checks for only batcher withdrawal
        onlyBatcher();
        isValidAddress(receiver);
        require(sharesIn > 0, "ZERO_SHARES");
        // calculate the amount based on the shares.
        amountOut = (sharesIn * totalVaultFunds()) / totalSupply();
        // burn shares of msg.sender
        _burn(msg.sender, sharesIn);
        /// charging exitFee
        if (exitFee > 0) {
            uint256 fee = (amountOut * exitFee) / MAX_BPS;
            IERC20(wantToken).transfer(governance, fee);
            amountOut = amountOut - fee;
        }
        IERC20(wantToken).safeTransfer(receiver, amountOut);
    }

    /// @notice Calculates the total amount of underlying tokens the vault holds.
    /// @return The total amount of underlying tokens the vault holds.
    function totalVaultFunds() public view returns (uint256) {
        return
            IERC20(wantToken).balanceOf(address(this)) + totalExecutorFunds();
    }

    /*///////////////////////////////////////////////////////////////
                    EXECUTOR DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice list of trade executors connected to vault.
    AddrArrayLib.Addresses tradeExecutorsList;

    /// @notice Emitted after the vault deposits into a executor contract.
    /// @param executor The executor that was deposited into.
    /// @param underlyingAmount The amount of underlying tokens that were deposited.
    event ExecutorDeposit(address indexed executor, uint256 underlyingAmount);

    /// @notice Emitted after the vault withdraws funds from a executor contract.
    /// @param executor The executor that was withdrawn from.
    /// @param underlyingAmount The amount of underlying tokens that were withdrawn.
    event ExecutorWithdrawal(
        address indexed executor,
        uint256 underlyingAmount
    );

    /// @notice Deposit given amount of want tokens into valid executor.
    /// @param _executor The executor to deposit into.
    /// @param _amount The amount of want tokens to deposit.
    function depositIntoExecutor(address _executor, uint256 _amount)
        public
        nonReentrant
    {
        isActiveExecutor(_executor);
        onlyKeeper();
        require(_amount > 0, "ZERO_AMOUNT");
        IERC20(wantToken).safeTransfer(_executor, _amount);
        emit ExecutorDeposit(_executor, _amount);
    }

    /// @notice Withdraw given amount of want tokens into valid executor.
    /// @param _executor The executor to withdraw tokens from.
    /// @param _amount The amount of want tokens to withdraw.
    function withdrawFromExecutor(address _executor, uint256 _amount)
        public
        nonReentrant
    {
        isActiveExecutor(_executor);
        onlyKeeper();
        require(_amount > 0, "ZERO_AMOUNT");
        IERC20(wantToken).safeTransferFrom(_executor, address(this), _amount);
        emit ExecutorWithdrawal(_executor, _amount);
    }

    /*///////////////////////////////////////////////////////////////
                           FEE CONFIGURATION
    //////////////////////////////////////////////////////////////*/
    /// @notice lagging value of vault total funds.
    /// @dev value intialized to max to prevent slashing on first deposit.
    uint256 public prevVaultFunds = type(uint256).max;
    /// @dev value intialized to max to prevent slashing on first deposit.
    uint256 public lastReportedTime = type(uint256).max;
    /// @dev Perfomance fee for the vault.
    uint256 public performanceFee;
    /// @notice Fee denominated in MAX_BPS charged during exit.
    uint256 public exitFee;
    /// @notice Mangement fee for operating the vault.
    uint256 public managementFee;

    /// @notice Emitted after perfomance fee updation.
    /// @param oldFee The old performance fee on vault.
    /// @param newFee The new performance fee on vault.
    event UpdatePerformanceFee(uint256 oldFee, uint256 newFee);

    /// @notice Updates the performance fee on the vault.
    /// @param _fee The new performance fee on the vault.
    /// @dev The new fee must be always less than 50% of yield.
    function setPerformanceFee(uint256 _fee) public {
        onlyGovernance();
        require(_fee < MAX_BPS / 2, "FEE_TOO_HIGH");
        emit UpdatePerformanceFee(performanceFee, _fee);
        performanceFee = _fee;
    }

    /// @notice Emitted after exit fee updation.
    /// @param oldFee The old exit fee on vault.
    /// @param newFee The new exit fee on vault.
    event UpdateExitFee(uint256 oldFee, uint256 newFee);

    /// @notice Function to set exit fee on the vault, can only be called by governance
    /// @param _fee Address of fee
    function setExitFee(uint256 _fee) public {
        onlyGovernance();
        require(_fee < MAX_BPS / 2, "EXIT_FEE_TOO_HIGH");
        emit UpdateExitFee(exitFee, _fee);
        exitFee = _fee;
    }

    /// @notice Emitted after management fee updation.
    /// @param oldFee The old management fee on vault.
    /// @param newFee The new management fee on vault.
    event UpdateManagementFee(uint256 oldFee, uint256 newFee);

    /// @notice Function to set exit fee on the vault, can only be called by governance
    /// @param _fee Address of fee
    function setManagementFee(uint256 _fee) public {
        onlyGovernance();
        require(_fee < MAX_BPS / 2, "EXIT_FEE_TOO_HIGH");
        emit UpdateManagementFee(managementFee, _fee);
        managementFee = _fee;
    }

    /// @notice Emitted when a fees are collected.
    /// @param collectedFees The amount of fees collected.
    event FeesCollected(uint256 collectedFees);

    /// @notice Calculates and collects the fees from the vault.
    /// @dev This function sends all the accured fees to governance.
    /// checks the yield made since previous harvest and
    /// calculates the fee based on it. Also note: this function
    /// should be called before processing any new deposits/withdrawals.
    function collectFees() internal {
        uint256 currentFunds = totalVaultFunds();
        uint256 fees = 0;
        // collect fees only when profit is made.
        if ((performanceFee > 0) && (currentFunds > prevVaultFunds)) {
            uint256 yieldEarned = (currentFunds - prevVaultFunds);
            // normalization by MAX_BPS
            fees += ((yieldEarned * performanceFee) / MAX_BPS);
        }
        if ((managementFee > 0) && (lastReportedTime < block.timestamp)) {
            uint256 duration = block.timestamp - lastReportedTime;
            fees +=
                ((duration * managementFee * currentFunds) / MAX_SECONDS) /
                MAX_BPS;
        }
        if (fees > 0) {
            IERC20(wantToken).safeTransfer(governance, fees);
            emit FeesCollected(fees);
        }
    }

    modifier ensureFeesAreCollected() {
        collectFees();
        _;
        // update vault funds after fees are collected.
        prevVaultFunds = totalVaultFunds();
        // update lastReportedTime after fees are collected.
        lastReportedTime = block.timestamp;
    }

    /*///////////////////////////////////////////////////////////////
                    EXECUTOR ADDITION/REMOVAL LOGIC
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when executor is added to vault.
    /// @param executor The address of added executor.
    event ExecutorAdded(address indexed executor);

    /// @notice Emitted when executor is removed from vault.
    /// @param executor The address of removed executor.
    event ExecutorRemoved(address indexed executor);

    /// @notice Adds a trade executor, enabling it to execute trades.
    /// @param _tradeExecutor The address of _tradeExecutor contract.
    function addExecutor(address _tradeExecutor) public {
        onlyGovernance();
        isValidAddress(_tradeExecutor);
        require(
            ITradeExecutor(_tradeExecutor).vault() == address(this),
            "INVALID_VAULT"
        );
        require(
            IERC20(wantToken).allowance(_tradeExecutor, address(this)) > 0,
            "NO_ALLOWANCE"
        );
        tradeExecutorsList.pushAddress(_tradeExecutor);
        emit ExecutorAdded(_tradeExecutor);
    }

    /// @notice Adds a trade executor, enabling it to execute trades.
    /// @param _tradeExecutor The address of _tradeExecutor contract.
    /// @dev make sure all funds are withdrawn from executor before removing.
    function removeExecutor(address _tradeExecutor) public {
        onlyGovernance();
        isValidAddress(_tradeExecutor);
        // check if executor attached to vault.
        isActiveExecutor(_tradeExecutor);

        (uint256 executorFunds, uint256 blockUpdated) = ITradeExecutor(
            _tradeExecutor
        ).totalFunds();
        areFundsUpdated(blockUpdated);
        require(executorFunds < DUST_LIMIT, "FUNDS_TOO_HIGH");
        tradeExecutorsList.removeAddress(_tradeExecutor);
        emit ExecutorRemoved(_tradeExecutor);
    }

    /// @notice gives the number of trade executors.
    /// @return The number of trade executors.
    function totalExecutors() public view returns (uint256) {
        return tradeExecutorsList.size();
    }

    /// @notice Returns trade executor at given index.
    /// @return The executor address at given valid index.
    function executorByIndex(uint256 _index) public view returns (address) {
        return tradeExecutorsList.getAddressAtIndex(_index);
    }

    /// @notice Calculates funds held by all executors in want token.
    /// @return Sum of all funds held by executors.
    function totalExecutorFunds() public view returns (uint256) {
        uint256 totalFunds = 0;
        for (uint256 i = 0; i < totalExecutors(); i++) {
            address executor = executorByIndex(i);
            (uint256 executorFunds, uint256 blockUpdated) = ITradeExecutor(
                executor
            ).totalFunds();
            areFundsUpdated(blockUpdated);
            totalFunds += executorFunds;
        }
        return totalFunds;
    }

    /*///////////////////////////////////////////////////////////////
                    GOVERNANCE ACTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a batcher is updated.
    /// @param oldBatcher The address of the current batcher.
    /// @param newBatcher The  address of new batcher.
    event UpdatedBatcher(
        address indexed oldBatcher,
        address indexed newBatcher
    );

    /// @notice Changes the batcher address.
    /// @dev  This can only be called by governance.
    /// @param _batcher The address to for new batcher.
    function setBatcher(address _batcher) public {
        onlyGovernance();
        emit UpdatedBatcher(batcher, _batcher);
        batcher = _batcher;
    }

    /// @notice Emitted batcherOnlyDeposit is enabled.
    /// @param state The state of depositing only via batcher.
    event UpdatedBatcherOnlyDeposit(bool state);

    /// @notice Enables/disables deposits with batcher only.
    /// @dev  This can only be called by governance.
    /// @param _batcherOnlyDeposit if true vault can accept deposit via batcher only or else anyone can deposit.
    function setBatcherOnlyDeposit(bool _batcherOnlyDeposit) public {
        onlyGovernance();
        batcherOnlyDeposit = _batcherOnlyDeposit;
        emit UpdatedBatcherOnlyDeposit(_batcherOnlyDeposit);
    }

    /// @notice Nominates new governance address.
    /// @dev  Governance will only be changed if the new governance accepts it. It will be pending till then.
    /// @param _governance The address of new governance.
    function setGovernance(address _governance) public {
        onlyGovernance();
        pendingGovernance = _governance;
    }

    /// @notice Emitted when governance is updated.
    /// @param oldGovernance The address of the current governance.
    /// @param newGovernance The address of new governance.
    event UpdatedGovernance(
        address indexed oldGovernance,
        address indexed newGovernance
    );

    /// @notice The nomine of new governance address proposed by `setGovernance` function can accept the governance.
    /// @dev  This can only be called by address of pendingGovernance.
    function acceptGovernance() public {
        require(msg.sender == pendingGovernance, "INVALID_ADDRESS");
        emit UpdatedGovernance(governance, pendingGovernance);
        governance = pendingGovernance;
    }

    /// @notice Emitted when keeper is updated.
    /// @param oldKeeper The address of the old keeper.
    /// @param newKeeper The address of the new keeper.
    event UpdatedKeeper(address indexed oldKeeper, address indexed newKeeper);

    /// @notice Sets new keeper address.
    /// @dev  This can only be called by governance.
    /// @param _keeper The address of new keeper.
    function setKeeper(address _keeper) public {
        onlyGovernance();
        emit UpdatedKeeper(keeper, _keeper);
        keeper = _keeper;
    }

    /// @notice Emitted when emergencyMode status is updated.
    /// @param emergencyMode boolean indicating state of emergency.
    event EmergencyModeStatus(bool emergencyMode);

    /// @notice sets emergencyMode.
    /// @dev  This can only be called by governance.
    /// @param _emergencyMode if true, vault will be in emergency mode.
    function setEmergencyMode(bool _emergencyMode) public {
        onlyGovernance();
        emergencyMode = _emergencyMode;
        batcherOnlyDeposit = true;
        batcher = address(0);
        emit EmergencyModeStatus(_emergencyMode);
    }

    /// @notice Removes invalid tokens from the vault.
    /// @dev  This is used as fail safe to remove want tokens from the vault during emergency mode
    /// can be called by anyone to send funds to governance.
    /// @param _token The address of token to be removed.
    function sweep(address _token) public {
        isEmergencyMode();
        IERC20(_token).safeTransfer(
            governance,
            IERC20(_token).balanceOf(address(this))
        );
    }

    /*///////////////////////////////////////////////////////////////
                    ACCESS MODIFERS
    //////////////////////////////////////////////////////////////*/
    /// @dev Checks if the sender is the governance.
    function onlyGovernance() internal view {
        require(msg.sender == governance, "ONLY_GOV");
    }

    /// @dev Checks if the sender is the keeper.
    function onlyKeeper() internal view {
        require(msg.sender == keeper, "ONLY_KEEPER");
    }

    /// @dev Checks if the sender is the batcher.
    function onlyBatcher() internal view {
        if (batcherOnlyDeposit) {
            require(msg.sender == batcher, "ONLY_BATCHER");
        }
    }

    /// @dev Checks if emergency mode is enabled.
    function isEmergencyMode() internal view {
        require(emergencyMode == true, "EMERGENCY_MODE");
    }

    /// @dev Checks if the address is valid.
    function isValidAddress(address _addr) internal pure {
        require(_addr != address(0), "NULL_ADDRESS");
    }

    /// @dev Checks if the tradeExecutor is valid.
    function isActiveExecutor(address _tradeExecutor) internal view {
        require(tradeExecutorsList.exists(_tradeExecutor), "INVALID_EXECUTOR");
    }

    /// @dev Checks if funds are updated.
    function areFundsUpdated(uint256 _blockUpdated) internal view {
        require(
            block.number <= _blockUpdated + BLOCK_LIMIT,
            "FUNDS_NOT_UPDATED"
        );
    }
}