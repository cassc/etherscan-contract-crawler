// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {StrategyParams, IOnChainVault} from "./interfaces/IOnChainVault.sol";
import {IBaseStrategy} from "./interfaces/IBaseStrategy.sol";

contract OnChainVault is
    Initializable,
    ERC20Upgradeable,
    IOnChainVault,
    OwnableUpgradeable
{
    uint256 public constant SECS_PER_YEAR = 31_556_952;
    uint256 public constant MAX_BPS = 10_000;
    uint256 public constant DEGRADATION_COEFFICIENT = 10 ** 18;
    uint256 public constant lockedProfitDegradation =
        (DEGRADATION_COEFFICIENT * 46) / 10 ** 6;
    uint256 public lockedProfit;
    uint256 public lastReport;
    address public override governance;
    address public treasury;
    IERC20 public override token;
    uint256 public depositLimit;
    uint256 public totalDebtRatio;
    uint256 public totalDebt;
    uint256 public managementFee;
    uint256 public performanceFee;
    address public management;
    bool public emergencyShutdown;

    bool public isInjectedOnce;
    uint256 public injectedTotalSupply;
    uint256 public injectedFreeFunds;

    mapping(address => StrategyParams) public strategies;
    mapping(address strategy => uint256 position)
        public strategyPositionInArray;

    address[] public OnChainStrategies;

    using SafeERC20 for IERC20;
    using SafeERC20 for ERC20;

    function initialize(
        IERC20 _token,
        address _governance,
        address _treasury,
        string calldata name,
        string calldata symbol
    ) external initializer {
        __Ownable_init();
        __ERC20_init(name, symbol);

        governance = _governance;
        token = _token;
        treasury = _treasury;
        approve(treasury, type(uint256).max);
    }

    modifier onlyAuthorized() {
        if (
            msg.sender != governance &&
            msg.sender != owner() &&
            msg.sender != management
        ) revert Vault__OnlyAuthorized(msg.sender);
        _;
    }

    function injectForMigration(
        uint256 _injectedTotalSupply,
        uint256 _injectedFreeFunds
    ) external onlyAuthorized {
        if (!isInjectedOnce) {
            injectedTotalSupply = _injectedTotalSupply;
            injectedFreeFunds = _injectedFreeFunds;
            isInjectedOnce = true;
        } else {
            revert("Cannot inject twice.");
        }
    }

    function totalSupply() public view override returns (uint256) {
        if (injectedTotalSupply > 0) {
            return injectedTotalSupply;
        }
        return super.totalSupply();
    }

    modifier checkAmountOnDeposit(uint256 amount) {
        if (amount + totalAssets() > depositLimit || amount == 0) {
            revert Vault__AmountIsIncorrect(amount);
        }
        _;
    }

    function decimals() public view virtual override returns (uint8) {
        return ERC20(address(token)).decimals();
    }

    function revokeFunds() external onlyAuthorized {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setEmergencyShutdown(
        bool _emergencyShutdown
    ) external onlyAuthorized {
        emergencyShutdown = _emergencyShutdown;
    }

    function setTreasury(address _newTreasuryAddress) external onlyAuthorized {
        treasury = _newTreasuryAddress;
    }

    function setDepositLimit(uint256 _limit) external onlyAuthorized {
        depositLimit = _limit;
    }

    //!Tests are not working with this implementation of PPS
    function totalAssets() public view returns (uint256 _assets) {
        for (uint256 i = 0; i < OnChainStrategies.length; i++) {
            _assets += IBaseStrategy(OnChainStrategies[i])
                .estimatedTotalAssets();
        }
        _assets += totalIdle();
        // _assets += totalIdle() + totalDebt;
    }

    function setPerformanceFee(uint256 fee) external onlyAuthorized {
        if (fee > MAX_BPS / 2) revert Vault__UnAcceptableFee();
        performanceFee = fee;
    }

    function setManagementFee(uint256 fee) external onlyAuthorized {
        if (fee > MAX_BPS) revert Vault__UnAcceptableFee();
        managementFee = fee;
    }

    function setManagement(address _management) external onlyAuthorized {
        management = _management;
    }

    function totalIdle() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function updateStrategyMinDebtPerHarvest(
        address strategy,
        uint256 _minDebtPerHarvest
    ) external onlyAuthorized {
        if (strategies[strategy].activation == 0)
            revert Vault__InactiveStrategy();
        if (strategies[strategy].maxDebtPerHarvest <= _minDebtPerHarvest)
            revert Vault__MinMaxDebtError();
        strategies[strategy].minDebtPerHarvest = _minDebtPerHarvest;
    }

    function updateStrategyMaxDebtPerHarvest(
        address strategy,
        uint256 _maxDebtPerHarvest
    ) external onlyAuthorized {
        if (strategies[strategy].activation == 0)
            revert Vault__InactiveStrategy();
        if (strategies[strategy].minDebtPerHarvest >= _maxDebtPerHarvest)
            revert Vault__MinMaxDebtError();
        strategies[strategy].maxDebtPerHarvest = _maxDebtPerHarvest;
    }

    function deposit(
        uint256 _amount,
        address _recipient
    ) external checkAmountOnDeposit(_amount) returns (uint256) {
        return _deposit(_amount, _recipient);
    }

    function deposit(
        uint256 _amount
    ) external checkAmountOnDeposit(_amount) returns (uint256) {
        return _deposit(_amount, msg.sender);
    }

    function withdraw(
        uint256 _maxShares,
        address _recipient,
        uint256 _maxLoss
    ) external {
        _initiateWithdraw(_maxShares, _recipient, _maxLoss);
    }

    function addStrategy(
        address _strategy,
        uint256 _debtRatio,
        uint256 _performanceFee,
        uint256 _minDebtPerHarvest,
        uint256 _maxDebtPerHarvest
    ) external onlyAuthorized {
        if (strategies[_strategy].activation != 0) revert Vault__V2();
        if (totalDebtRatio + _debtRatio > MAX_BPS) revert Vault__V3();
        if (_performanceFee > MAX_BPS / 2) revert Vault__UnAcceptableFee();
        if (_minDebtPerHarvest > _maxDebtPerHarvest)
            revert Vault__MinMaxDebtError();
        strategies[_strategy] = StrategyParams({
            performanceFee: _performanceFee,
            activation: block.timestamp,
            debtRatio: _debtRatio,
            minDebtPerHarvest: _minDebtPerHarvest,
            maxDebtPerHarvest: _maxDebtPerHarvest,
            lastReport: 0,
            totalDebt: 0,
            totalGain: 0,
            totalLoss: 0
        });

        totalDebtRatio += _debtRatio;
        strategyPositionInArray[_strategy] = OnChainStrategies.length;
        OnChainStrategies.push(_strategy);
    }

    function debtOutstanding(
        address _strategy
    ) external view returns (uint256) {
        return _debtOutstanding(_strategy);
    }

    function debtOutstanding() external view returns (uint256) {
        return _debtOutstanding(msg.sender);
    }

    function creditAvailable(
        address _strategy
    ) external view returns (uint256) {
        return _creditAvailable(_strategy);
    }

    function _initiateWithdraw(
        uint256 maxShares,
        address recipient,
        uint256 maxLoss
    ) internal returns (uint256) {
        uint256 shares = maxShares;
        if (maxLoss > MAX_BPS) revert Vault__V4();
        if (shares == type(uint256).max) {
            shares = balanceOf(msg.sender);
        }
        if (shares > balanceOf(msg.sender)) revert Vault__NotEnoughShares();
        if (shares == 0) revert Vault__ZeroToWithdraw();

        uint256 value = _shareValue(shares);
        uint256 vaultBalance = totalIdle();
        if (value > vaultBalance) {
            uint256 totalLoss;
            for (uint256 i = 0; i < OnChainStrategies.length; i++) {
                if (value <= vaultBalance) {
                    break;
                }
                uint256 amountNeeded = value - vaultBalance;
                amountNeeded = Math.min(
                    amountNeeded,
                    // IBaseStrategy(OnChainStrategies[i]).estimatedTotalAssets()
                    strategies[OnChainStrategies[i]].totalDebt
                );
                if (amountNeeded == 0) {
                    continue;
                }
                uint256 balanceBefore = token.balanceOf(address(this));
                uint256 loss = IBaseStrategy(OnChainStrategies[i]).withdraw(
                    amountNeeded
                );
                uint256 withdrawn = token.balanceOf(address(this)) -
                    balanceBefore;
                vaultBalance += withdrawn;
                if (loss > 0) {
                    value -= loss;
                    totalLoss += loss;
                    _reportLoss(OnChainStrategies[i], loss);
                }
                strategies[OnChainStrategies[i]].totalDebt -= withdrawn;
                totalDebt -= withdrawn;
                emit StrategyWithdrawnSome(
                    OnChainStrategies[i],
                    strategies[OnChainStrategies[i]].totalDebt,
                    loss
                );
            }
            if (value > vaultBalance) {
                value = vaultBalance;
                shares = _sharesForAmount(value + totalLoss);
                require(
                    shares < balanceOf(msg.sender),
                    "shares amount to burn grater than balance of user"
                );
            }
            if (totalLoss > (maxLoss * (value + totalLoss)) / MAX_BPS)
                revert Vault__UnacceptableLoss();
        }

        _burn(msg.sender, shares);
        token.safeTransfer(recipient, value);
        emit Withdraw(recipient, shares, value);
        return value;
    }

    function pricePerShare() external view returns (uint256) {
        return _shareValue(10 ** decimals());
    }

    function revokeStrategy(address _strategy) external onlyAuthorized {
        _revokeStrategy(_strategy);
    }

    function revokeStrategy() external {
        require(
            msg.sender == governance ||
                msg.sender == owner() ||
                msg.sender ==
                OnChainStrategies[strategyPositionInArray[msg.sender]],
            "notAuthorized"
        );
        _revokeStrategy(msg.sender);
    }

    function updateStrategyDebtRatio(
        address _strategy,
        uint256 _debtRatio
    ) external onlyAuthorized {
        if (strategies[_strategy].activation == 0)
            revert Vault__InactiveStrategy();

        totalDebtRatio -= strategies[_strategy].debtRatio;
        strategies[_strategy].debtRatio = _debtRatio;
        if (totalDebtRatio + _debtRatio > MAX_BPS) revert Vault__V6();
        totalDebtRatio += _debtRatio;
    }

    function migrateStrategy(
        address _oldStrategy,
        address _newStrategy
    ) external onlyAuthorized {
        if (_newStrategy == address(0)) revert Vault__V7();
        if (strategies[_oldStrategy].activation == 0) revert Vault__V8();
        if (strategies[_newStrategy].activation > 0) revert Vault__V9();
        StrategyParams memory params = strategies[_oldStrategy];
        _revokeStrategy(_oldStrategy);
        totalDebtRatio += params.debtRatio;

        strategies[_newStrategy] = StrategyParams({
            performanceFee: params.performanceFee,
            activation: params.lastReport,
            debtRatio: params.debtRatio,
            minDebtPerHarvest: params.minDebtPerHarvest,
            maxDebtPerHarvest: params.maxDebtPerHarvest,
            lastReport: params.lastReport,
            totalDebt: params.totalDebt,
            totalGain: 0,
            totalLoss: 0
        });
        strategies[_oldStrategy].totalDebt = 0;

        IBaseStrategy(_oldStrategy).migrate(_newStrategy);
        OnChainStrategies[strategyPositionInArray[_oldStrategy]] = _newStrategy;
        strategyPositionInArray[_newStrategy] = strategyPositionInArray[
            _oldStrategy
        ];
        strategyPositionInArray[_oldStrategy] = 0;
    }

    function _deposit(
        uint256 _amount,
        address _recipient
    ) internal returns (uint256) {
        if (emergencyShutdown) revert Vault__V13();
        uint256 shares = _issueSharesForAmount(_recipient, _amount);
        token.safeTransferFrom(msg.sender, address(this), _amount);
        return shares;
    }

    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external returns (uint256) {
        if (strategies[msg.sender].activation == 0) revert Vault__V14();

        if (_loss > 0) {
            _reportLoss(msg.sender, _loss);
        }
        uint256 totalFees = _assessFees(msg.sender, _gain);
        strategies[msg.sender].totalGain += _gain;
        uint256 credit = _creditAvailable(msg.sender);

        uint256 debt = _debtOutstanding(msg.sender);
        uint256 debtPayment = Math.min(debt, _debtPayment);

        if (debtPayment > 0) {
            strategies[msg.sender].totalDebt -= debtPayment;
            totalDebt -= debtPayment;
            debt -= debtPayment;
        }

        if (credit > 0) {
            strategies[msg.sender].totalDebt += credit;
            totalDebt += credit;
        }

        uint256 totalAvail = _gain + debtPayment;
        if (totalAvail < credit) {
            token.safeTransfer(msg.sender, credit - totalAvail);
        } else if (totalAvail > credit) {
            token.safeTransferFrom(
                msg.sender,
                address(this),
                totalAvail - credit
            );
        }

        uint256 lockedProfitBeforeLoss = _calculateLockedProfit() +
            _gain -
            totalFees;
        if (lockedProfitBeforeLoss > _loss) {
            lockedProfit = lockedProfitBeforeLoss - _loss;
        } else {
            lockedProfit = 0;
        }

        strategies[msg.sender].lastReport = block.timestamp;
        lastReport = block.timestamp;

        StrategyParams memory params = strategies[msg.sender];
        emit StrategyReported(
            msg.sender,
            _gain,
            _loss,
            _debtPayment,
            params.totalGain,
            params.totalLoss,
            params.totalDebt,
            credit,
            params.debtRatio
        );
        if (strategies[msg.sender].debtRatio == 0 || emergencyShutdown) {
            return IBaseStrategy(msg.sender).estimatedTotalAssets();
        } else {
            return debt;
        }
    }

    function _calculateLockedProfit() internal view returns (uint256) {
        uint256 lockedFundsRatio = (block.timestamp - lastReport) *
            lockedProfitDegradation;
        if (lockedFundsRatio < DEGRADATION_COEFFICIENT) {
            uint256 _lockedProfit = lockedProfit;
            return
                _lockedProfit -
                ((lockedFundsRatio * _lockedProfit) / DEGRADATION_COEFFICIENT);
        } else {
            return 0;
        }
    }

    function _reportLoss(address _strategy, uint256 _loss) internal {
        if (strategies[_strategy].totalDebt < _loss) revert Vault__V15();

        if (totalDebtRatio != 0) {
            uint256 ratioChange = Math.min(
                (_loss * totalDebtRatio) / totalDebt,
                strategies[_strategy].debtRatio
            );
            strategies[_strategy].debtRatio -= ratioChange;
            totalDebtRatio -= ratioChange;
        }
        strategies[_strategy].totalLoss += _loss;
        strategies[_strategy].totalDebt -= _loss;
        totalDebt -= _loss;
    }

    function _freeFunds() internal view returns (uint256) {
        if (injectedFreeFunds > 0) {
            return injectedFreeFunds;
        }
        return totalAssets() - _calculateLockedProfit();
    }

    function _shareValue(uint256 _shares) internal view returns (uint256) {
        if (totalSupply() == 0) {
            return _shares;
        }
        return (_shares * _freeFunds()) / totalSupply();
    }

    function _sharesForAmount(uint256 amount) internal view returns (uint256) {
        uint256 _freeFund = _freeFunds();
        if (_freeFund > 0) {
            return ((amount * totalSupply()) / _freeFund);
        } else {
            return 0;
        }
    }

    function maxAvailableShares() external view returns (uint256) {
        uint256 shares = _sharesForAmount(totalIdle());
        for (uint256 i = 0; i < OnChainStrategies.length; i++) {
            shares += _sharesForAmount(
                strategies[OnChainStrategies[i]].totalDebt
            );
        }
        return shares;
    }

    function _issueSharesForAmount(
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        uint256 shares = 0;
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            shares = _amount;
        } else {
            shares = (_amount * _totalSupply) / _freeFunds();
            if (injectedTotalSupply > 0) {
                injectedTotalSupply = 0;
            }
            if (injectedFreeFunds > 0) {
                injectedFreeFunds = 0;
            }
        }
        if (shares == 0) revert Vault__V17();
        _mint(_to, shares);
        return shares;
    }

    function _revokeStrategy(address _strategy) internal {
        totalDebtRatio -= strategies[_strategy].debtRatio;
        strategies[_strategy].debtRatio = 0;
    }

    function _creditAvailable(
        address _strategy
    ) internal view returns (uint256) {
        if (emergencyShutdown) {
            return 0;
        }
        uint256 strategyDebtLimit = (strategies[_strategy].debtRatio *
            totalAssets()) / MAX_BPS;
        uint256 strategyTotalDebt = strategies[_strategy].totalDebt;

        uint256 vaultDebtLimit = (totalDebtRatio * totalAssets()) / MAX_BPS;
        uint256 vaultTotalDebt = totalDebt;

        if (
            strategyDebtLimit <= strategyTotalDebt ||
            vaultDebtLimit <= totalDebt
        ) {
            return 0;
        }
        uint256 available = strategyDebtLimit - strategyTotalDebt;
        available = Math.min(available, vaultDebtLimit - vaultTotalDebt);
        return Math.min(totalIdle(), available);
    }

    function _debtOutstanding(
        address _strategy
    ) internal view returns (uint256) {
        if (totalDebtRatio == 0) {
            return strategies[_strategy].totalDebt;
        }
        uint256 strategyDebtLimit = (strategies[_strategy].debtRatio *
            totalAssets()) / MAX_BPS;
        uint256 strategyTotalDebt = strategies[_strategy].totalDebt;

        if (emergencyShutdown) {
            return strategyTotalDebt;
        } else if (strategyTotalDebt <= strategyDebtLimit) {
            return 0;
        } else {
            return strategyTotalDebt - strategyDebtLimit;
        }
    }

    function _assessFees(
        address strategy,
        uint256 gain
    ) internal returns (uint256) {
        if (strategies[strategy].activation == block.timestamp) {
            return 0;
        }

        uint256 duration = block.timestamp - strategies[strategy].lastReport;

        require(duration != 0, "can't assessFees twice within the same block");

        if (gain == 0) {
            return 0;
        }

        uint256 _managementFee = ((strategies[strategy].totalDebt -
            IBaseStrategy(strategy).delegatedAssets()) *
            duration *
            managementFee) /
            MAX_BPS /
            SECS_PER_YEAR;
        uint256 _strategistFee = (gain * strategies[strategy].performanceFee) /
            MAX_BPS;
        uint256 _performanceFee = (gain * performanceFee) / MAX_BPS;
        uint256 totalFee = _managementFee + _strategistFee + _performanceFee;
        if (totalFee > gain) {
            totalFee = gain;
        }
        if (totalFee > 0) {
            uint256 reward = _issueSharesForAmount(address(this), totalFee);
            if (_strategistFee > 0) {
                uint256 strategistReward = (_strategistFee * reward) / totalFee;
                transfer(treasury, strategistReward);
            }
            if (balanceOf(address(this)) > 0) {
                transfer(treasury, balanceOf(address(this)));
            }
        }
        return totalFee;
    }

    receive() external payable {}
}