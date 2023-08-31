// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

import {ERC20} from "ERC20.sol";
import {SafeTransferLib} from "SafeTransferLib.sol";
import {Math} from "Math.sol";
import {Owned} from "Owned.sol";
import {ReentrancyGuard} from "ReentrancyGuard.sol";
import {IStrategy} from "IStrategy.sol";
import {ERC4626} from "ERC4626.sol";
import {Constants} from "Constants.sol";
import {Errors} from "Errors.sol";
import {StrategyQueue} from "StrategyQueue.sol";

//  ________  ________  ________
//  |\   ____\|\   __  \|\   __  \
//  \ \  \___|\ \  \|\  \ \  \|\  \
//   \ \  \  __\ \   _  _\ \  \\\  \
//    \ \  \|\  \ \  \\  \\ \  \\\  \
//     \ \_______\ \__\\ _\\ \_______\
//      \|_______|\|__|\|__|\|_______|

// gro protocol: https://github.com/groLabs/GSquared

/// @notice GVault - Gro protocol stand alone vault for generating yield
/// @title GVault
/// @notice  Gro protocol stand alone vault for generating yield on
/// stablecoins following the EIP-4626 Standard
contract GVault is Constants, ERC4626, StrategyQueue, Owned, ReentrancyGuard {
    using SafeTransferLib for ERC20;

    /*//////////////////////////////////////////////////////////////
                        CONSTANTS & IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    // Underlying token
    ERC20 public immutable override asset;
    uint256 public immutable minDeposit;

    /*//////////////////////////////////////////////////////////////
                    STORAGE VARIABLES & TYPES
    //////////////////////////////////////////////////////////////*/

    struct StrategyParams {
        bool active;
        uint256 debtRatio;
        uint256 lastReport;
        uint256 totalDebt;
        uint256 totalGain;
        uint256 totalLoss;
    }

    mapping(address => StrategyParams) public strategies;
    uint256 public vaultAssets;

    // Slow release of profit
    uint256 public lockedProfit;
    uint256 public releaseTime;

    uint256 public vaultDebtRatio;
    uint256 public vaultTotalDebt;
    uint256 public lastReport;

    // Vault fee
    address public feeCollector;
    uint256 public vaultFee;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    // Strategy events
    event LogStrategyHarvestReport(
        address indexed strategy,
        uint256 gain,
        uint256 loss,
        uint256 debtPaid,
        uint256 debtAdded,
        uint256 lockedProfit,
        uint256 lockedProfitBeforeLoss
    );

    event LogStrategyTotalChanges(
        address indexed strategy,
        uint256 totalGain,
        uint256 totalLoss,
        uint256 totalDebt
    );

    event LogWithdrawalFromStrategy(
        uint48 strategyId,
        uint256 strategyDebt,
        uint256 totalVaultDebt,
        uint256 lossFromStrategyWithdrawal
    );

    // Vault events
    event LogNewDebtRatio(
        address indexed strategy,
        uint256 debtRatio,
        uint256 vaultDebtRatio
    );

    event LogNewReleaseFactor(uint256 factor);
    event LogNewVaultFee(uint256 vaultFee);
    event LogNewfeeCollector(address feeCollector);

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(ERC20 _asset)
        ERC20(
            string(abi.encodePacked("Gro ", _asset.symbol(), " Vault")),
            string(abi.encodePacked("gro", _asset.symbol())),
            _asset.decimals()
        )
        Owned(msg.sender)
    {
        asset = _asset;
        minDeposit = 10**_asset.decimals();
        // 24 hours release window in seconds
        releaseTime = 86400;
    }

    /*//////////////////////////////////////////////////////////////
                            GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get number of strategies in underlying vault
    /// @return number of strategies in the withdrawal queue
    function getNoOfStrategies() external view returns (uint256) {
        return noOfStrategies();
    }

    /// @notice Helper function for strategy to get debt from vault
    function getStrategyDebt() external view returns (uint256) {
        return strategies[msg.sender].totalDebt;
    }

    /// @notice Get total invested in strategy
    /// @param _index index of strategy
    /// @return amount of total debt the strategies have to the GVault
    function getStrategyDebt(uint256 _index)
        external
        view
        returns (uint256 amount)
    {
        return strategies[nodes[_index].strategy].totalDebt;
    }

    /// @notice Helper function for strategy to get harvest data from vault
    function getStrategyData()
        external
        view
        returns (
            bool,
            uint256,
            uint256
        )
    {
        StrategyParams storage stratData = strategies[msg.sender];
        return (stratData.active, stratData.totalDebt, stratData.lastReport);
    }

    /*//////////////////////////////////////////////////////////////
                            SETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Set contract that will receive vault fees
    /// @param _feeCollector address of feeCollector contract
    function setFeeCollector(address _feeCollector) external onlyOwner {
        feeCollector = _feeCollector;
        emit LogNewfeeCollector(_feeCollector);
    }

    /// @notice Set fee that is reduced from strategy yields when harvests are called
    /// @param _fee new strategy fee
    function setVaultFee(uint256 _fee) external onlyOwner {
        if (_fee >= 3000) revert Errors.VaultFeeTooHigh();
        vaultFee = _fee;
        emit LogNewVaultFee(_fee);
    }

    /// @notice Set how quickly profits are released
    /// @param _time how quickly profits are released in seconds
    function setProfitRelease(uint256 _time) external onlyOwner {
        releaseTime = _time;
        emit LogNewReleaseFactor(_time);
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAW LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposit assets into the GVault
    /// @param _assets user deposit amount
    /// @param _receiver Address receiving the shares
    /// @return shares the number of shares minted during the deposit
    function deposit(uint256 _assets, address _receiver)
        external
        override
        nonReentrant
        returns (uint256 shares)
    {
        // Check for rounding error since we round down in previewDeposit.
        if (_assets < minDeposit) revert Errors.MinDeposit();
        if ((shares = previewDeposit(_assets)) == 0) revert Errors.ZeroShares();

        asset.safeTransferFrom(msg.sender, address(this), _assets);
        vaultAssets += _assets;

        _mint(_receiver, shares);

        emit Deposit(msg.sender, _receiver, _assets, shares);

        return shares;
    }

    /// @notice Request shares to be minted by depositing assets into the GVault
    /// @param _shares Amount of shares to be minted
    /// @param _receiver Address receiving the shares
    /// @return assets the number of asset tokens deposited during the mint of the
    /// vault shares
    function mint(uint256 _shares, address _receiver)
        external
        override
        nonReentrant
        returns (uint256 assets)
    {
        // Check for rounding error in previewMint.
        if ((assets = previewMint(_shares)) < minDeposit)
            revert Errors.MinDeposit();

        asset.safeTransferFrom(msg.sender, address(this), assets);
        vaultAssets += assets;

        _mint(_receiver, _shares);

        emit Deposit(msg.sender, _receiver, assets, _shares);

        return assets;
    }

    /// @notice withdraw assets from the GVault
    /// @param _assets the amount of want token the caller wants to withdraw
    /// @param _receiver address receiving the asset token
    /// @param _owner address that owns the 4626 shares that will be burnt
    /// @param _minAmount minAmount of assets to return
    /// @return shares the number of shares burnt during the withdrawal
    function withdraw(
        uint256 _assets,
        address _receiver,
        address _owner,
        uint256 _minAmount
    ) external nonReentrant returns (uint256 shares) {
        return _withdraw(_assets, _receiver, _owner, _minAmount);
    }

    /// @notice withdraw assets from the GVault
    /// @param _assets the amount of want token the caller wants to withdraw
    /// @param _receiver address receiving the asset token
    /// @param _owner address that owns the 4626 shares that will be burnt
    /// @return shares the number of shares burnt during the withdrawal
    function withdraw(
        uint256 _assets,
        address _receiver,
        address _owner
    ) external override nonReentrant returns (uint256 shares) {
        return _withdraw(_assets, _receiver, _owner, 0);
    }

    /// @notice Internal helper function for withdrawal - called by EIP-4626 standard withdraw function
    ///     or custom withdraw function with minAmount.
    function _withdraw(
        uint256 _assets,
        address _receiver,
        address _owner,
        uint256 _minAmount
    ) internal returns (uint256 shares) {
        if (_assets == 0) revert Errors.ZeroAssets();

        shares = previewWithdraw(_assets);

        if (shares > balanceOf[_owner]) revert Errors.InsufficientShares();

        if (msg.sender != _owner) {
            uint256 allowed = allowance[_owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max)
                allowance[_owner][msg.sender] = allowed - shares;
        }

        uint256 vaultBalance;
        (_assets, vaultBalance) = beforeWithdraw(_assets);

        if (_assets < _minAmount) revert Errors.InsufficientAssets();

        _burn(_owner, shares);

        asset.safeTransfer(_receiver, _assets);
        vaultAssets = vaultBalance - _assets;

        emit Withdraw(msg.sender, _receiver, _owner, _assets, shares);

        return shares;
    }

    /// @notice Redeem GVault shares for the equivalent amount of assets
    /// @param _shares the number of vault shares the caller wants to burn
    /// @param _receiver the address that will receive the asset tokens
    /// @param _owner the owner of the shares that will be burnt
    /// @return assets the amount of asset tokens sent to the receiver
    function redeem(
        uint256 _shares,
        address _receiver,
        address _owner
    ) external override nonReentrant returns (uint256 assets) {
        if (_shares == 0) revert Errors.ZeroShares();

        if (_shares > balanceOf[_owner]) revert Errors.InsufficientShares();

        if (msg.sender != _owner) {
            uint256 allowed = allowance[_owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max)
                allowance[_owner][msg.sender] = allowed - _shares;
        }

        assets = convertToAssets(_shares);
        uint256 vaultBalance;
        (assets, vaultBalance) = beforeWithdraw(assets);

        _burn(_owner, _shares);

        asset.safeTransfer(_receiver, assets);
        vaultAssets = vaultBalance - assets;

        emit Withdraw(msg.sender, _receiver, _owner, assets, _shares);

        return assets;
    }

    /*//////////////////////////////////////////////////////////////
                    DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice The maximum amount a user can deposit into the vault
    function maxDeposit(address)
        public
        view
        override
        returns (uint256 maxAssets)
    {
        return type(uint256).max - convertToAssets(totalSupply);
    }

    /// @notice Simulate the shares issued for a given deposit
    /// @param _assets number of asset tokens being deposited
    /// @return shares number of shares issued for the number of assets provided
    function previewDeposit(uint256 _assets)
        public
        view
        override
        returns (uint256 shares)
    {
        return convertToShares(_assets);
    }

    /// @notice maximum number of shares that can be minted
    function maxMint(address) public view override returns (uint256 maxShares) {
        return type(uint256).max - totalSupply;
    }

    /// @notice Simulate the number of assets required to mint a specific number of shares
    /// @param _shares number of shares to mint
    /// @return assets number of assets required to issue the shares inputted
    function previewMint(uint256 _shares)
        public
        view
        override
        returns (uint256 assets)
    {
        uint256 _totalSupply = totalSupply; // Saves an extra SLOAD if _totalSupply is non-zero.
        return
            _totalSupply == 0
                ? _shares
                : Math.ceilDiv((_shares * _freeFunds()), _totalSupply);
    }

    /// @notice maximum amount of asset tokens the owner can withdraw
    /// @param _owner address of the owner of the GVault Shares
    /// @return maxAssets maximum amount of asset tokens the owner can withdraw
    function maxWithdraw(address _owner)
        public
        view
        override
        returns (uint256 maxAssets)
    {
        return convertToAssets(balanceOf[_owner]);
    }

    /// @notice return the amount of shares that would be burned for a given number of assets
    /// @param _assets number of assert tokens to withdraw
    /// @return shares burnt during withdrawal
    function previewWithdraw(uint256 _assets)
        public
        view
        override
        returns (uint256 shares)
    {
        uint256 freeFunds_ = _freeFunds(); // Saves an extra SLOAD if _freeFunds is non-zero.
        return
            freeFunds_ == 0
                ? _assets
                : Math.ceilDiv(_assets * totalSupply, freeFunds_);
    }

    /// @notice maximum number of shares the owner can redeem
    /// @param _owner address for the owner of the GVault shares
    /// @return maxShares number of GVault shares the owner has
    function maxRedeem(address _owner)
        public
        view
        override
        returns (uint256 maxShares)
    {
        return balanceOf[_owner];
    }

    /// @notice Returns the amount of assets that can be redeemed with the shares
    /// @param _shares the number of shares the caller wants to redeem
    /// @return assets the number of asset tokens the caller would receive
    function previewRedeem(uint256 _shares)
        public
        view
        override
        returns (uint256 assets)
    {
        return convertToAssets(_shares);
    }

    /*//////////////////////////////////////////////////////////////
                        VAULT ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculate system total assets including estimated profits
    function totalAssets() external view override returns (uint256) {
        return _estimatedTotalAssets();
    }

    /// @notice Calculate system total assets excluding estimated profits
    function realizedTotalAssets() external view returns (uint256) {
        return _totalAssets();
    }

    /// @notice Value of asset in shares
    /// @param _assets amount of asset to convert to shares
    function convertToShares(uint256 _assets)
        public
        view
        override
        returns (uint256 shares)
    {
        uint256 freeFunds_ = _freeFunds(); // Saves an extra SLOAD if _freeFunds is non-zero.
        return freeFunds_ == 0 ? _assets : (_assets * totalSupply) / freeFunds_;
    }

    /// @notice Value of shares in underlying asset
    /// @param _shares amount of shares to convert to tokens
    function convertToAssets(uint256 _shares)
        public
        view
        override
        returns (uint256 assets)
    {
        uint256 _totalSupply = totalSupply; // Saves an extra SLOAD if _totalSupply is non-zero.
        return
            _totalSupply == 0
                ? _shares
                : ((_shares * _freeFunds()) / _totalSupply);
    }

    /// @notice Gives the price for a single Vault share.
    /// @return The value of a single share.
    function getPricePerShare() external view returns (uint256) {
        return convertToAssets(10**decimals);
    }

    /*//////////////////////////////////////////////////////////////
                            STRATEGY LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Number of active strategies in the vaultAdapter
    function noOfStrategies() internal view returns (uint256) {
        return strategyQueue.totalNodes;
    }

    /// @notice Update the debtRatio of a specific strategy
    /// @param _strategy target strategy
    /// @param _debtRatio new debt ratio
    function setDebtRatio(address _strategy, uint256 _debtRatio)
        external
        onlyOwner
    {
        if (!strategies[_strategy].active) revert Errors.StrategyNotActive();
        _setDebtRatio(_strategy, _debtRatio);
    }

    /// @notice Add a new strategy to the vault adapter
    /// @param _strategy target strategy to add
    /// @param _debtRatio target debtRatio of strategy
    function addStrategy(address _strategy, uint256 _debtRatio)
        external
        onlyOwner
    {
        if (_strategy == ZERO_ADDRESS) revert Errors.ZeroAddress();
        if (strategies[_strategy].active) revert Errors.StrategyActive();
        if (address(this) != IStrategy(_strategy).vault())
            revert Errors.IncorrectVaultOnStrategy();

        StrategyParams storage newStrat = strategies[_strategy];
        newStrat.active = true;
        _setDebtRatio(_strategy, _debtRatio);
        newStrat.lastReport = block.timestamp;

        _push(_strategy);
    }

    /// @notice remove existing strategy from vault by revoking and removing
    ///     from the withdrawal queue
    /// @param _strategy address of old strategy
    /// @dev Should be called when all the debt has been paid back to the vault
    function removeStrategy(address _strategy) external onlyOwner {
        if (!strategies[_strategy].active) revert Errors.StrategyNotActive();
        _revokeStrategy(_strategy);
        _removeStrategy(_strategy);
    }

    /// @notice remove strategy from the withdrawal queue
    /// @param _strategy address of strategy to remove
    function _removeStrategy(address _strategy) internal {
        if (strategies[_strategy].active) revert Errors.StrategyActive();
        if (strategies[_strategy].totalDebt > 0)
            revert Errors.StrategyDebtNotZero();

        _pop(_strategy);
    }

    /// @notice Remove strategy from vault adapter
    function revokeStrategy() external {
        if (!strategies[msg.sender].active) revert Errors.StrategyNotActive();
        _revokeStrategy(msg.sender);
    }

    /// @notice Move the strategy to a new position
    /// @param _strategy Target strategy to move
    /// @param _pos desired position of strategy
    /// @dev if the _pos value is >= number of strategies in the queue,
    ///      the strategy will be moved to the tail position
    function moveStrategy(address _strategy, uint256 _pos) external onlyOwner {
        uint256 currentPos = getStrategyPositions(_strategy);
        uint256 _strategyId = strategyId[_strategy];
        if (currentPos > _pos)
            move(uint48(_strategyId), uint48(currentPos - _pos), false);
        else move(uint48(_strategyId), uint48(_pos - currentPos), true);
    }

    /// @notice Check how much credits are available for the strategy
    /// @param _strategy Target strategy
    function creditAvailable(address _strategy)
        external
        view
        returns (uint256)
    {
        return _creditAvailable(_strategy);
    }

    /// @notice Same as above but called by the streategy
    function creditAvailable() external view returns (uint256) {
        return _creditAvailable(msg.sender);
    }

    /// @notice Amount of debt the strategy has to pay back to the vault at next harvest
    /// @param _strategy target strategy
    /// @return amount of debt the strategy has to pay back and the current debt ratio of the strategy
    function excessDebt(address _strategy)
        external
        view
        returns (uint256, uint256)
    {
        return _excessDebt(_strategy);
    }

    /// @notice Helper function to get strategy's total debt to the vault
    /// @dev here to simplify strategy's life when trying to get the totalDebt
    function strategyDebt() external view returns (uint256) {
        return strategies[msg.sender].totalDebt;
    }

    /// @notice Report back any gains/losses from a (strategy) harvest, vault adapter
    ///     calls back debt or gives out more credit to the strategy depending on available
    ///     credit and the strategies current position.
    /// @param _gain Strategy gains from latest harvest
    /// @param _loss Strategy losses from latest harvest
    /// @param _debtPayment Amount strategy can pay back to vault
    /// @param _emergency Flag to indicate if the harvest was an emergency harvest
    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment,
        bool _emergency
    ) external returns (uint256) {
        StrategyParams storage _strategy = strategies[msg.sender];
        if (!_strategy.active) revert Errors.StrategyNotActive();
        if (asset.balanceOf(msg.sender) < _debtPayment)
            revert Errors.IncorrectStrategyAccounting();

        if (_loss > 0) {
            _reportLoss(msg.sender, _loss);
        }
        if (_gain > 0) {
            _strategy.totalGain += _gain;
            _strategy.totalDebt += _gain;
            vaultTotalDebt += _gain;
        }

        if (_emergency) {
            _revokeStrategy(msg.sender);
        }

        (uint256 debt, ) = _excessDebt(msg.sender);
        uint256 debtPayment = Math.min(_debtPayment, debt);

        if (debtPayment > 0) {
            _strategy.totalDebt = _strategy.totalDebt - debtPayment;
            vaultTotalDebt -= debtPayment;
            debt -= debtPayment;
        }

        uint256 credit = _creditAvailable(msg.sender);

        if (credit > 0) {
            _strategy.totalDebt += credit;
            vaultTotalDebt += credit;
        }

        uint256 totalAvailable = debtPayment;

        if (totalAvailable < credit) {
            asset.safeTransfer(msg.sender, credit - totalAvailable);
            vaultAssets -= credit - totalAvailable;
        } else if (totalAvailable > credit) {
            asset.safeTransferFrom(
                msg.sender,
                address(this),
                totalAvailable - credit
            );
            vaultAssets += totalAvailable - credit;
        }

        // Profit is locked and gradually released per block
        // this computes current locked profit and replace with
        // the sum of the current and the new profit
        uint256 lockedProfitBeforeLoss = _calculateLockedProfit() +
            _calcFees(_gain);
        // Store how much loss remains after locked profit is removed,
        // here only for logging purposes
        if (lockedProfitBeforeLoss > _loss) {
            lockedProfit = lockedProfitBeforeLoss - _loss;
        } else {
            lockedProfit = 0;
        }

        lastReport = block.timestamp;
        _strategy.lastReport = lastReport;

        if (_emergency) {
            _removeStrategy(msg.sender);
        }

        emit LogStrategyHarvestReport(
            msg.sender,
            _gain,
            _loss,
            debtPayment,
            credit,
            lockedProfit,
            lockedProfitBeforeLoss
        );

        emit LogStrategyTotalChanges(
            msg.sender,
            _strategy.totalGain,
            _strategy.totalLoss,
            _strategy.totalDebt
        );

        return credit;
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL HOOKS
    //////////////////////////////////////////////////////////////*/

    /// @notice Runs before any withdraw function mainly to ensure vault has enough assets
    /// @param _assets Amount of assets to withdraw
    /// @return Amount of assets withdrawn and amount of assets in vault
    function beforeWithdraw(uint256 _assets)
        internal
        returns (uint256, uint256)
    {
        // If reserves dont cover the withdrawal, start withdrawing from strategies
        ERC20 _token = asset;
        uint256 vaultBalance = vaultAssets;
        if (_assets > vaultBalance) {
            uint48 _strategyId = strategyQueue.head;
            while (true) {
                address _strategy = nodes[_strategyId].strategy;
                // break if we have withdrawn all we need
                if (_assets <= vaultBalance) break;
                uint256 amountNeeded = _assets - vaultBalance;

                StrategyParams storage _strategyData = strategies[_strategy];
                amountNeeded = Math.min(amountNeeded, _strategyData.totalDebt);
                // If nothing is needed or strategy has no assets, continue
                if (amountNeeded > 0) {
                    (uint256 withdrawn, uint256 loss) = IStrategy(_strategy)
                        .withdraw(amountNeeded);

                    // Handle the loss if any
                    if (loss > 0) {
                        _assets = _assets - loss;
                        _reportLoss(_strategy, loss);
                    }
                    // Remove withdrawn amount from strategy and vault debts
                    _strategyData.totalDebt -= withdrawn;
                    vaultTotalDebt -= withdrawn;
                    vaultBalance += withdrawn;
                    emit LogWithdrawalFromStrategy(
                        _strategyId,
                        _strategyData.totalDebt,
                        vaultTotalDebt,
                        loss
                    );
                }
                _strategyId = nodes[_strategyId].next;
                if (_strategyId == 0) break;
            }
            if (_assets > vaultBalance) {
                _assets = vaultBalance;
            }
        }
        return (_assets, vaultBalance);
    }

    /// @notice Calculate how much profit is currently locked
    function _calculateLockedProfit() internal view returns (uint256) {
        uint256 _releaseTime = releaseTime;
        uint256 _timeSinceLastReport = block.timestamp - lastReport;
        if (_releaseTime > _timeSinceLastReport) {
            uint256 _lockedProfit = lockedProfit;
            return
                _lockedProfit -
                ((_lockedProfit * _timeSinceLastReport) / _releaseTime);
        } else {
            return 0;
        }
    }

    /// @notice the number of total assets the GVault has excluding profits
    /// and losses
    function _freeFunds() internal view returns (uint256) {
        return _totalAssets() - _calculateLockedProfit();
    }

    /// @notice Calculate the amount of assets the vault has available for the strategy to pull and invest,
    ///     the available credit is based on the strategies debt ratio and the total available assets
    ///     the vault has
    /// @param _strategy target strategy
    /// @dev called during harvest
    function _creditAvailable(address _strategy)
        internal
        view
        returns (uint256)
    {
        StrategyParams memory _strategyData = strategies[_strategy];
        uint256 vaultTotalAssets = _totalAssets();
        uint256 vaultDebtLimit = (vaultDebtRatio * vaultTotalAssets) /
            PERCENTAGE_DECIMAL_FACTOR;
        uint256 _vaultTotalDebt = vaultTotalDebt;
        uint256 strategyDebtLimit = (_strategyData.debtRatio *
            vaultTotalAssets) / PERCENTAGE_DECIMAL_FACTOR;
        uint256 strategyTotalDebt = _strategyData.totalDebt;

        if (
            strategyDebtLimit <= strategyTotalDebt ||
            vaultDebtLimit <= _vaultTotalDebt
        ) {
            return 0;
        }

        uint256 available = strategyDebtLimit - strategyTotalDebt;

        available = Math.min(available, vaultDebtLimit - _vaultTotalDebt);

        return Math.min(available, vaultAssets);
    }

    /// @notice Deal with any loss that a strategy has realized
    /// @param _strategy target strategy
    /// @param _loss amount of loss realized
    function _reportLoss(address _strategy, uint256 _loss) internal {
        StrategyParams storage strategy = strategies[_strategy];
        // Loss can only be up the amount of debt issued to strategy
        if (strategy.totalDebt < _loss) revert Errors.StrategyLossTooHigh();
        // Add loss to strategy and remove loss from strategyDebt
        strategy.totalLoss += _loss;
        strategy.totalDebt -= _loss;
        vaultTotalDebt -= _loss;
    }

    /// @notice Amount by which a strategy exceeds its current debt limit
    /// @param _strategy target strategy
    /// @return amount of debt the strategy has to pay back and the current debt ratio of the strategy
    function _excessDebt(address _strategy)
        internal
        view
        returns (uint256, uint256)
    {
        StrategyParams storage strategy = strategies[_strategy];
        uint256 _debtRatio = strategy.debtRatio;
        uint256 strategyDebtLimit = (_debtRatio * _totalAssets()) /
            PERCENTAGE_DECIMAL_FACTOR;
        uint256 strategyTotalDebt = strategy.totalDebt;

        if (strategyTotalDebt <= strategyDebtLimit) {
            return (0, _debtRatio);
        } else {
            return (strategyTotalDebt - strategyDebtLimit, _debtRatio);
        }
    }

    function _calcFees(uint256 _gain) internal returns (uint256) {
        uint256 fees = (_gain * vaultFee) / PERCENTAGE_DECIMAL_FACTOR;
        if (fees > 0) {
            uint256 shares = convertToShares(fees);
            _mint(feeCollector, shares);
        }
        return _gain - fees;
    }

    /// @notice Update a given strategys debt ratio
    /// @param _strategy target strategy
    /// @param _debtRatio new debt ratio
    /// @dev See setDebtRatio functions
    function _setDebtRatio(address _strategy, uint256 _debtRatio) internal {
        uint256 _vaultDebtRatio = vaultDebtRatio -
            strategies[_strategy].debtRatio +
            _debtRatio;
        if (_vaultDebtRatio > PERCENTAGE_DECIMAL_FACTOR)
            revert Errors.VaultDebtRatioTooHigh();
        strategies[_strategy].debtRatio = _debtRatio;
        vaultDebtRatio = _vaultDebtRatio;
        emit LogNewDebtRatio(_strategy, _debtRatio, _vaultDebtRatio);
    }

    /// @notice Get current estimated amount of assets in strategy
    /// @param _index index of strategy
    function _getStrategyEstimatedTotalAssets(uint256 _index)
        internal
        view
        returns (uint256)
    {
        return IStrategy(nodes[_index].strategy).estimatedTotalAssets();
    }

    /// @notice Remove strategy from vault
    /// @param _strategy address of strategy
    function _revokeStrategy(address _strategy) internal {
        vaultDebtRatio -= strategies[_strategy].debtRatio;
        strategies[_strategy].debtRatio = 0;
        strategies[_strategy].active = false;
    }

    /// @notice Vault adapters total assets including loose assets and debts
    /// @dev note that this does not consider estimated gains/losses from the strategies
    function _totalAssets() private view returns (uint256) {
        return vaultAssets + vaultTotalDebt;
    }

    /// @notice Vault adapters total assets including loose assets and estimated returns
    /// @dev note that this does consider estimated gains/losses from the strategies
    function _estimatedTotalAssets() private view returns (uint256) {
        uint256 total = vaultAssets;
        uint256[MAXIMUM_STRATEGIES] memory _queue = fullWithdrawalQueue();
        for (uint256 i = 0; i < noOfStrategies(); ++i) {
            total += _getStrategyEstimatedTotalAssets(_queue[i]);
        }
        return total;
    }
}