// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./libraries/DecimalsConverter.sol";

import "./interfaces/ICapitalPool.sol";
import "./interfaces/IClaimingRegistry.sol";
import "./interfaces/IContractsRegistry.sol";
import "./interfaces/ILeveragePortfolio.sol";
import "./interfaces/ILiquidityRegistry.sol";
import "./interfaces/IPolicyBook.sol";
import "./interfaces/IPolicyBookRegistry.sol";
import "./interfaces/IYieldGenerator.sol";
import "./interfaces/ILeveragePortfolioView.sol";

import "./abstract/AbstractDependant.sol";

import "./Globals.sol";

contract CapitalPool is ICapitalPool, OwnableUpgradeable, AbstractDependant {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;
    using Math for uint256;

    uint256 public constant ADDITIONAL_WITHDRAW_PERIOD = 1 days;

    IClaimingRegistry public claimingRegistry;
    IPolicyBookRegistry public policyBookRegistry;
    IYieldGenerator public yieldGenerator;
    ILeveragePortfolio public reinsurancePool;
    ILiquidityRegistry public liquidityRegistry;
    ILeveragePortfolioView public leveragePortfolioView;
    ERC20 public stblToken;

    // reisnurance pool vStable balance updated by(premium, interest from defi)
    uint256 public reinsurancePoolBalance;
    // user leverage pool vStable balance updated by(premium, addliq, withdraw liq)
    mapping(address => uint256) public leveragePoolBalance;
    // policy books vStable balances updated by(premium, addliq, withdraw liq)
    mapping(address => uint256) public regularCoverageBalance;
    // all hStable capital balance , updated by (all pool transfer + deposit to dfi + liq cushion)
    uint256 public hardUsdtAccumulatedBalance;
    // all vStable capital balance , updated by (all pool transfer + withdraw from liq cushion)
    uint256 public override virtualUsdtAccumulatedBalance;
    // pool balances tracking
    uint256 public override liquidityCushionBalance;
    address public maintainer;

    uint256 public stblDecimals;

    // new state post v2 deployemnt
    bool public isLiqCushionPaused;
    bool public automaticHardRebalancing;

    uint256 public override rebalanceDuration;
    bool private deployFundsToDefi;

    event PoolBalancesUpdated(
        uint256 hardUsdtAccumulatedBalance,
        uint256 virtualUsdtAccumulatedBalance,
        uint256 liquidityCushionBalance,
        uint256 reinsurancePoolBalance
    );

    event LiquidityCushionRebalanced(
        uint256 liquidityNeede,
        uint256 liquidityWithdraw,
        uint256 liquidityDeposit
    );

    modifier broadcastBalancing() {
        _;
        emit PoolBalancesUpdated(
            hardUsdtAccumulatedBalance,
            virtualUsdtAccumulatedBalance,
            liquidityCushionBalance,
            reinsurancePoolBalance
        );
    }

    modifier onlyPolicyBook() {
        require(policyBookRegistry.isPolicyBook(msg.sender), "CAPL: Not a PolicyBook");
        _;
    }

    modifier onlyReinsurancePool() {
        require(
            address(reinsurancePool) == _msgSender(),
            "RP: Caller is not a reinsurance pool contract"
        );
        _;
    }

    modifier onlyClaimingRegistry() {
        require(
            address(claimingRegistry) == _msgSender(),
            "CP: Caller is not claiming registry contract"
        );
        _;
    }

    modifier onlyMaintainer() {
        require(_msgSender() == maintainer, "CP: not maintainer");
        _;
    }

    function __CapitalPool_init() external initializer {
        __Ownable_init();
        maintainer = _msgSender();
        rebalanceDuration = 3 days;
        deployFundsToDefi = true;
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        claimingRegistry = IClaimingRegistry(_contractsRegistry.getClaimingRegistryContract());
        policyBookRegistry = IPolicyBookRegistry(
            _contractsRegistry.getPolicyBookRegistryContract()
        );
        stblToken = ERC20(_contractsRegistry.getUSDTContract());
        yieldGenerator = IYieldGenerator(_contractsRegistry.getYieldGeneratorContract());
        reinsurancePool = ILeveragePortfolio(_contractsRegistry.getReinsurancePoolContract());
        liquidityRegistry = ILiquidityRegistry(_contractsRegistry.getLiquidityRegistryContract());
        leveragePortfolioView = ILeveragePortfolioView(
            _contractsRegistry.getLeveragePortfolioViewContract()
        );
        stblDecimals = stblToken.decimals();
    }

    /// @notice distributes the policybook premiums into pools (CP, ULP , RP)
    /// @dev distributes the balances acording to the established percentages
    /// @param _stblAmount amount hardSTBL ingressed into the system
    /// @param _epochsNumber uint256 the number of epochs which the policy holder will pay a premium for
    /// @param _protocolFee uint256 the amount of protocol fee earned by premium
    function addPolicyHoldersHardSTBL(
        uint256 _stblAmount,
        uint256 _epochsNumber,
        uint256 _protocolFee
    ) external override onlyPolicyBook broadcastBalancing returns (uint256) {
        PremiumFactors memory factors;

        factors.vStblOfCP = regularCoverageBalance[_msgSender()];
        factors.premiumPrice = _stblAmount.sub(_protocolFee);

        factors.policyBookFacade = IPolicyBookFacade(IPolicyBook(_msgSender()).policyBookFacade());

        factors.vStblDeployedByRP = DecimalsConverter.convertFrom18(
            factors.policyBookFacade.VUreinsurnacePool(),
            stblDecimals
        );

        factors.userLeveragePoolsCount = factors.policyBookFacade.countUserLeveragePools();
        factors.epochsNumber = _epochsNumber;

        uint256 reinsurancePoolPremium;
        uint256 coveragePoolPremium;

        if (factors.vStblDeployedByRP == 0 && factors.userLeveragePoolsCount == 0) {
            coveragePoolPremium = factors.premiumPrice;
        } else {
            (reinsurancePoolPremium, coveragePoolPremium) = _calcPremiumForAllPools(factors);
        }

        uint256 reinsurancePoolTotalPremium = reinsurancePoolPremium.add(_protocolFee);
        reinsurancePoolBalance = reinsurancePoolBalance.add(reinsurancePoolTotalPremium);
        reinsurancePool.addPolicyPremium(
            _epochsNumber,
            DecimalsConverter.convertTo18(reinsurancePoolTotalPremium, stblDecimals)
        );

        regularCoverageBalance[_msgSender()] = regularCoverageBalance[_msgSender()].add(
            coveragePoolPremium
        );
        hardUsdtAccumulatedBalance = hardUsdtAccumulatedBalance.add(_stblAmount);
        virtualUsdtAccumulatedBalance = virtualUsdtAccumulatedBalance.add(_stblAmount);
        return DecimalsConverter.convertTo18(coveragePoolPremium, stblDecimals);
    }

    function _calcPremiumForAllPools(PremiumFactors memory factors)
        internal
        returns (uint256 reinsurancePoolPremium, uint256 coveragePoolPremium)
    {
        uint256 _totalCoverTokens =
            DecimalsConverter.convertFrom18(
                (IPolicyBook(_msgSender())).totalCoverTokens(),
                stblDecimals
            );

        factors.poolUtilizationRation = _totalCoverTokens.mul(PERCENTAGE_100).div(
            factors.vStblOfCP
        );

        uint256 _participatedLeverageAmounts;

        if (factors.userLeveragePoolsCount > 0) {
            address[] memory _userLeverageArr =
                factors.policyBookFacade.listUserLeveragePools(0, factors.userLeveragePoolsCount);

            for (uint256 i = 0; i < _userLeverageArr.length; i++) {
                _participatedLeverageAmounts = _participatedLeverageAmounts.add(
                    clacParticipatedLeverageAmount(factors, _userLeverageArr[i])
                );
            }
        }
        uint256 totalLiqforPremium =
            factors.vStblOfCP.add(factors.vStblDeployedByRP).add(_participatedLeverageAmounts);

        factors.premiumPerDeployment = (factors.premiumPrice.mul(PRECISION)).div(
            totalLiqforPremium
        );

        reinsurancePoolPremium = _calcReinsurancePoolPremium(factors);

        if (factors.userLeveragePoolsCount > 0) {
            _calcUserLeveragePoolPremium(factors);
        }
        coveragePoolPremium = _calcCoveragePoolPremium(factors);
    }

    /// @notice distributes the hardSTBL from the coverage providers
    /// @dev emits PoolBalancedUpdated event
    /// @param _stblAmount amount hardSTBL ingressed into the system
    function addCoverageProvidersHardSTBL(uint256 _stblAmount)
        external
        override
        onlyPolicyBook
        broadcastBalancing
    {
        regularCoverageBalance[_msgSender()] = regularCoverageBalance[_msgSender()].add(
            _stblAmount
        );
        hardUsdtAccumulatedBalance = hardUsdtAccumulatedBalance.add(_stblAmount);
        virtualUsdtAccumulatedBalance = virtualUsdtAccumulatedBalance.add(_stblAmount);
    }

    //// @notice distributes the hardSTBL from the leverage providers
    /// @dev emits PoolBalancedUpdated event
    /// @param _stblAmount amount hardSTBL ingressed into the system
    function addLeverageProvidersHardSTBL(uint256 _stblAmount)
        external
        override
        onlyPolicyBook
        broadcastBalancing
    {
        leveragePoolBalance[_msgSender()] = leveragePoolBalance[_msgSender()].add(_stblAmount);
        hardUsdtAccumulatedBalance = hardUsdtAccumulatedBalance.add(_stblAmount);
        virtualUsdtAccumulatedBalance = virtualUsdtAccumulatedBalance.add(_stblAmount);
    }

    /// @notice distributes the hardSTBL from the reinsurance pool
    /// @dev emits PoolBalancedUpdated event
    /// @param _stblAmount amount hardSTBL ingressed into the system
    function addReinsurancePoolHardSTBL(uint256 _stblAmount)
        external
        override
        onlyReinsurancePool
        broadcastBalancing
    {
        reinsurancePoolBalance = reinsurancePoolBalance.add(_stblAmount);
        hardUsdtAccumulatedBalance = hardUsdtAccumulatedBalance.add(_stblAmount);
        virtualUsdtAccumulatedBalance = virtualUsdtAccumulatedBalance.add(_stblAmount);
    }

    function addWithdrawalHardSTBL(uint256 _stblAmount, uint256 _accumaltedAmount)
        external
        override
    {
        require(
            address(yieldGenerator) == _msgSender(),
            "CP: Caller is not a yield generator contract"
        );
        hardUsdtAccumulatedBalance = hardUsdtAccumulatedBalance.add(_stblAmount).add(
            _accumaltedAmount
        );

        reinsurancePoolBalance = reinsurancePoolBalance.add(_accumaltedAmount);
        virtualUsdtAccumulatedBalance = virtualUsdtAccumulatedBalance.add(_accumaltedAmount);
    }

    /// @notice rebalances pools acording to v2 specification and dao enforced policies
    /// @dev  emits PoolBalancesUpdated
    function rebalanceLiquidityCushion() public override broadcastBalancing onlyMaintainer {
        require(!isLiqCushionPaused, "CP: liqudity cushion is pasued");

        //check defi protocol balances
        (, uint256 _lostAmount) = yieldGenerator.reevaluateDefiProtocolBalances();

        if (_lostAmount > 0) {
            isLiqCushionPaused = true;
            if (automaticHardRebalancing) {
                defiHardRebalancing();
            }
        }

        // hard rebalancing - Stop all withdrawals from all pools
        if (isLiqCushionPaused) {
            hardUsdtAccumulatedBalance = hardUsdtAccumulatedBalance.add(liquidityCushionBalance);
            liquidityCushionBalance = 0;
            return;
        }

        uint256 _pendingClaimAmount =
            claimingRegistry.getAllPendingClaimsAmount(
                claimingRegistry.getWithdrawClaimRequestIndexListCount()
            );
        uint256 _pendingRewardAmount =
            claimingRegistry.getAllPendingRewardsAmount(
                claimingRegistry.getWithdrawRewardRequestVoterListCount()
            );

        uint256 _pendingWithdrawlAmount =
            liquidityRegistry.getAllPendingWithdrawalRequestsAmount(
                liquidityRegistry.getWithdrawlRequestUsersListCount()
            );

        uint256 _requiredLiquidity =
            _pendingWithdrawlAmount.add(_pendingClaimAmount).add(_pendingRewardAmount);

        _requiredLiquidity = DecimalsConverter.convertFrom18(_requiredLiquidity, stblDecimals);

        (uint256 _deposit, uint256 _withdraw) = getDepositAndWithdraw(_requiredLiquidity);

        liquidityCushionBalance = _requiredLiquidity;

        hardUsdtAccumulatedBalance = 0;

        uint256 _actualAmount;
        if (_deposit > 0) {
            stblToken.safeApprove(address(yieldGenerator), 0);
            stblToken.safeApprove(address(yieldGenerator), _deposit);

            _actualAmount = yieldGenerator.deposit(_deposit);
            if (_actualAmount < _deposit) {
                hardUsdtAccumulatedBalance = hardUsdtAccumulatedBalance.add(
                    (_deposit.sub(_actualAmount))
                );
            }
        } else if (_withdraw > 0) {
            _actualAmount = yieldGenerator.withdraw(_withdraw);
            if (_actualAmount < _withdraw) {
                liquidityCushionBalance = liquidityCushionBalance.sub(
                    (_withdraw.sub(_actualAmount))
                );
            }
        }

        emit LiquidityCushionRebalanced(_requiredLiquidity, _withdraw, _deposit);
    }

    /// @param _rebalanceDuration parameter passes in seconds
    function setRebalanceDuration(uint256 _rebalanceDuration) public onlyOwner {
        require(_rebalanceDuration <= 7 days, "CP: invalid rebalance duration");
        rebalanceDuration = _rebalanceDuration;
    }

    function defiHardRebalancing() public onlyOwner {
        (uint256 _totalDeposit, uint256 _lostAmount) =
            yieldGenerator.reevaluateDefiProtocolBalances();

        if (_lostAmount > 0 && _totalDeposit > _lostAmount) {
            uint256 _lostPercentage =
                _lostAmount.mul(PERCENTAGE_100).div(virtualUsdtAccumulatedBalance);

            address[] memory _policyBooksArr =
                policyBookRegistry.list(0, policyBookRegistry.count());
            ///@dev we should update all coverage pools liquidity before leverage pool
            /// in order to do leverage rebalancing for all pools at once
            for (uint256 i = 0; i < _policyBooksArr.length; i++) {
                if (policyBookRegistry.isUserLeveragePool(_policyBooksArr[i])) continue;

                _updatePoolLiquidity(_policyBooksArr[i], 0, _lostPercentage, PoolType.COVERAGE);
            }

            address[] memory _userLeverageArr =
                policyBookRegistry.listByType(
                    IPolicyBookFabric.ContractType.VARIOUS,
                    0,
                    policyBookRegistry.countByType(IPolicyBookFabric.ContractType.VARIOUS)
                );

            for (uint256 i = 0; i < _userLeverageArr.length; i++) {
                _updatePoolLiquidity(_userLeverageArr[i], 0, _lostPercentage, PoolType.LEVERAGE);
            }
            yieldGenerator.defiHardRebalancing();
        }
    }

    /// @dev when calling this function we have to have either _lostAmount == 0 or _lostPercentage == 0
    function _updatePoolLiquidity(
        address _poolAddress,
        uint256 _lostAmount,
        uint256 _lostPercentage,
        PoolType poolType
    ) internal {
        IPolicyBook _pool = IPolicyBook(_poolAddress);

        if (_lostPercentage > 0) {
            uint256 _currentLiquidity = _pool.totalLiquidity();
            _lostAmount = _currentLiquidity.mul(_lostPercentage).div(PERCENTAGE_100);
        }
        _pool.updateLiquidity(_lostAmount);

        uint256 _stblLostAmount = DecimalsConverter.convertFrom18(_lostAmount, stblDecimals);

        if (poolType == PoolType.COVERAGE) {
            regularCoverageBalance[_poolAddress] = regularCoverageBalance[_poolAddress].sub(
                _stblLostAmount
            );
        } else if (poolType == PoolType.LEVERAGE) {
            leveragePoolBalance[_poolAddress] = leveragePoolBalance[_poolAddress].sub(
                _stblLostAmount
            );
        } else if (poolType == PoolType.REINSURANCE) {
            reinsurancePoolBalance = reinsurancePoolBalance.sub(_stblLostAmount);
        }

        if (_lostPercentage > 0) {
            virtualUsdtAccumulatedBalance = virtualUsdtAccumulatedBalance.sub(_stblLostAmount);
        }
    }

    /// @notice Fullfils policybook claims by transfering the balance to claimer
    /// @param _claimer, address of the claimer recieving the withdraw
    /// @param _stblClaimAmount uint256 amount to of the claim
    function fundClaim(
        address _claimer,
        uint256 _stblClaimAmount,
        address _policyBookAddress
    ) external override onlyClaimingRegistry returns (uint256 _actualAmount) {
        _actualAmount = _withdrawFromLiquidityCushion(_claimer, _stblClaimAmount);

        _dispatchLiquidities(
            _policyBookAddress,
            DecimalsConverter.convertTo18(_actualAmount, stblDecimals)
        );
    }

    function _dispatchLiquidities(address _policyBookAddress, uint256 _claimAmount) internal {
        IPolicyBook policyBook = IPolicyBook(_policyBookAddress);
        IPolicyBookFacade policyBookFacade = policyBook.policyBookFacade();

        uint256 totalCoveragedLiquidity = policyBook.totalLiquidity();
        uint256 totalLeveragedLiquidity = policyBookFacade.totalLeveragedLiquidity();
        uint256 totalPoolLiquidity = totalCoveragedLiquidity.add(totalLeveragedLiquidity);

        // COVERAGE CONTRIBUTION
        uint256 coverageContribution =
            totalCoveragedLiquidity.mul(PERCENTAGE_100).div(totalPoolLiquidity);
        uint256 coverageLoss = _claimAmount.mul(coverageContribution).div(PERCENTAGE_100);
        _updatePoolLiquidity(_policyBookAddress, coverageLoss, 0, PoolType.COVERAGE);

        // LEVERAGE CONTRIBUTION
        address[] memory _userLeverageArr =
            policyBookFacade.listUserLeveragePools(0, policyBookFacade.countUserLeveragePools());
        for (uint256 i = 0; i < _userLeverageArr.length; i++) {
            uint256 leverageContribution =
                policyBookFacade.LUuserLeveragePool(_userLeverageArr[i]).mul(PERCENTAGE_100).div(
                    totalPoolLiquidity
                );
            uint256 leverageLoss = _claimAmount.mul(leverageContribution).div(PERCENTAGE_100);
            _updatePoolLiquidity(_userLeverageArr[i], leverageLoss, 0, PoolType.LEVERAGE);
        }

        // REINSURANCE CONTRIBUTION
        uint256 reinsuranceContribution =
            (policyBookFacade.LUreinsurnacePool().add(policyBookFacade.VUreinsurnacePool()))
                .mul(PERCENTAGE_100)
                .div(totalPoolLiquidity);
        uint256 reinsuranceLoss = _claimAmount.mul(reinsuranceContribution).div(PERCENTAGE_100);
        _updatePoolLiquidity(address(reinsurancePool), reinsuranceLoss, 0, PoolType.REINSURANCE);
    }

    /// @notice Fullfils policybook claims by transfering the balance to claimer
    /// @param _voter, address of the voter recieving the withdraw
    /// @param _stblRewardAmount uint256 amount to of the reward
    function fundReward(address _voter, uint256 _stblRewardAmount)
        external
        override
        onlyClaimingRegistry
        returns (uint256 _actualAmount)
    {
        _actualAmount = _withdrawFromLiquidityCushion(_voter, _stblRewardAmount);

        _updatePoolLiquidity(
            address(reinsurancePool),
            DecimalsConverter.convertTo18(_actualAmount, stblDecimals),
            0,
            PoolType.REINSURANCE
        );
    }

    /// @notice Withdraws liquidity from a specific policbybook to the user
    /// @param _sender, address of the user beneficiary of the withdraw
    /// @param _stblAmount uint256 amount to be withdrawn
    function withdrawLiquidity(
        address _sender,
        uint256 _stblAmount,
        bool _isLeveragePool
    ) external override onlyPolicyBook broadcastBalancing returns (uint256 _actualAmount) {
        _actualAmount = _withdrawFromLiquidityCushion(_sender, _stblAmount);

        if (_isLeveragePool) {
            leveragePoolBalance[_msgSender()] = leveragePoolBalance[_msgSender()].sub(
                _actualAmount
            );
        } else {
            regularCoverageBalance[_msgSender()] = regularCoverageBalance[_msgSender()].sub(
                _actualAmount
            );
        }
    }

    function setMaintainer(address _newMainteiner) public onlyOwner {
        require(_newMainteiner != address(0), "CP: invalid maintainer address");
        maintainer = _newMainteiner;
    }

    function pauseLiquidityCushionRebalancing(bool _paused) public onlyOwner {
        require(_paused != isLiqCushionPaused, "CP: invalid paused state");

        isLiqCushionPaused = _paused;

        if (isLiqCushionPaused) {
            hardUsdtAccumulatedBalance = hardUsdtAccumulatedBalance.add(liquidityCushionBalance);
            liquidityCushionBalance = 0;
        }
    }

    function automateHardRebalancing(bool _isAutomatic) public onlyOwner {
        require(_isAutomatic != automaticHardRebalancing, "CP: invalid state");

        automaticHardRebalancing = _isAutomatic;
    }

    function allowDeployFundsToDefi(bool _deployFundsToDefi) public onlyOwner {
        require(_deployFundsToDefi != deployFundsToDefi, "CP: invalid input");

        //can not disabled deploy funds to defi in case there is deposited amount
        if (!_deployFundsToDefi) {
            require(yieldGenerator.totalDeposit() == 0, "CP: Can't disable deploy funds");
        }

        deployFundsToDefi = _deployFundsToDefi;

        // check isLiqCushionPaused isn't have the same state before update it
        if (isLiqCushionPaused != !deployFundsToDefi) {
            pauseLiquidityCushionRebalancing(!deployFundsToDefi);
        }
    }

    function _withdrawFromLiquidityCushion(address _sender, uint256 _stblAmount)
        internal
        broadcastBalancing
        returns (uint256 _actualAmount)
    {
        //withdraw from hardbalance if defi deployment is pasued
        if (!deployFundsToDefi) {
            require(hardUsdtAccumulatedBalance >= _stblAmount, "CP: insuficient liquidity");
            hardUsdtAccumulatedBalance = hardUsdtAccumulatedBalance.sub(_stblAmount);
            _actualAmount = _stblAmount;
        } else {
            //withdraw from liq cushion service if defi deployment is enabled
            require(!isLiqCushionPaused, "CP: withdraw is pasued");

            if (_stblAmount > liquidityCushionBalance) {
                uint256 _diffAmount = _stblAmount.sub(liquidityCushionBalance);
                if (hardUsdtAccumulatedBalance >= _diffAmount) {
                    hardUsdtAccumulatedBalance = hardUsdtAccumulatedBalance.sub(_diffAmount);
                    liquidityCushionBalance = liquidityCushionBalance.add(_diffAmount);
                } else if (hardUsdtAccumulatedBalance > 0) {
                    liquidityCushionBalance = liquidityCushionBalance.add(
                        hardUsdtAccumulatedBalance
                    );
                    hardUsdtAccumulatedBalance = 0;
                }
            }
            require(liquidityCushionBalance > 0, "CP: insuficient liquidity");

            _actualAmount = Math.min(_stblAmount, liquidityCushionBalance);

            liquidityCushionBalance = liquidityCushionBalance.sub(_actualAmount);
        }

        virtualUsdtAccumulatedBalance = virtualUsdtAccumulatedBalance.sub(_actualAmount);

        stblToken.safeTransfer(_sender, _actualAmount);
    }

    function _calcReinsurancePoolPremium(PremiumFactors memory factors)
        internal
        pure
        returns (uint256)
    {
        return (factors.premiumPerDeployment.mul(factors.vStblDeployedByRP).div(PRECISION));
    }

    function _calcUserLeveragePoolPremium(PremiumFactors memory factors) internal {
        address[] memory _userLeverageArr =
            factors.policyBookFacade.listUserLeveragePools(0, factors.userLeveragePoolsCount);

        uint256 premium;
        uint256 _participatedLeverageAmount;
        for (uint256 i = 0; i < _userLeverageArr.length; i++) {
            _participatedLeverageAmount = clacParticipatedLeverageAmount(
                factors,
                _userLeverageArr[i]
            );
            premium = (
                factors.premiumPerDeployment.mul(_participatedLeverageAmount).div(PRECISION)
            );

            leveragePoolBalance[_userLeverageArr[i]] = leveragePoolBalance[_userLeverageArr[i]]
                .add(premium);
            ILeveragePortfolio(_userLeverageArr[i]).addPolicyPremium(
                factors.epochsNumber,
                DecimalsConverter.convertTo18(premium, stblDecimals)
            );
        }
    }

    function clacParticipatedLeverageAmount(
        PremiumFactors memory factors,
        address userLeveragePool
    ) internal view returns (uint256) {
        return
            DecimalsConverter
                .convertFrom18(
                factors.policyBookFacade.LUuserLeveragePool(userLeveragePool),
                stblDecimals
            )
                .mul(leveragePortfolioView.calcM(factors.poolUtilizationRation, userLeveragePool))
                .div(PERCENTAGE_100);
    }

    function _calcCoveragePoolPremium(PremiumFactors memory factors)
        internal
        pure
        returns (uint256)
    {
        return factors.premiumPerDeployment.mul(factors.vStblOfCP).div(PRECISION);
    }

    function getDepositAndWithdraw(uint256 _requiredLiquidity)
        internal
        view
        returns (uint256 deposit, uint256 withdraw)
    {
        uint256 _availableBalance = hardUsdtAccumulatedBalance.add(liquidityCushionBalance);

        if (_requiredLiquidity > _availableBalance) {
            withdraw = _requiredLiquidity.sub(_availableBalance);
        } else if (_requiredLiquidity < _availableBalance) {
            deposit = _availableBalance.sub(_requiredLiquidity);
        }
    }

    function getWithdrawPeriod() external view override returns (uint256) {
        return rebalanceDuration + ADDITIONAL_WITHDRAW_PERIOD;
    }
}