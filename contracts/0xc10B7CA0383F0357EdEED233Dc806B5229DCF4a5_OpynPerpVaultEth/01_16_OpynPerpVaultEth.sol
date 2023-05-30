// SPDX-License-Identifier: MIT
pragma solidity >=0.7.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IAction} from "../interfaces/IAction.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IOldVault} from "../interfaces/IOldVault.sol";
import {IWETH} from "../interfaces/IWETH.sol";

contract OpynPerpVaultEth is
    ERC20Upgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    enum VaultState {
        Locked,
        Unlocked,
        Emergency
    }

    /// @dev current state of the vault
    VaultState public state;

    /// @dev state of the vault before it was paused
    VaultState public stateBeforePause;

    /// @dev oldVault for migration
    IOldVault public oldVault;

    /// @dev 100%
    uint256 public constant BASE = 10000;

    /// @dev percentage of profits that will go to the fee recipient
    uint256 public performanceFeeInPercent = 100; // 1%

    /// @dev percentage of total asset charged as management fee every year
    uint256 public managementFeeInPercent = 0; // 0%

    /// @dev amount of asset that has been registered to be withdrawn. This amount will be reserved in the vault after the current round ends
    uint256 public withdrawQueueAmount;

    /// @dev amount of asset that has been deposited into the vault, but hasn't minted a share yet
    uint256 public pendingDeposit;

    /// @dev ERC20 asset which can be deposited into this strategy. Do not use anything but ERC20s.
    address public asset;

    /// @dev address to which all fees are sent
    address public feeRecipient;

    /// @dev actions that build up this strategy (vault)
    address[] public actions;

    /// @dev the timestamp at which the current round started
    uint256 public currentRoundStartTimestamp;

    /// @dev keep tracks of how much capital the current round start with
    uint256 public currentRoundStartingAmount;

    /// @dev cap for the vault
    uint256 public cap = 1000 ether;

    /// @dev the current round
    uint256 public round;

    /// @dev user's share in withdraw queue for a round
    mapping(address => mapping(uint256 => uint256))
        public userRoundQueuedWithdrawShares;

    /// @dev user's asset amount in deposit queue for a round
    mapping(address => mapping(uint256 => uint256))
        public userRoundQueuedDepositAmount;

    /// @dev total registered shares per round
    mapping(uint256 => uint256) public roundTotalQueuedWithdrawShares;

    /// @dev total asset recorded at end of each round
    mapping(uint256 => uint256) public roundTotalAsset;

    /// @dev total share supply recorded at end of each round
    mapping(uint256 => uint256) public roundTotalShare;

    /*=====================
     *       Events       *
     *====================*/

    event Deposit(
        address account,
        uint256 amountDeposited,
        uint256 shareMinted
    );

    event Withdraw(
        address account,
        uint256 amountWithdrawn,
        uint256 shareBurned
    );

    event WithdrawFromQueue(
        address account,
        uint256 amountWithdrawn,
        uint256 round
    );

    event Rollover(uint256[] allocations);

    event StateUpdated(VaultState state);

    event CapUpdated(uint256 newCap);

    /*=====================
     *     Modifiers      *
     *====================*/

    /**
     * @dev can only be executed in the unlocked state.
     */
    modifier onlyUnlocked() {
        require(state == VaultState.Unlocked, "!Unlocked");
        _;
    }

    /**
     * @dev can only be executed in the locked state.
     */
    modifier onlyLocked() {
        require(state == VaultState.Locked, "!Locked");
        _;
    }

    /**
     * @dev can only be executed in the unlocked state. Sets the state to 'Locked'
     */
    modifier lockState() {
        state = VaultState.Locked;
        emit StateUpdated(VaultState.Locked);
        _;
    }

    /**
     * @dev Sets the state to 'Unlocked'
     */
    modifier unlockState() {
        state = VaultState.Unlocked;
        emit StateUpdated(VaultState.Unlocked);
        _;
    }

    /**
     * @dev can only be executed if vault is not in the 'Emergency' state.
     */
    modifier notEmergency() {
        require(state != VaultState.Emergency, "Emergency");
        _;
    }

    /*=====================
     * External Functions *
     *====================*/

    /**
     * @notice function to init the vault
     * this will set the "action" for this strategy vault and won't be able to change
     * @param _asset The asset that this vault will manage. Cannot be changed after initializing.
     * @param _owner The address that will be the owner of this vault.
     * @param _feeRecipient The address to which all the fees will be sent. Cannot be changed after initializing.
     * @param _decimals of the _asset
     * @param _tokenName name of the share given to depositors of this vault
     * @param _tokenSymbol symbol of the share given to depositors of this vault
     * @param _actions array of addresses of the action contracts
     * @dev when choosing actions make sure they have similar lifecycles and expiries. if the actions can't all be closed at the
     * same time, composing them may lead to tricky interactions like user funds being stuck for longer in actions than expected.
     */
    function init(
        address _asset,
        address _owner,
        address _feeRecipient,
        uint8 _decimals,
        string memory _tokenName,
        string memory _tokenSymbol,
        address[] memory _actions,
        address _oldVault
    ) public initializer {
        __ReentrancyGuard_init();
        __ERC20_init(_tokenName, _tokenSymbol);
        _setupDecimals(_decimals);
        __Ownable_init();
        transferOwnership(_owner);

        asset = _asset;
        feeRecipient = _feeRecipient;

        // assign actions
        for (uint256 i = 0; i < _actions.length; i++) {
            // check all items before actions[i], does not equal to action[i]
            for (uint256 j = 0; j < i; j++) {
                require(_actions[i] != _actions[j], "duplicated action");
            }
            actions.push(_actions[i]);
        }

        state = VaultState.Unlocked;

        currentRoundStartTimestamp = block.timestamp;
        oldVault = IOldVault(_oldVault);
    }

    /**
     * @notice allows the owner to change the vault cap
     * @param _cap the new cap of the vault
     */
    function setCap(uint256 _cap) external onlyOwner {
        cap = _cap;
        emit CapUpdated(cap);
    }

    /**
     * @notice returns the total assets controlled by this vault, excluding pending deposit and withdraw
     */
    function totalUnderlyingControlled() external view returns (uint256) {
        return _netAssetsControlled();
    }

    /**
     * @notice returns how many shares a user can get if they deposit `_amount` of asset into the vault
     * @dev this number will change when someone registers a withdraw when the vault is locked
     * @param _amount amount of asset that the user will deposit
     */
    function getSharesByDepositAmount(uint256 _amount)
        external
        view
        returns (uint256)
    {
        return _getSharesByDepositAmount(_amount, _netAssetsControlled());
    }

    /**
     * @notice returns how much of the asset a user can get back if they burn `_shares` amount of shares. The
     * asset amount returned also takes into account fees charged.
     * @param _shares amount of shares the user will burn
     */
    function getWithdrawAmountByShares(uint256 _shares)
        external
        view
        returns (uint256)
    {
        return _getWithdrawAmountByShares(_shares);
    }

    /**
     * @notice Deposits ETH into the contract and mint vault shares.
     * @dev deposit into the weth then mint the shares to depositor, and emit the deposit event
     */
    function depositETH()
        external
        payable
        nonReentrant
        onlyUnlocked
        notEmergency
    {
        uint256 amount = msg.value;
        require(amount > 0, "O6");
        //deposit into weth
        IWETH(asset).deposit{value: amount}();
        // mint shares and emit event
        _deposit(amount);
    }

    /**
     * @notice deposits `amount` of the asset into the vault and issues shares
     * @dev deposit ERC20 asset and get shares. Direct deposits can only happen when the vault is unlocked.
     * @param _amount The amount of asset that is deposited.
     */
    function deposit(uint256 _amount) external onlyUnlocked notEmergency {
        IERC20(asset).safeTransferFrom(msg.sender, address(this), _amount);
        _deposit(_amount);
    }

    /**
     * @notice deposits `amount` of the asset into the vault without issuing shares
     * @dev deposits the ETH and turn into it to ERC20 asset and add into the pending queue. This is called when the vault is locked. Note that if
     * a user deposits before the start of the end of the current round, they will not be able to withdraw their
     * funds until the current round is over. They will also not be able to earn any premiums on their current deposit.
     */
    function registerDepositETH(address _shareRecipient)
        external
        payable
        nonReentrant
        notEmergency
        onlyLocked
    {
        uint256 amount = msg.value;
        require(amount > 0, "O6");
        //deposit into weth
        IWETH(asset).deposit{value: msg.value}();
        // mint shares and emit event
        _register(amount, _shareRecipient);
    }

    /**
     * @notice deposits `amount` of the asset into the vault without issuing shares
     * @dev deposits the ERC20 asset into the pending queue. This is called when the vault is locked. Note that if
     * a user deposits before the start of the end of the current round, they will not be able to withdraw their
     * funds until the current round is over. They will also not be able to earn any premiums on their current deposit.
     * @param _amount The amount of asset that is deposited.
     */
    function registerDeposit(uint256 _amount, address _shareRecipient)
        external
        onlyLocked
        notEmergency
    {
        IERC20(asset).safeTransferFrom(msg.sender, address(this), _amount);
        _register(_amount, _shareRecipient);
    }

    function _register(uint256 _amount, address _shareRecipient) internal {
        uint256 totalWithDepositedAmount = _totalAssets();
        require(totalWithDepositedAmount < cap, "Cap exceeded");
        userRoundQueuedDepositAmount[_shareRecipient][
            round
        ] = userRoundQueuedDepositAmount[_shareRecipient][round].add(_amount);
        pendingDeposit = pendingDeposit.add(_amount);
    }

    /**
     * @notice anyone can call this function to actually transfer the minted shares to the depositors
     * @dev this can only be called once closePosition is called to end the current round. The depositor needs a share
     * to be able to withdraw their assets in the future.
     * @param _depositor the address of the depositor
     * @param _round the round in which the depositor called `registerDeposit`
     */
    function claimShares(address _depositor, uint256 _round) external {
        require(_round < round, "Invalid round");
        uint256 amountDeposited = userRoundQueuedDepositAmount[_depositor][
            _round
        ];

        userRoundQueuedDepositAmount[_depositor][_round] = 0;

        uint256 equivalentShares = amountDeposited
            .mul(roundTotalShare[_round])
            .div(roundTotalAsset[_round]);

        // transfer shares from vault to user
        _transfer(address(this), _depositor, equivalentShares);
    }

    /**
     * @notice withdraws asset from vault using vault shares.
     * @dev The msg.sender needs to burn the vault shares to be able to withdraw. If the user called `registerDeposit`
     * without someone calling `claimShares` for them, they wont be able to withdraw. They need to have the shares in their wallet.
     * This can only be called when the vault is unlocked.
     * @param _shares is the number of vault shares to be burned
     */
    function withdraw(uint256 _shares)
        external
        nonReentrant
        onlyUnlocked
        notEmergency
    {
        uint256 withdrawAmount = _regularWithdraw(_shares);
        IERC20(asset).safeTransfer(msg.sender, withdrawAmount);
    }

    receive() external payable {}

    fallback() external payable {}

    /**
     * @notice migrate assets from old vault to this vault
     * @dev The msg.sender needs to have old vault tokens to be able to migrate to this vault.
     * @param _amount is the amount of the old vault tokens
     * @param minEth is the minimum amount expected to get while withdrawing from curve pool for the old vault withdraw function
     */
    function migrate(uint256 _amount, uint256 minEth)
        external
        payable
        onlyUnlocked
        notEmergency
        nonReentrant
    {
        IERC20(address(oldVault)).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        oldVault.withdrawETH(_amount, minEth);
        _amount = address(this).balance;
        //deposit into weth
        IWETH(asset).deposit{value: _amount}();
        // mint shares and emit event
        _deposit(_amount);
    }

    /**
     * @notice allows someone to request to withdraw their assets once this round ends.
     * @dev assets can only be withdrawn after this round ends and closePosition is called. Calling this will burn the
     * shares right now but the assets will be transferred back to the user only when `withdrawFromQueue` is called.
     * This can only be called when the vault is locked.
     * @param _shares the amount of shares the user wants to cash out
     */
    function registerWithdraw(uint256 _shares) external onlyLocked {
        _burn(msg.sender, _shares);
        userRoundQueuedWithdrawShares[msg.sender][
            round
        ] = userRoundQueuedWithdrawShares[msg.sender][round].add(_shares);
        roundTotalQueuedWithdrawShares[round] = roundTotalQueuedWithdrawShares[
            round
        ].add(_shares);
    }

    /**
     * @notice allows the user to withdraw their promised assets from the withdraw queue at any time.
     * @dev the assets first need to be transferred to the withdraw queue which happens when the current round ends when
     * closePositions is called.
     * @param _round the round the user registered a queue withdraw
     */
    function withdrawFromQueue(uint256 _round)
        external
        nonReentrant
        notEmergency
    {
        uint256 withdrawAmount = _withdrawFromQueue(_round);
        IERC20(asset).safeTransfer(msg.sender, withdrawAmount);
    }

    /**
     * @notice allows anyone to close out the previous round by calling "closePositions" on all actions.
     * @dev this does the following:
     * 1. calls closePositions on all the actions withdraw the money from all the actions
     * 2. pay all the fees
     * 3. snapshots last round's shares and asset balances
     * 4. empties the pendingDeposits and pulls in those assets to be used in the next round
     * 5. sets aside assets from the main vault into the withdrawQueue
     * 6. ends the old round and unlocks the vault
     */
    function closePositions() public onlyLocked unlockState {
        // calls closePositions on all the actions and transfers the assets back into the vault
        _closeAndWithdraw();

        _payRoundFee();

        // records the net shares and assets in the current round and updates the pendingDeposits and withdrawQueue
        _snapshotShareAndAsset();

        round = round.add(1);
        currentRoundStartTimestamp = block.timestamp;
    }

    /**
     * @notice distributes funds to each action and locks the vault
     */
    function rollOver(uint256[] calldata _allocationPercentages)
        external
        virtual
        onlyOwner
        onlyUnlocked
        lockState
    {
        require(
            _allocationPercentages.length == actions.length,
            "INVALID_INPUT"
        );

        emit Rollover(_allocationPercentages);

        _distribute(_allocationPercentages);
    }

    /**
     * @notice sets the vault's state to "Emergency", which disables all withdrawals and deposits
     */
    function emergencyPause() external onlyOwner {
        stateBeforePause = state;
        state = VaultState.Emergency;
        emit StateUpdated(VaultState.Emergency);
    }

    /**
     * @notice sets the vault's state to whatever state it was before "Emergency"
     */
    function resumeFromPause() external onlyOwner {
        require(state == VaultState.Emergency, "!Emergency");
        state = stateBeforePause;
        emit StateUpdated(stateBeforePause);
    }

    /**
     * @notice sets the vault's perf fee
     */
    function setPerformanceFee(uint256 _percent) external onlyOwner {
        require(
            _percent >= 0 && _percent <= 10000,
            "% must be between 0 and 10000"
        );
        performanceFeeInPercent = _percent;
    }

    /**
     * @notice sets the vault's perf fee
     */
    function setFeeRecipient(address _recipient) external onlyOwner {
        feeRecipient = _recipient;
    }

    /**
     * @notice sets the vault's management fee
     */
    function setManagementFee(uint256 _percent) external onlyOwner {
        require(
            _percent >= 0 && _percent <= 10000,
            "% must be between 0 and 10000"
        );
        managementFeeInPercent = _percent;
    }

    /*=====================
     * Internal functions *
     *====================*/

    /**
     * @notice net assets controlled by this vault, which is effective balance + debts of actions
     */
    function _netAssetsControlled() internal view returns (uint256) {
        return _effectiveBalance().add(_totalDebt());
    }

    /**
     * @notice total assets controlled by the vault, including the pendingDeposits, withdrawQueue and debts of actions
     */
    function _totalAssets() internal view returns (uint256) {
        return IERC20(asset).balanceOf(address(this)).add(_totalDebt());
    }

    /**
     * @notice returns asset balance of the vault excluding assets registered to be withdrawn and the assets still in pendingDeposit.
     */
    function _effectiveBalance() internal view returns (uint256) {
        return
            IERC20(asset).balanceOf(address(this)).sub(pendingDeposit).sub(
                withdrawQueueAmount
            );
    }

    /**
     * @notice estimate amount of assets in all the actions
     * this function iterates through all actions and sum up the currentValue reported by each action.
     */
    function _totalDebt() internal view returns (uint256) {
        uint256 debt = 0;
        for (uint256 i = 0; i < actions.length; i++) {
            debt = debt.add(IAction(actions[i]).currentValue());
        }
        return debt;
    }

    /**
     * @notice mints the shares to depositor, and emits the deposit event
     */
    function _deposit(uint256 _amount) internal {
        // the asset is already deposited into the contract at this point, need to substract it from total
        uint256 netWithDepositedAmount = _netAssetsControlled();
        uint256 totalWithDepositedAmount = _totalAssets();
        require(totalWithDepositedAmount < cap, "Cap exceeded");
        uint256 netBeforeDeposit = netWithDepositedAmount.sub(_amount);

        uint256 share = _getSharesByDepositAmount(_amount, netBeforeDeposit);

        emit Deposit(msg.sender, _amount, share);

        _mint(msg.sender, share);
    }

    /**
     * @notice iterrate through each action, close position and withdraw funds
     */
    function _closeAndWithdraw() internal {
        for (uint8 i = 0; i < actions.length; i = i + 1) {
            // 1. close position. this should revert if any position is not ready to be closed.
            IAction(actions[i]).closePosition();

            // 2. withdraw assets
            uint256 actionBalance = IERC20(asset).balanceOf(actions[i]);
            if (actionBalance > 0)
                IERC20(asset).safeTransferFrom(
                    actions[i],
                    address(this),
                    actionBalance
                );
        }
    }

    /**
     * @notice distributes the effective balance to different actions
     * @dev the manager can keep a reserve in the vault by not distributing all the funds.
     */
    function _distribute(uint256[] memory _percentages) internal nonReentrant {
        uint256 totalBalance = _effectiveBalance();

        currentRoundStartingAmount = totalBalance;

        // keep track of total percentage to make sure we're summing up to 100%
        uint256 sumPercentage;
        for (uint8 i = 0; i < actions.length; i = i + 1) {
            sumPercentage = sumPercentage.add(_percentages[i]);
            require(sumPercentage <= BASE, "PERCENTAGE_SUM_EXCEED_MAX");

            uint256 newAmount = totalBalance.mul(_percentages[i]).div(BASE);

            if (newAmount > 0) {
                IERC20(asset).safeTransfer(actions[i], newAmount);
                IAction(actions[i]).rolloverPosition();
            }
        }

        require(sumPercentage == BASE, "PERCENTAGE_DOESNT_ADD_UP");
    }

    /**
     * @notice calculates withdraw amount from queued shares, returns withdraw amount to be handled by queueWithdraw or queueWithdrawETH
     * @param _round the round you registered a queue withdraw
     */
    function _withdrawFromQueue(uint256 _round) internal returns (uint256) {
        require(_round < round, "Invalid round");

        uint256 queuedShares = userRoundQueuedWithdrawShares[msg.sender][
            _round
        ];
        uint256 withdrawAmount = queuedShares.mul(roundTotalAsset[_round]).div(
            roundTotalShare[_round]
        );

        // remove user's queued shares
        userRoundQueuedWithdrawShares[msg.sender][_round] = 0;
        // decrease total asset we reserved for withdraw
        withdrawQueueAmount = withdrawQueueAmount.sub(withdrawAmount);

        emit WithdrawFromQueue(msg.sender, withdrawQueueAmount, _round);

        return withdrawAmount;
    }

    /**
     * @notice burn shares, return withdraw amount handle by withdraw or withdrawETH
     * @param _share amount of shares burn to withdraw asset.
     */
    function _regularWithdraw(uint256 _share) internal returns (uint256) {
        uint256 withdrawAmount = _getWithdrawAmountByShares(_share);

        _burn(msg.sender, _share);

        emit Withdraw(msg.sender, withdrawAmount, _share);

        return withdrawAmount;
    }

    /**
     * @notice return how many shares you can get if you deposit {_amount} asset
     * @param _amount amount of token depositing
     * @param _totalAssetAmount amount of asset already in the pool before deposit
     */
    function _getSharesByDepositAmount(
        uint256 _amount,
        uint256 _totalAssetAmount
    ) internal view returns (uint256) {
        uint256 shareSupply = totalSupply().add(
            roundTotalQueuedWithdrawShares[round]
        );

        uint256 shares = shareSupply == 0
            ? _amount
            : _amount.mul(shareSupply).div(_totalAssetAmount);
        return shares;
    }

    /**
     * @notice return how many asset you can get if you burn the number of shares
     */
    function _getWithdrawAmountByShares(uint256 _share)
        internal
        view
        returns (uint256)
    {
        uint256 effectiveShares = totalSupply();
        return _share.mul(_netAssetsControlled()).div(effectiveShares);
    }

    /**
     * @notice pay fee to fee recipient after we pull all assets back to the vault
     */
    function _payRoundFee() internal {
        // don't need to call totalAsset() because actions are empty now.
        uint256 newTotal = _effectiveBalance();
        uint256 profit;

        if (newTotal > currentRoundStartingAmount)
            profit = newTotal.sub(currentRoundStartingAmount);

        uint256 performanceFee = profit.mul(performanceFeeInPercent).div(BASE);

        uint256 managementFee = currentRoundStartingAmount
            .mul(managementFeeInPercent)
            .mul((block.timestamp.sub(currentRoundStartTimestamp)))
            .div(365 days)
            .div(BASE);
        uint256 totalFee = performanceFee.add(managementFee);
        if (totalFee > profit) totalFee = profit;

        currentRoundStartingAmount = 0;

        IERC20(asset).transfer(feeRecipient, totalFee);
    }

    /**
     * @notice snapshot last round's total shares and balance, excluding pending deposits.
     * @dev this function is called after withdrawing from action contracts and does the following:
     * 1. snapshots last round's shares and asset balances
     * 2. empties the pendingDeposits and pulls in those assets into the next round
     * 3. sets aside assets from the main vault into the withdrawQueue
     */
    function _snapshotShareAndAsset() internal {
        uint256 vaultBalance = _effectiveBalance();
        uint256 outStandingShares = totalSupply();
        uint256 sharesBurned = roundTotalQueuedWithdrawShares[round];

        uint256 totalShares = outStandingShares.add(sharesBurned);

        // store this round's balance and shares
        roundTotalShare[round] = totalShares;
        roundTotalAsset[round] = vaultBalance;

        // === Handle withdraw queue === //
        // withdrawQueueAmount was keeping track of total amount that should be reserved for withdraws, not including this round
        // add this round's reserved asset into withdrawQueueAmount, which will stay in the vault for withdraw

        uint256 roundReservedAsset = sharesBurned.mul(vaultBalance).div(
            totalShares
        );
        withdrawQueueAmount = withdrawQueueAmount.add(roundReservedAsset);

        // === Handle deposit queue === //
        // pendingDeposit is amount of deposit accepted in this round, which was in the vault all the time.
        // we will calculate how much shares this amount can mint, mint it at once to the vault,
        // and reset the pendingDeposit, so that this amount can be used in the next round.
        uint256 sharesToMint = pendingDeposit.mul(totalShares).div(
            vaultBalance
        );
        _mint(address(this), sharesToMint);
        pendingDeposit = 0;
    }
}