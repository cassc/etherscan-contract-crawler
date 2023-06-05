// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IMasterVault.sol";

import "./interfaces/IWaitingPool.sol";
import "../strategies/IBaseStrategy.sol";

// --- Vault with instances per Underlying to generate yield via strategies ---
contract MasterVault is IMasterVault, ERC4626Upgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {

    // ---------------
    // --- Wrapper ---
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // ------------
    // --- Vars --- 'PLACEHOLDER_' slot unused
    IWaitingPool public waitingPool;  // Pending withdraw contract
    address private PLACEHOLDER_1;

    address public feeReceiver;
    address public provider;          // DavosProvider
    address private PLACEHOLDER_2;

    uint256 public depositFee;
    uint256 public maxDepositFee;
    uint256 public withdrawalFee;
    uint256 public maxWithdrawalFee;
    uint256 public MAX_STRATEGIES;
    uint256 public totalDebt;         // Underlying Tokens in all Strategies
    uint256 public feeEarned;
    address[] public strategies;

    mapping(address => bool) public manager;
    mapping(address => StrategyParams) public strategyParams;

    uint256 private PLACEHOLDER_3;
    uint256 public allocateOnDeposit;


    // ------------
    // --- Mods ---
    modifier onlyOwnerOrProvider() {
        require(msg.sender == owner() || msg.sender == provider, "MasterVault/not-owner-or-provider");
        _;
    }
    modifier onlyOwnerOrManager() {
        require(msg.sender == owner() || manager[msg.sender], "MasterVault/not-owner-or-manager");
        _;
    }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }

    // ------------
    // --- Init ---
    /** Initializer for upgradeability
      * @param _asset underlying asset
      * @param _name name of MasterVault token
      * @param _symbol symbol of MasterVault token
      * @param _maxDepositFees fees charged in parts per million; 1% = 10000ppm
      * @param _maxWithdrawalFees fees charged in parts per million; 1% = 10000ppm
      * @param _maxStrategies number of maximum strategies
      */
    function initialize(address _asset, string memory _name, string memory _symbol, uint256 _maxDepositFees, uint256 _maxWithdrawalFees, uint8 _maxStrategies) external initializer {
        
        require(_maxDepositFees > 0 && _maxDepositFees <= 1e6, "MasterVault/invalid-maxDepositFee");
        require(_maxWithdrawalFees > 0 && _maxWithdrawalFees <= 1e6, "MasterVault/invalid-maxWithdrawalFees");

        __ERC4626_init(IERC20MetadataUpgradeable(_asset));
        __ERC20_init(_name, _symbol);
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        
        maxDepositFee = _maxDepositFees;
        maxWithdrawalFee = _maxWithdrawalFees;
        MAX_STRATEGIES = _maxStrategies;

        feeReceiver = msg.sender;
    }

    // ----------------
    // --- Deposits ---
    /** Deposit underlying assets via DavosProvider
      * @param _amount amount of Underlying Token deposit
      * @return shares corresponding MasterVault tokens
      */
    function depositUnderlying(uint256 _amount) external override nonReentrant whenNotPaused onlyOwnerOrProvider returns (uint256 shares) {

        require(_amount > 0, "MasterVault/invalid-amount");
        address src = msg.sender;

        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(asset()), src, address(this), _amount);
        shares = _assessFee(_amount, depositFee);

        uint256 waitingPoolDebt = waitingPool.totalDebt();
        uint256 waitingPoolBalance = IERC20Upgradeable(asset()).balanceOf(address(waitingPool));
        if(waitingPoolDebt > 0 && waitingPoolBalance < waitingPoolDebt) {
            uint256 waitingPoolDebtDiff = waitingPoolDebt - waitingPoolBalance;
            uint256 poolAmount = (waitingPoolDebtDiff < shares) ? waitingPoolDebtDiff : shares;
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(asset()), address(waitingPool), poolAmount);
        }

        _mint(src, shares);

        if(allocateOnDeposit == 1) allocate();

        emit Deposit(src, src, _amount, shares);
    }
    /** Deposit underlying tokens into strategy
      * @param _strategy address of strategy
      * @param _amount amount of Underlying Token deposit
      */
    function depositToStrategy(address _strategy, uint256 _amount) public onlyOwnerOrManager {

        require(_depositToStrategy(_strategy, _amount));
    }
    /** Deposit all underlying tokens into strategy
      * @param _strategy address of strategy
      */
    function depositAllToStrategy(address _strategy) public onlyOwnerOrManager {

        require(_depositToStrategy(_strategy, totalAssetInVault()));
    }
    /** Internal -> deposits underlying to strategy
      * @param _strategy address of strategy
      * @param _amount amount of Underlying Token deposit
      * @return success finality state of deposit
      */
    function _depositToStrategy(address _strategy, uint256 _amount) private returns (bool success) {

        require(_amount > 0, "MasterVault/invalid-amount");
        require(strategyParams[_strategy].active, "MasterVault/invalid-strategy");
        require(totalAssetInVault() >= _amount, "MasterVault/insufficient-balance");

        // 'capacity' is total depositable; 'chargedCapacity' is capacity after charging fee
        (uint256 capacity, uint256 chargedCapacity) = IBaseStrategy(_strategy).canDeposit(_amount);
        if(capacity <= 0 || capacity > _amount || chargedCapacity > capacity) return false;

        totalDebt += chargedCapacity;
        strategyParams[_strategy].debt += chargedCapacity;

        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(asset()), _strategy, capacity);
        IBaseStrategy(_strategy).deposit(capacity);
        
        emit DepositedToStrategy(_strategy, capacity, chargedCapacity);
        return true;
    }
    /** Deposits underlying to active strategies based on allocation points
      * @dev Useful incase of deposits to avoid unnecessary swapFees
      */
    function allocate() public {
        for(uint8 i = 0; i < strategies.length; i++) {
            if(strategyParams[strategies[i]].active) {
                StrategyParams memory strategy =  strategyParams[strategies[i]];
                uint256 allocation = strategy.allocation;
                if(allocation > 0) {
                    uint256 totalAssetAndDebt = totalAssetInVault() + totalDebt;
                    uint256 strategyRatio = (strategy.debt * 1e6) / totalAssetAndDebt;
                    if(strategyRatio < allocation) {
                        uint256 depositAmount = ((totalAssetAndDebt * allocation) / 1e6) - strategy.debt;
                        if(totalAssetInVault() > depositAmount && depositAmount > 0) {
                            _depositToStrategy(strategies[i], depositAmount);
                        }
                    }
                }
            }
        }
    }

    // -----------------
    // --- Withdraws ---
    /** Withdraw underlying assets via DavosProvider
      * @param _account receipient
      * @param _amount underlying assets to withdraw
      * @return assets underlying assets excluding any fees
      */
    function withdrawUnderlying(address _account, uint256 _amount) external override nonReentrant whenNotPaused onlyOwnerOrProvider returns (uint256 assets) {

        require(_amount > 0, "MasterVault/invalid-amount");
        address src = msg.sender;
        assets = _amount;

        _burn(src, _amount);

        uint256 underlyingBalance = totalAssetInVault();
        if(underlyingBalance < _amount) {

          uint256 debt = waitingPool.getUnbackedDebt();
          Type class = debt == 0 ? Type.ABSTRACT : Type.IMMEDIATE;
          
          (uint256 withdrawn, bool incomplete, bool delayed) = _withdrawFromActiveStrategies(_account, _amount + debt - underlyingBalance, class);

          if(withdrawn == 0 || debt != 0 || incomplete) {
            assets = _assessFee(assets, withdrawalFee);
            waitingPool.addToQueue(_account, assets);
            if(totalAssetInVault() > 0) 
              SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(asset()), address(waitingPool), underlyingBalance);
            emit Withdraw(src, src, src, assets, _amount);
            return _amount;
          } else if(delayed) {
            assets = underlyingBalance;
          } else {
            assets = underlyingBalance + withdrawn;
          }
        }

        assets = _assessFee(assets, withdrawalFee);
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(asset()), _account, assets);

        emit Withdraw(src, src, src, assets, _amount);
        return _amount;
    }
    /** Withdraw underlying assets from Strategy
      * @param _strategy address of strategy
      * @param _amount underlying assets to withdraw from strategy
      */
    function withdrawFromStrategy(address _strategy, uint256 _amount) public onlyOwnerOrManager {

        (uint256 withdrawn,) = _withdrawFromStrategy(address(this), _strategy, _amount);
        require(withdrawn > 0, "MasterVault/unable-to-withdraw");
    }
    /** Withdraw all underlying assets from Strategy
      * @param _strategy address of strategy
      */
    function withdrawAllFromStrategy(address _strategy) external onlyOwnerOrManager {

        (uint256 withdrawn,) = _withdrawFromStrategy(address(this), _strategy, strategyParams[_strategy].debt);
        require(withdrawn > 0, "MasterVault/unable-to-withdraw");
    }
    /** Internal -> withdraws underlying from strategy
      * @param _recipient direct receiver if strategy has unstake time
      * @param _strategy address of strategy
      * @param _amount amount of Underlying Token withdrawal
      * @return bool amount of Underlying Tokens withdrawn
      * @return incomplete 'true' if withdrawn amount less than '_amount'
      */
    function _withdrawFromStrategy(address _recipient, address _strategy, uint256 _amount) private returns(uint256, bool incomplete) {

        require(_amount > 0, "MasterVault/invalid-amount");
        require(strategyParams[_strategy].debt >= _amount, "MasterVault/insufficient-assets-in-strategy");

        StrategyParams memory params = strategyParams[_strategy];
        (uint256 capacity, uint256 chargedCapacity) = IBaseStrategy(_strategy).canWithdraw(_amount);
        if(capacity <= 0 || chargedCapacity > capacity) return (0, false);
        else if(capacity < _amount) incomplete = true;

        if(params.class == Type.DELAYED && incomplete) return (0, true);

        totalDebt -= capacity;
        strategyParams[_strategy].debt -= capacity;

        uint256 value = IBaseStrategy(_strategy).withdraw(_recipient, capacity);

        require(value >= chargedCapacity, "MasterVault/preview-withdrawn-mismatch");

        emit WithdrawnFromStrategy(_strategy, _amount, chargedCapacity);
        return (chargedCapacity, incomplete);
    }
    /** Internal -> traverses through all active strategies for withdrawal
      * @param _recipient direct receiver if strategy has unstake time
      * @param _amount amount of Underlying Tokens withdrawal
      */
    function _withdrawFromActiveStrategies(address _recipient, uint256 _amount, Type class) private returns(uint256 withdrawn, bool incomplete, bool delayed) {

        for(uint8 i = 0; i < strategies.length; i++) {
            if(strategyParams[strategies[i]].active && (strategyParams[strategies[i]].class == class || class == Type.ABSTRACT) && strategyParams[strategies[i]].debt >= _amount) {
              _recipient = strategyParams[strategies[i]].class == Type.DELAYED ? _recipient : address(this);
              delayed = strategyParams[strategies[i]].class == Type.DELAYED ? true : false;
              (withdrawn, incomplete) = _withdrawFromStrategy(_recipient, strategies[i], _amount);
            }
        }
    }
    /** Internal -> charge corresponding fees from amount
      * @param amount amount to charge fee from
      * @param fees fee percentage
      * @return value amount after fee charge
      */
    function _assessFee(uint256 amount, uint256 fees) private returns(uint256 value) {

        if(fees > 0) {
            uint256 fee = (amount * fees) / 1e6;
            value = amount - fee;
            feeEarned += fee;
        } else return amount;
    }

    // ---------------
    // --- Manager ---
    /** Withdraws all assets from strategy marking it inactive
      * @param _strategy address of strategy 
      */
    function retireStrat(address _strategy) external onlyOwnerOrManager {

        if(_deactivateStrategy(_strategy)) return;

        _withdrawFromStrategy(address(this), _strategy, strategyParams[_strategy].debt);
        require(_deactivateStrategy(_strategy), "MasterVault/cannot-retire");
    }
    /** Withdraws all assets from old strategy to new strategy
      * @notice allocate() must be triggered afterwards
      * @notice old strategy might have unstake delay
      * @param _oldStrategy address of old strategy
      * @param _newStrategy address of new strategy 
      * @param _newAllocation underlying assets allocation to '_newStrategy' where 1% = 10000
      */
    function migrateStrategy(address _oldStrategy, address _newStrategy, uint256 _newAllocation, Type _class) external onlyOwnerOrManager {

        require(_oldStrategy != address(0) && _newStrategy != address(0));

        uint256 oldStrategyDebt = strategyParams[_oldStrategy].debt;
        if(oldStrategyDebt > 0) {
            (uint256 withdrawn,) = _withdrawFromStrategy(address(this), _oldStrategy, oldStrategyDebt);
            require(withdrawn > 0, "MasterVault/cannot-withdraw");
        }

        StrategyParams memory params = StrategyParams({active: true, class: _class, allocation: _newAllocation, debt: 0});

        bool isValidStrategy;
        for(uint256 i = 0; i < strategies.length; i++) {
            if(strategies[i] == _oldStrategy) {
                isValidStrategy = true;
                strategies[i] = _newStrategy;
                strategyParams[_newStrategy] = params;
                
                break;
            }
        }

        require(isValidStrategy, "MasterVault/invalid-oldStrategy");
        require(_deactivateStrategy(_oldStrategy),"MasterVault/cannot-deactivate");
        require(_isValidAllocation(), "MasterVault/>100%");

        emit StrategyMigrated(_oldStrategy, _newStrategy, _newAllocation);
    }
    /** Internal -> checks strategy's debt and deactives it
      * @param _strategy address of strategy 
      */
    function _deactivateStrategy(address _strategy) private returns(bool success) {

        if (strategyParams[_strategy].debt <= 10) {
            strategyParams[_strategy].active = false;
            strategyParams[_strategy].debt = 0;
            return true;
        }
    }
    /** Internal -> Sums up all individual allocation to match total
      */
    function _isValidAllocation() private view returns(bool) {

        uint256 totalAllocations;
        for(uint256 i = 0; i < strategies.length; i++) {
            if(strategyParams[strategies[i]].active) {
                totalAllocations += strategyParams[strategies[i]].allocation;
            }
        }

        return totalAllocations <= 1e6;
    }
    /** Sends required Underlying Token amount to waitingPool to equalize debt
      * @notice '_withdrawFromActiveStrategies' might have strategy with unstake delay
      */
    function cancelDebt(Type _class) public onlyOwnerOrManager {

        uint256 withdrawn; bool delayed;

        uint256 waitingPoolDebt = waitingPool.totalDebt();
        uint256 waitingPoolBal = IERC20Upgradeable(asset()).balanceOf(address(waitingPool));
        if (waitingPoolDebt > waitingPoolBal) {
          uint256 withdrawAmount = waitingPoolDebt - waitingPoolBal;
          if (totalAssetInVault() >= withdrawAmount) {
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(asset()), address(waitingPool), withdrawAmount);
          } else {
            (withdrawn,,delayed) = _withdrawFromActiveStrategies(address(waitingPool), withdrawAmount + 1, _class);
            uint256 amount = totalAssetInVault();
            if(withdrawn > 0 && !delayed) amount += withdrawn;
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(asset()), address(waitingPool), amount);
          }
        }
    }
    /** Triggers tryRemove() of waiting pool contract
      */
    function tryRemove() public onlyOwnerOrManager {

        waitingPool.tryRemove();
    }

    // -------------
    // --- Admin ---
    /** Adds a new strategy
      * @param _strategy address of strategy 
      * @param _allocation underlying assets allocation to '_strategy' where 1% = 10000
      */
    function addStrategy(address _strategy, uint256 _allocation, Type _class) external onlyOwner {

        require(_strategy != address(0));
        require(strategies.length < MAX_STRATEGIES, "MasterVault/strategies-maxed");

        uint256 totalAllocations;
        for(uint256 i = 0; i < strategies.length; i++) {
            if(strategies[i] == _strategy) revert("MasterVault/already-exists");
            if(strategyParams[strategies[i]].active) totalAllocations += strategyParams[strategies[i]].allocation;
        }

        require(totalAllocations + _allocation <= 1e6, "MasterVault/>100%");

        StrategyParams memory params = StrategyParams({active: true, class: _class, allocation: _allocation, debt: 0});

        strategyParams[_strategy] = params;
        strategies.push(_strategy);
        emit StrategyAdded(_strategy, _allocation);
    }
    /** Changes allocation of Strategy
      * @param _strategy address of strategy 
      * @param _allocation underlying assets new allocation to '_strategy' where 1% = 10000
      */
    function changeStrategyAllocation(address _strategy, uint256 _allocation) external onlyOwner {

        require(_strategy != address(0));        
        strategyParams[_strategy].allocation = _allocation;
        require(_isValidAllocation(), "MasterVault/>100%");

        emit StrategyAllocationChanged(_strategy, _allocation);
    }
    /** Withdraw fees to feeReceiver
      */
    function withdrawFee() external onlyOwner{

        if(feeEarned > 0) {
            uint256 toSend = feeEarned;
            feeEarned = 0;
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(asset()), feeReceiver, toSend);
        }
    }
    /** Changes allocation mode on deposit
      * @param _status 0-Disabled, 1-Enabled
      */
    function changeAllocateOnDeposit(uint256 _status) external onlyOwner {

        require(_status >= 0 && _status < 2, "MasterVault/range-0-or-1");
        allocateOnDeposit = _status;

        emit AllocationOnDepositChangeed(_status);
    }
    /** Sets a deposit fee where 1% = 10000ppm
      * @param _newDepositFee new deposit fee percentage
      */
    function setDepositFee(uint256 _newDepositFee) external onlyOwner {

        require(maxDepositFee > _newDepositFee,"MasterVault/more-than-maxDepositFee");
        depositFee = _newDepositFee;

        emit DepositFeeChanged(_newDepositFee);
    }
    /** Sets a withdrawal fee where 1% = 10000ppm
      * @param _newWithdrawalFee new withdrawal fee percentage
      */
    function setWithdrawalFee(uint256 _newWithdrawalFee) external onlyOwner {

        require(maxWithdrawalFee > _newWithdrawalFee,"MasterVault/more-than-maxWithdrawalFee");
        withdrawalFee = _newWithdrawalFee;

        emit WithdrawalFeeChanged(_newWithdrawalFee);
    }
    /** Changes provider contract
      * @param _provider new provider
      */
    function changeProvider(address _provider) external onlyOwner {

        require(_provider != address(0));
        provider = _provider;

        emit ProviderChanged(_provider);
    }
    /** Sets waiting pool contract
      * @param _waitingPool new waiting pool address
      */
    function setWaitingPool(address _waitingPool) external onlyOwner {

        require(_waitingPool != address(0));
        waitingPool = IWaitingPool(_waitingPool);

        emit WaitingPoolChanged(_waitingPool);
    }
    /** Sets waiting pool cap
      * @param _cap new cap limit
      */
    function setWaitingPoolCap(uint256 _cap) external onlyOwner {

        waitingPool.setCapLimit(_cap);

        emit WaitingPoolCapChanged(_cap);
    }
    /** Changes fee receiver
      * @param _feeReceiver new fee receiver
      */
    function changeFeeReceiver(address _feeReceiver) external onlyOwner {

        require(_feeReceiver != address(0));
        feeReceiver = _feeReceiver;

        emit FeeReceiverChanged(_feeReceiver);
    }
    /** Adds a new manager
      * @param _newManager new manager
      */
    function addManager(address _newManager) external onlyOwner {

        require(_newManager != address(0));
        manager[_newManager] = true;

        emit ManagerAdded(_newManager);
    }
    /** Removes an existing manager
      * @param _manager new manager
      */
    function removeManager(address _manager) external onlyOwner {

        require(manager[_manager]);
        manager[_manager] = false;

        emit ManagerRemoved(_manager);
    } 
    /** Pauses MasterVault contract
      */
    function pause() external onlyOwner whenNotPaused {

        _pause();
    }
    /** Unpauses MasterVault contract
    */
    function unpause() external onlyOwner whenPaused {

        _unpause();
    }

    // -------------
    // --- Views ---
    /** Returns the amount of assets that can be withdrawn instantly
      * @return available amount of assets
      */
    function availableToWithdraw() public view returns(uint256 available) {

        for(uint8 i = 0; i < strategies.length; i++) available += IERC20Upgradeable(asset()).balanceOf(strategies[i]);
        available += totalAssetInVault();
    }
    /** Returns the amount of underlying assets in MasterVault excluding feeEarned
      * @return balance amount of assets
      */
    function totalAssetInVault() public view returns(uint256 balance) {

        return (totalAssets() > feeEarned) ? totalAssets() - feeEarned : 0;
    }

    // ---------------
    // --- ERC4626 ---
    /** Kept only for the sake of ERC4626 standard
      */
    function deposit(uint256 assets, address receiver) public override returns (uint256) { revert(); }
    function mint(uint256 shares, address receiver) public override returns (uint256) { revert(); }
    function withdraw(uint256 assets, address receiver, address owner) public override returns (uint256) { revert(); }
    function redeem(uint256 shares, address receiver, address owner) public override returns (uint256) { revert(); }
}