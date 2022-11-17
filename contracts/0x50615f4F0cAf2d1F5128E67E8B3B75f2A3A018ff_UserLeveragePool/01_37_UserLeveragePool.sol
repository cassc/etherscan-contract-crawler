// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./tokens/erc20permit-upgradeable/ERC20PermitUpgradeable.sol";

import "./abstract/AbstractLeveragePortfolio.sol";
import "./interfaces/IBMICoverStaking.sol";
import "./interfaces/IBMICoverStakingView.sol";
import "./interfaces/IClaimingRegistry.sol";
import "./interfaces/IRewardsGenerator.sol";
import "./interfaces/ILiquidityRegistry.sol";
import "./interfaces/IUserLeveragePool.sol";
import "./interfaces/IShieldMining.sol";

contract UserLeveragePool is AbstractLeveragePortfolio, IUserLeveragePool, ERC20PermitUpgradeable {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;
    using Math for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant PREMIUM_DISTRIBUTION_EPOCH = 1 days;
    uint256 public constant MAX_PREMIUM_DISTRIBUTION_EPOCHS = 90;

    uint256 public constant override EPOCH_DURATION = 1 weeks;
    uint256 public constant MAXIMUM_EPOCHS = SECONDS_IN_THE_YEAR / EPOCH_DURATION;
    uint256 public constant VIRTUAL_EPOCHS = 1;

    uint256 public constant override READY_TO_WITHDRAW_PERIOD = 2 days;

    uint256 public override epochStartTime;
    uint256 public lastDistributionEpoch;

    uint256 public lastPremiumDistributionEpoch;
    int256 public lastPremiumDistributionAmount;

    IPolicyBookFabric.ContractType public override contractType;

    ERC20 public stblToken;
    IBMICoverStaking public bmiCoverStaking;
    IBMICoverStakingView public bmiCoverStakingView;
    IRewardsGenerator public rewardsGenerator;
    // ILiquidityMining public liquidityMining;
    ILiquidityRegistry public liquidityRegistry;
    IShieldMining public shieldMining;

    mapping(address => WithdrawalInfo) public override withdrawalsInfo;

    // mapping(address => uint256) public liquidityFromLM;
    mapping(uint256 => int256) public premiumDistributionDeltas;

    mapping(address => uint256) public override userLiquidity;

    uint256 public stblDecimals;
    uint256 public maxCapacities;
    bool public override whitelisted;

    // new state post v2
    uint256 public override a2_ProtocolConstant;
    IClaimingRegistry public claimingRegistry;

    event LiquidityAdded(
        address _liquidityHolder,
        uint256 _liquidityAmount,
        uint256 _newTotalLiquidity
    );
    event WithdrawalRequested(
        address _liquidityHolder,
        uint256 _tokensToWithdraw,
        uint256 _readyToWithdrawDate
    );

    modifier updateBMICoverStakingReward() {
        _;
        forceUpdateBMICoverStakingRewardMultiplier();
    }

    modifier withPremiumsDistribution() {
        _distributePremiums();
        _;
    }

    function __UserLeveragePool_init(
        IPolicyBookFabric.ContractType _contractType,
        string calldata _description,
        string calldata _projectSymbol
    ) external override initializer {
        __LeveragePortfolio_init();

        string memory fullSymbol = string(abi.encodePacked("bmiV2", _projectSymbol, "Cover"));
        __ERC20Permit_init(fullSymbol);
        __ERC20_init(_description, fullSymbol);
        contractType = _contractType;

        epochStartTime = block.timestamp;
        lastDistributionEpoch = 1;

        lastPremiumDistributionEpoch = _getPremiumDistributionEpoch();
        maxCapacities = 3500000 * DECIMALS18;
        a2_ProtocolConstant = 50 * PRECISION;
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        stblToken = ERC20(_contractsRegistry.getUSDTContract());
        bmiCoverStaking = IBMICoverStaking(_contractsRegistry.getBMICoverStakingContract());
        bmiCoverStakingView = IBMICoverStakingView(
            _contractsRegistry.getBMICoverStakingViewContract()
        );
        rewardsGenerator = IRewardsGenerator(_contractsRegistry.getRewardsGeneratorContract());
        policyBookAdmin = _contractsRegistry.getPolicyBookAdminContract();
        capitalPool = ICapitalPool(_contractsRegistry.getCapitalPoolContract());
        liquidityRegistry = ILiquidityRegistry(_contractsRegistry.getLiquidityRegistryContract());
        policyBookRegistry = IPolicyBookRegistry(
            _contractsRegistry.getPolicyBookRegistryContract()
        );
        leveragePortfolioView = ILeveragePortfolioView(
            _contractsRegistry.getLeveragePortfolioViewContract()
        );
        reinsurancePoolAddress = _contractsRegistry.getReinsurancePoolContract();
        stblDecimals = stblToken.decimals();
        shieldMining = IShieldMining(_contractsRegistry.getShieldMiningContract());
        claimingRegistry = IClaimingRegistry(_contractsRegistry.getClaimingRegistryContract());
    }

    function getEpoch(uint256 time) public view override returns (uint256) {
        return time.sub(epochStartTime).div(EPOCH_DURATION) + 1;
    }

    function _getPremiumDistributionEpoch() internal view returns (uint256) {
        return block.timestamp / PREMIUM_DISTRIBUTION_EPOCH;
    }

    function _getSTBLToBMIXRatio(uint256 currentLiquidity) internal view returns (uint256) {
        uint256 _currentTotalSupply = totalSupply();

        if (_currentTotalSupply == 0) {
            return PERCENTAGE_100;
        }

        return currentLiquidity.mul(PERCENTAGE_100).div(_currentTotalSupply);
    }

    function convertBMIXToSTBL(uint256 _amount) public view override returns (uint256) {
        (, uint256 currentLiquidity) = getNewCoverAndLiquidity();

        return _amount.mul(_getSTBLToBMIXRatio(currentLiquidity)).div(PERCENTAGE_100);
    }

    function convertSTBLToBMIX(uint256 _amount) public view override returns (uint256) {
        (, uint256 currentLiquidity) = getNewCoverAndLiquidity();

        return _amount.mul(PERCENTAGE_100).div(_getSTBLToBMIXRatio(currentLiquidity));
    }

    function _getPremiumsDistribution(uint256 lastEpoch, uint256 currentEpoch)
        internal
        view
        returns (
            int256 currentDistribution,
            uint256 distributionEpoch,
            uint256 newTotalLiquidity
        )
    {
        currentDistribution = lastPremiumDistributionAmount;
        newTotalLiquidity = totalLiquidity;
        distributionEpoch = Math.min(
            currentEpoch,
            lastEpoch + MAX_PREMIUM_DISTRIBUTION_EPOCHS + 1
        );

        for (uint256 i = lastEpoch + 1; i <= distributionEpoch; i++) {
            currentDistribution += premiumDistributionDeltas[i];
            newTotalLiquidity = newTotalLiquidity.add(uint256(currentDistribution));
        }
    }

    function _distributePremiums() internal {
        uint256 lastEpoch = lastPremiumDistributionEpoch;
        uint256 currentEpoch = _getPremiumDistributionEpoch();

        if (currentEpoch > lastEpoch) {
            (
                lastPremiumDistributionAmount,
                lastPremiumDistributionEpoch,
                totalLiquidity
            ) = _getPremiumsDistribution(lastEpoch, currentEpoch);
        }
    }

    function whitelist(bool _whitelisted)
        external
        override
        onlyPolicyBookAdmin
        updateBMICoverStakingReward
    {
        whitelisted = _whitelisted;
    }

    /// @notice set max total liquidity for the pool
    /// @param _maxCapacities uint256 the max total liquidity
    function setMaxCapacities(uint256 _maxCapacities) external override onlyPolicyBookAdmin {
        require(_maxCapacities > 0, "LP: max capacities can't be zero");
        maxCapacities = _maxCapacities;
    }

    function setA2_ProtocolConstant(uint256 _a2_ProtocolConstant)
        external
        override
        onlyPolicyBookAdmin
    {
        a2_ProtocolConstant = _a2_ProtocolConstant;
    }

    function forceUpdateBMICoverStakingRewardMultiplier() public override {
        uint256 _totalBmiMultiplier;
        uint256 _poolMultiplier;
        uint256 _leverageProvided;
        uint256 _poolUR;
        address policyBookAddress;
        for (uint256 i = 0; i < leveragedCoveragePools.length(); i++) {
            policyBookAddress = leveragedCoveragePools.at(i);
            IPolicyBook _coveragepool = IPolicyBook(policyBookAddress);

            _poolMultiplier = rewardsGenerator.getPolicyBookRewardMultiplier(policyBookAddress);

            _leverageProvided = poolsLDeployedAmount[policyBookAddress].mul(PRECISION).div(
                totalLiquidity
            );

            _poolUR = _coveragepool.totalCoverTokens().mul(PERCENTAGE_100).div(
                _coveragepool.totalLiquidity()
            );

            _totalBmiMultiplier = _totalBmiMultiplier.add(
                leveragePortfolioView.calcBMIMultiplier(
                    BMIMultiplierFactors(
                        _poolMultiplier,
                        _leverageProvided,
                        leveragePortfolioView.calcM(_poolUR, address(this))
                    )
                )
            );
        }

        rewardsGenerator.updatePolicyBookShare(_totalBmiMultiplier.div(10**22), address(this)); // 5 decimal places or zero
    }

    function getNewCoverAndLiquidity()
        public
        view
        override
        returns (uint256 newTotalCoverTokens, uint256 newTotalLiquidity)
    {
        newTotalLiquidity = totalLiquidity;

        uint256 lastEpoch = lastPremiumDistributionEpoch;
        uint256 currentEpoch = _getPremiumDistributionEpoch();

        if (currentEpoch > lastEpoch) {
            (, , newTotalLiquidity) = _getPremiumsDistribution(lastEpoch, currentEpoch);
        }
    }

    /// @notice add the portion of 80% of premium to user leverage pool where the leverage provide lstable : access policybook
    /// @param epochsNumber uint256 the number of epochs which the policy holder will pay a premium for
    /// @param  premiumAmount uint256 the premium amount which is a portion of 80% of the premium
    function addPolicyPremium(uint256 epochsNumber, uint256 premiumAmount)
        external
        override
        withPremiumsDistribution
        updateBMICoverStakingReward
        onlyCapitalPool
    {
        updateEpochsInfo();

        uint256 _totalSeconds =
            secondsToEndCurrentEpoch().add(epochsNumber.sub(1).mul(EPOCH_DURATION));

        _addPolicyPremiumToDistributions(
            _totalSeconds.add(VIRTUAL_EPOCHS * EPOCH_DURATION),
            premiumAmount
        );

        emit PremiumAdded(premiumAmount);
    }

    /// @dev no need to cap epochs because the maximum policy duration is 1 year
    function _addPolicyPremiumToDistributions(uint256 _totalSeconds, uint256 _distributedAmount)
        internal
    {
        uint256 distributionEpochs = _totalSeconds.add(1).div(PREMIUM_DISTRIBUTION_EPOCH).max(1);

        int256 distributedPerEpoch = int256(_distributedAmount.div(distributionEpochs));
        uint256 nextEpoch = _getPremiumDistributionEpoch() + 1;

        premiumDistributionDeltas[nextEpoch] += distributedPerEpoch;
        premiumDistributionDeltas[nextEpoch + distributionEpochs] -= distributedPerEpoch;
    }

    function updateEpochsInfo() public override {
        uint256 _lastDistributionEpoch = lastDistributionEpoch;
        uint256 _newDistributionEpoch =
            Math.min(getEpoch(block.timestamp), _lastDistributionEpoch + MAXIMUM_EPOCHS);

        if (_lastDistributionEpoch < _newDistributionEpoch) {
            lastDistributionEpoch = _newDistributionEpoch;
        }
    }

    function secondsToEndCurrentEpoch() public view override returns (uint256) {
        uint256 epochNumber = block.timestamp.sub(epochStartTime).div(EPOCH_DURATION) + 1;

        return epochNumber.mul(EPOCH_DURATION).sub(block.timestamp.sub(epochStartTime));
    }

    function addLiquidity(uint256 _liquidityAmount) external override {
        _addLiquidity(_msgSender(), _liquidityAmount);
    }

    // function addLiquidityFor(address _liquidityHolderAddr, uint256 _liquidityAmount)
    //     external
    //     override
    //     onlyLiquidityAdders
    // {
    //     _addLiquidity(_liquidityHolderAddr, _liquidityAmount);
    // }

    function addLiquidityAndStake(uint256 _liquidityAmount, uint256 _stakeSTBLAmount)
        external
        override
    {
        require(_stakeSTBLAmount <= _liquidityAmount, "LP: Wrong staking amount");

        _addLiquidity(_msgSender(), _liquidityAmount);
        bmiCoverStaking.stakeBMIXFrom(_msgSender(), convertSTBLToBMIX(_stakeSTBLAmount));
    }

    function _addLiquidity(address _liquidityHolderAddr, uint256 _liquidityAmount)
        internal
        withPremiumsDistribution
        updateBMICoverStakingReward
    {
        require(
            totalLiquidity.add(_liquidityAmount) <= maxCapacities,
            "LP: amount exceed the max capacities"
        );

        uint256 stblLiquidity = DecimalsConverter.convertFrom18(_liquidityAmount, stblDecimals);
        require(stblLiquidity > 0, "LP: Liquidity amount is zero");

        updateEpochsInfo();

        stblToken.safeTransferFrom(_liquidityHolderAddr, address(capitalPool), stblLiquidity);

        capitalPool.addLeverageProvidersHardSTBL(stblLiquidity);

        uint256 _liquidityAmountBMIX = convertSTBLToBMIX(_liquidityAmount);

        _mint(_liquidityHolderAddr, _liquidityAmountBMIX);
        uint256 liquidity = totalLiquidity.add(_liquidityAmount);
        totalLiquidity = liquidity;

        liquidityRegistry.tryToAddPolicyBook(_liquidityHolderAddr, address(this));

        _reevaluateProvidedLeverageStable(LeveragePortfolio.USERLEVERAGEPOOL, _liquidityAmount);
        _updateShieldMining(_liquidityHolderAddr, _liquidityAmountBMIX, false);

        emit LiquidityAdded(_liquidityHolderAddr, _liquidityAmount, liquidity);
    }

    function _updateShieldMining(
        address liquidityProvider,
        uint256 liquidityAmount,
        bool isWithdraw
    ) internal {
        address policyBookAddress;

        for (uint256 i = 0; i < leveragedCoveragePools.length(); i++) {
            policyBookAddress = leveragedCoveragePools.at(i);

            if (shieldMining.getShieldTokenAddress(policyBookAddress) != address(0)) {
                shieldMining.updateTotalSupply(
                    policyBookAddress,
                    address(this),
                    liquidityProvider
                );
            }
        }

        if (liquidityProvider != address(0)) {
            if (isWithdraw) {
                userLiquidity[liquidityProvider] = userLiquidity[liquidityProvider].sub(
                    liquidityAmount
                );
            } else {
                userLiquidity[liquidityProvider] = userLiquidity[liquidityProvider].add(
                    liquidityAmount
                );
            }
        }
    }

    function getAvailableBMIXWithdrawableAmount(address _userAddr)
        external
        view
        override
        returns (uint256)
    {
        (, uint256 newTotalLiquidity) = getNewCoverAndLiquidity();

        return convertSTBLToBMIX(Math.min(newTotalLiquidity, _getUserAvailableSTBL(_userAddr)));
    }

    function _getUserAvailableSTBL(address _userAddr) internal view returns (uint256) {
        uint256 availableSTBL =
            convertBMIXToSTBL(
                balanceOf(_userAddr).add(withdrawalsInfo[_userAddr].withdrawalAmount)
            );

        return availableSTBL;
    }

    function getWithdrawalStatus(address _userAddr)
        public
        view
        override
        returns (WithdrawalStatus)
    {
        uint256 readyToWithdrawDate = withdrawalsInfo[_userAddr].readyToWithdrawDate;

        if (readyToWithdrawDate == 0) {
            return WithdrawalStatus.NONE;
        }

        if (block.timestamp < readyToWithdrawDate) {
            return WithdrawalStatus.PENDING;
        }

        if (
            block.timestamp >= readyToWithdrawDate.add(READY_TO_WITHDRAW_PERIOD) &&
            !withdrawalsInfo[_userAddr].withdrawalAllowed
        ) {
            return WithdrawalStatus.EXPIRED;
        }

        return WithdrawalStatus.READY;
    }

    // function requestWithdrawalWithPermit(
    //     uint256 _tokensToWithdraw,
    //     uint8 _v,
    //     bytes32 _r,
    //     bytes32 _s
    // ) external override {
    //     permit(_msgSender(), address(this), _tokensToWithdraw, MAX_INT, _v, _r, _s);

    //     requestWithdrawal(_tokensToWithdraw);
    // }

    function requestWithdrawal(uint256 _tokensToWithdraw)
        public
        override
        withPremiumsDistribution
    {
        require(_tokensToWithdraw > 0, "LP: Amount is zero");

        WithdrawalStatus _withdrawlStatus = getWithdrawalStatus(msg.sender);

        require(
            _withdrawlStatus == WithdrawalStatus.NONE ||
                _withdrawlStatus == WithdrawalStatus.EXPIRED,
            "LP: ongoing withdrawl request"
        );

        require(
            !claimingRegistry.hasProcedureOngoing(address(this)),
            "LP: ongoing claim procedure"
        );

        uint256 _stblTokensToWithdraw = convertBMIXToSTBL(_tokensToWithdraw);
        uint256 _availableSTBLBalance = _getUserAvailableSTBL(_msgSender());

        require(_availableSTBLBalance >= _stblTokensToWithdraw, "LP: Wrong announced amount");

        updateEpochsInfo();

        _lockTokens(_msgSender(), _tokensToWithdraw);

        liquidityRegistry.registerWithdrawl(address(this), _msgSender());

        _requestWithdrawal(_tokensToWithdraw, _msgSender());
    }

    function _requestWithdrawal(uint256 _tokensToWithdraw, address _user) internal {
        uint256 _readyToWithdrawDate = block.timestamp.add(capitalPool.getWithdrawPeriod());

        withdrawalsInfo[_user] = WithdrawalInfo(_tokensToWithdraw, _readyToWithdrawDate, false);

        emit WithdrawalRequested(_user, _tokensToWithdraw, _readyToWithdrawDate);
    }

    function _lockTokens(address _userAddr, uint256 _neededTokensToLock) internal {
        uint256 _currentLockedTokens = withdrawalsInfo[_userAddr].withdrawalAmount;

        if (_currentLockedTokens > _neededTokensToLock) {
            this.transfer(_userAddr, _currentLockedTokens - _neededTokensToLock);
        } else if (_currentLockedTokens < _neededTokensToLock) {
            this.transferFrom(
                _userAddr,
                address(this),
                _neededTokensToLock - _currentLockedTokens
            );
        }
    }

    function unlockTokens() external override {
        uint256 _lockedAmount = withdrawalsInfo[_msgSender()].withdrawalAmount;

        require(_lockedAmount > 0, "LP: Amount is zero");

        this.transfer(_msgSender(), _lockedAmount);
        delete withdrawalsInfo[_msgSender()];
        liquidityRegistry.removeExpiredWithdrawalRequest(_msgSender(), address(this));
    }

    function withdrawLiquidity()
        external
        override
        withPremiumsDistribution
        updateBMICoverStakingReward
    {
        require(
            getWithdrawalStatus(_msgSender()) == WithdrawalStatus.READY,
            "LP: Withdrawal is not ready"
        );

        updateEpochsInfo();

        uint256 liquidity = totalLiquidity;
        uint256 _currentWithdrawalAmount = withdrawalsInfo[_msgSender()].withdrawalAmount;
        uint256 _tokensToWithdraw =
            Math.min(_currentWithdrawalAmount, convertSTBLToBMIX(liquidity));

        uint256 _stblTokensToWithdraw = convertBMIXToSTBL(_tokensToWithdraw);

        uint256 _stblTokensToWithdrawConverted =
            DecimalsConverter.convertFrom18(_stblTokensToWithdraw, stblDecimals);

        uint256 _actualStblTokensToWithdraw =
            capitalPool.withdrawLiquidity(_msgSender(), _stblTokensToWithdrawConverted, true);

        if (_stblTokensToWithdrawConverted != _actualStblTokensToWithdraw) {
            _actualStblTokensToWithdraw = DecimalsConverter.convertTo18(
                _actualStblTokensToWithdraw,
                stblDecimals
            );
            _tokensToWithdraw = convertSTBLToBMIX(_actualStblTokensToWithdraw);
            _stblTokensToWithdraw = _actualStblTokensToWithdraw;
        }

        _burn(address(this), _tokensToWithdraw);
        liquidity = liquidity.sub(_stblTokensToWithdraw);

        _currentWithdrawalAmount = _currentWithdrawalAmount.sub(_tokensToWithdraw);

        if (_currentWithdrawalAmount == 0) {
            delete withdrawalsInfo[_msgSender()];
            liquidityRegistry.tryToRemovePolicyBook(_msgSender(), address(this));
        } else {
            _requestWithdrawal(_currentWithdrawalAmount, _msgSender());
        }

        totalLiquidity = liquidity;

        _reevaluateProvidedLeverageStable(
            LeveragePortfolio.USERLEVERAGEPOOL,
            _stblTokensToWithdraw
        );
        _updateShieldMining(_msgSender(), _tokensToWithdraw, true);

        emit LiquidityWithdrawn(_msgSender(), _stblTokensToWithdraw, liquidity);
    }

    function updateLiquidity(uint256 _lostLiquidity) external override onlyCapitalPool {
        updateEpochsInfo();

        uint256 _newLiquidity = totalLiquidity.sub(_lostLiquidity);
        totalLiquidity = _newLiquidity;

        _reevaluateProvidedLeverageStable(LeveragePortfolio.USERLEVERAGEPOOL, _lostLiquidity);
        _updateShieldMining(address(0), _lostLiquidity, true);

        emit LiquidityWithdrawn(_msgSender(), _lostLiquidity, _newLiquidity);
    }

    /// @notice returns APY% with 10**5 precision
    function getAPY() public view override returns (uint256) {
        uint256 lastEpoch = lastPremiumDistributionEpoch;
        uint256 currentEpoch = _getPremiumDistributionEpoch();
        int256 premiumDistributionAmount = lastPremiumDistributionAmount;

        // simulates addLiquidity()
        if (currentEpoch > lastEpoch) {
            (premiumDistributionAmount, currentEpoch, ) = _getPremiumsDistribution(
                lastEpoch,
                currentEpoch
            );
        }

        premiumDistributionAmount += premiumDistributionDeltas[currentEpoch + 1];

        return
            uint256(premiumDistributionAmount).mul(365).mul(10**7).div(
                convertBMIXToSTBL(totalSupply()).add(APY_TOKENS)
            );
    }

    /// @notice Getting number stats, access: ANY
    /// @return _maxCapacities is a max liquidity of the pool
    /// @return _buyPolicyCapacity is becuase to follow the same function in policy book
    /// @return _totalSTBLLiquidity is PolicyBook's liquidity
    /// @return _totalLeveragedLiquidity is becuase to follow the same function in policy book
    /// @return _stakedSTBL is how much stable coin are staked on this PolicyBook
    /// @return _annualProfitYields is its APY
    /// @return _annualInsuranceCost is becuase to follow the same function in policy book
    /// @return  _bmiXRatio is multiplied by 10**18. To get STBL representation
    function numberStats()
        external
        view
        override
        returns (
            uint256 _maxCapacities,
            uint256 _buyPolicyCapacity,
            uint256 _totalSTBLLiquidity,
            uint256 _totalLeveragedLiquidity,
            uint256 _stakedSTBL,
            uint256 _annualProfitYields,
            uint256 _annualInsuranceCost,
            uint256 _bmiXRatio
        )
    {
        (, _totalSTBLLiquidity) = getNewCoverAndLiquidity();
        _maxCapacities = maxCapacities;
        _stakedSTBL = rewardsGenerator.getStakedPolicyBookSTBL(address(this));
        _annualProfitYields = getAPY();
        _bmiXRatio = convertBMIXToSTBL(10**18);
    }

    /// @notice Getting info, access: ANY
    /// @return _symbol is the symbol of PolicyBook (bmiXCover)
    /// @return _insuredContract is an addres of insured contract
    /// @return _contractType is becuase to follow the same function in policy book
    /// @return _whitelisted is a state of whitelisting
    function info()
        external
        view
        override
        returns (
            string memory _symbol,
            address _insuredContract,
            IPolicyBookFabric.ContractType _contractType,
            bool _whitelisted
        )
    {
        return (symbol(), address(0), contractType, whitelisted);
    }
}