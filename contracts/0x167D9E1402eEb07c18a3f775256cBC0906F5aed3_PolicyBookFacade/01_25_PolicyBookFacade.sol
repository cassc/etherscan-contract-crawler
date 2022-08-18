// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/Math.sol";

import "./libraries/DecimalsConverter.sol";

import "./interfaces/IContractsRegistry.sol";
import "./interfaces/IShieldMining.sol";
import "./interfaces/ILiquidityRegistry.sol";
import "./interfaces/IPolicyBookAdmin.sol";
import "./interfaces/IPolicyBookFacade.sol";
import "./interfaces/helpers/IPriceFeed.sol";

import "./interfaces/IPolicyBookRegistry.sol";
import "./interfaces/IRewardsGenerator.sol";
import "./interfaces/IPolicyQuote.sol";
import "./interfaces/IClaimingRegistry.sol";

import "./abstract/AbstractDependant.sol";

import "./Globals.sol";

contract PolicyBookFacade is IPolicyBookFacade, AbstractDependant, Initializable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Math for uint256;
    using SafeMath for uint256;

    uint256 public constant MINUMUM_COVERAGE = 100 * DECIMALS18; // 100 STBL

    uint256 public constant EPOCH_DURATION = 1 weeks;
    uint256 public constant MAXIMUM_EPOCHS = SECONDS_IN_THE_YEAR / EPOCH_DURATION;

    uint256 public constant RISKY_UTILIZATION_RATIO = 80 * PRECISION;
    uint256 public constant MODERATE_UTILIZATION_RATIO = 50 * PRECISION;

    uint256 public constant MINIMUM_REWARD = 15 * PRECISION; // 0.15
    uint256 public constant MAXIMUM_REWARD = 2 * PERCENTAGE_100; // 2.0
    uint256 public constant BASE_REWARD = PERCENTAGE_100; // 1.0

    uint256 private constant MAX_LEVERAGE_POOLS = 3;

    IPolicyBookAdmin public policyBookAdmin;
    ILeveragePortfolio public reinsurancePool;
    IPolicyBook public override policyBook;
    IShieldMining public shieldMining;
    IPolicyBookRegistry public policyBookRegistry;

    ILiquidityRegistry public liquidityRegistry;

    address public capitalPoolAddress;
    address public priceFeed;

    // virtual funds deployed by reinsurance pool
    uint256 public override VUreinsurnacePool;
    // leverage funds deployed by reinsurance pool
    uint256 public override LUreinsurnacePool;
    // leverage funds deployed by user leverage pool
    mapping(address => uint256) public override LUuserLeveragePool;
    // total leverage funds deployed to the pool sum of (VUreinsurnacePool,LUreinsurnacePool,LUuserLeveragePool)
    uint256 public override totalLeveragedLiquidity;

    uint256 public override userleveragedMPL;
    uint256 public override reinsurancePoolMPL;

    uint256 public override rebalancingThreshold;

    bool public override safePricingModel;

    mapping(address => uint256) public override userLiquidity;

    EnumerableSet.AddressSet internal userLeveragePools;

    IRewardsGenerator public rewardsGenerator;

    IPolicyQuote public policyQuote;

    IClaimingRegistry public claimingRegistry;

    event DeployLeverageFunds(uint256 _deployedAmount);

    modifier onlyCapitalPool() {
        require(msg.sender == capitalPoolAddress, "PBFC: only CapitalPool");
        _;
    }

    modifier onlyPolicyBookAdmin() {
        require(msg.sender == address(policyBookAdmin), "PBFC: Not a PBA");
        _;
    }

    modifier onlyLeveragePortfolio() {
        require(
            msg.sender == address(reinsurancePool) ||
                policyBookRegistry.isUserLeveragePool(msg.sender),
            "PBFC: only LeveragePortfolio"
        );
        _;
    }

    modifier onlyPolicyBookRegistry() {
        require(msg.sender == address(policyBookRegistry), "PBFC: Not a policy book registry");
        _;
    }

    modifier onlyPolicyBook() {
        require(msg.sender == address(policyBook), "PBFC: Not a policy book");
        _;
    }

    function __PolicyBookFacade_init(
        address pbProxy,
        address liquidityProvider,
        uint256 _initialDeposit
    ) external override initializer {
        policyBook = IPolicyBook(pbProxy);
        rebalancingThreshold = DEFAULT_REBALANCING_THRESHOLD;
        userLiquidity[liquidityProvider] = _initialDeposit;
    }

    function setDependencies(IContractsRegistry contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        IContractsRegistry _contractsRegistry = IContractsRegistry(contractsRegistry);

        capitalPoolAddress = _contractsRegistry.getCapitalPoolContract();
        policyBookRegistry = IPolicyBookRegistry(
            _contractsRegistry.getPolicyBookRegistryContract()
        );
        liquidityRegistry = ILiquidityRegistry(_contractsRegistry.getLiquidityRegistryContract());
        policyBookAdmin = IPolicyBookAdmin(_contractsRegistry.getPolicyBookAdminContract());
        priceFeed = _contractsRegistry.getPriceFeedContract();
        reinsurancePool = ILeveragePortfolio(_contractsRegistry.getReinsurancePoolContract());
        policyQuote = IPolicyQuote(_contractsRegistry.getPolicyQuoteContract());
        shieldMining = IShieldMining(_contractsRegistry.getShieldMiningContract());
        rewardsGenerator = IRewardsGenerator(_contractsRegistry.getRewardsGeneratorContract());
        claimingRegistry = IClaimingRegistry(_contractsRegistry.getClaimingRegistryContract());
    }

    /// @notice Let user to buy policy by supplying stable coin, access: ANY
    /// @param _epochsNumber is number of seconds to cover
    /// @param _coverTokens is number of tokens to cover
    function buyPolicy(uint256 _epochsNumber, uint256 _coverTokens) external override {
        _buyPolicy(msg.sender, msg.sender, _epochsNumber, _coverTokens, 0, address(0));
    }

    function buyPolicyFor(
        address _holder,
        uint256 _epochsNumber,
        uint256 _coverTokens
    ) external override {
        _buyPolicy(msg.sender, _holder, _epochsNumber, _coverTokens, 0, address(0));
    }

    function buyPolicyFromDistributor(
        uint256 _epochsNumber,
        uint256 _coverTokens,
        address _distributor
    ) external override {
        uint256 _distributorFee = policyBookAdmin.distributorFees(_distributor);
        _buyPolicy(
            msg.sender,
            msg.sender,
            _epochsNumber,
            _coverTokens,
            _distributorFee,
            _distributor
        );
    }

    /// @notice Let user to buy policy by supplying stable coin, access: ANY
    /// @param _holder address user the policy is being "bought for"
    /// @param _epochsNumber is number of seconds to cover
    /// @param _coverTokens is number of tokens to cover
    function buyPolicyFromDistributorFor(
        address _holder,
        uint256 _epochsNumber,
        uint256 _coverTokens,
        address _distributor
    ) external override {
        uint256 _distributorFee = policyBookAdmin.distributorFees(_distributor);
        _buyPolicy(
            msg.sender,
            _holder,
            _epochsNumber,
            _coverTokens,
            _distributorFee,
            _distributor
        );
    }

    /// @notice Let user to add liquidity by supplying stable coin, access: ANY
    /// @param _liquidityAmount is amount of stable coin tokens to secure
    function addLiquidity(uint256 _liquidityAmount) external override {
        _addLiquidity(msg.sender, msg.sender, _liquidityAmount, 0);
    }

    function addLiquidityFromDistributorFor(address _liquidityHolderAddr, uint256 _liquidityAmount)
        external
        override
    {
        _addLiquidity(msg.sender, _liquidityHolderAddr, _liquidityAmount, 0);
    }

    /// @dev access: ANY
    function addLiquidityAndStakeFor(
        address _liquidityHolderAddr,
        uint256 _liquidityAmount,
        uint256 _stakeSTBLAmount
    ) external override {
        _addLiquidity(msg.sender, _liquidityHolderAddr, _liquidityAmount, _stakeSTBLAmount);
    }

    /// @notice Let user to add liquidity by supplying stable coin and stake it,
    /// @dev access: ANY
    function addLiquidityAndStake(uint256 _liquidityAmount, uint256 _stakeSTBLAmount)
        external
        override
    {
        _addLiquidity(msg.sender, msg.sender, _liquidityAmount, _stakeSTBLAmount);
    }

    function _addLiquidity(
        address _liquidityBuyerAddr,
        address _liquidityHolderAddr,
        uint256 _liquidityAmount,
        uint256 _stakeSTBLAmount
    ) internal {
        uint256 _tokensToAdd =
            policyBook.addLiquidity(
                _liquidityBuyerAddr,
                _liquidityHolderAddr,
                _liquidityAmount,
                _stakeSTBLAmount
            );

        _reevaluateProvidedLeverageStable(_liquidityAmount);
        _updateShieldMining(_liquidityHolderAddr, _tokensToAdd, false);
    }

    function _buyPolicy(
        address _policyBuyerAddr,
        address _policyHolderAddr,
        uint256 _epochsNumber,
        uint256 _coverTokens,
        uint256 _distributorFee,
        address _distributor
    ) internal {
        policyBook.buyPolicy(
            _policyBuyerAddr,
            _policyHolderAddr,
            _epochsNumber,
            _coverTokens,
            _distributorFee,
            _distributor
        );

        _deployLeveragedFunds();
    }

    function _reevaluateProvidedLeverageStable(uint256 newAmount) internal {
        uint256 _newAmountPercentage;
        uint256 _totalLiq = policyBook.totalLiquidity();

        if (_totalLiq > 0) {
            _newAmountPercentage = newAmount.mul(PERCENTAGE_100).div(_totalLiq);
        }
        if ((_totalLiq > 0 && _newAmountPercentage > rebalancingThreshold) || _totalLiq == 0) {
            _deployLeveragedFunds();
        }
    }

    ///@dev in case ur changed of the pools by commit a claim or policy expired
    function reevaluateProvidedLeverageStable() external override onlyPolicyBook {
        _deployLeveragedFunds();
    }

    /// @notice deploy leverage funds (RP lStable, ULP lStable)
    /// @param  deployedAmount uint256 the deployed amount to be added or substracted from the total liquidity
    /// @param leveragePool whether user leverage or reinsurance leverage
    function deployLeverageFundsAfterRebalance(
        uint256 deployedAmount,
        ILeveragePortfolio.LeveragePortfolio leveragePool
    ) external override onlyLeveragePortfolio {
        if (leveragePool == ILeveragePortfolio.LeveragePortfolio.USERLEVERAGEPOOL) {
            LUuserLeveragePool[msg.sender] = deployedAmount;
            if (LUuserLeveragePool[msg.sender] == 0) {
                userLeveragePools.remove(msg.sender);
            }
        } else {
            LUreinsurnacePool = deployedAmount;
        }
        uint256 _LUuserLeveragePool;
        for (uint256 i = 0; i < userLeveragePools.length(); i++) {
            _LUuserLeveragePool = _LUuserLeveragePool.add(
                LUuserLeveragePool[userLeveragePools.at(i)]
            );
        }
        totalLeveragedLiquidity = VUreinsurnacePool.add(LUreinsurnacePool).add(
            _LUuserLeveragePool
        );
        emit DeployLeverageFunds(deployedAmount);
    }

    /// @notice deploy virtual funds (RP vStable)
    /// @param  deployedAmount uint256 the deployed amount to be added to the liquidity
    function deployVirtualFundsAfterRebalance(uint256 deployedAmount)
        external
        override
        onlyLeveragePortfolio
    {
        VUreinsurnacePool = deployedAmount;
        uint256 _LUuserLeveragePool;
        for (uint256 i = 0; i < userLeveragePools.length(); i++) {
            _LUuserLeveragePool = _LUuserLeveragePool.add(
                LUuserLeveragePool[userLeveragePools.at(i)]
            );
        }
        totalLeveragedLiquidity = VUreinsurnacePool.add(LUreinsurnacePool).add(
            _LUuserLeveragePool
        );
        emit DeployLeverageFunds(deployedAmount);
    }

    function _deployLeveragedFunds() internal {
        uint256 _deployedAmount;

        uint256 _LUuserLeveragePool;

        _deployedAmount = reinsurancePool.deployVirtualStableToCoveragePools();
        VUreinsurnacePool = _deployedAmount;

        _deployedAmount = reinsurancePool.deployLeverageStableToCoveragePools(
            ILeveragePortfolio.LeveragePortfolio.REINSURANCEPOOL
        );
        LUreinsurnacePool = _deployedAmount;

        address[] memory _userLeverageArr =
            policyBookRegistry.listByType(
                IPolicyBookFabric.ContractType.VARIOUS,
                0,
                policyBookRegistry.countByType(IPolicyBookFabric.ContractType.VARIOUS)
            );
        for (uint256 i = 0; i < _userLeverageArr.length; i++) {
            if (isExceedMaxLeveragePools(_userLeverageArr[i])) {
                continue;
            }
            _deployedAmount = ILeveragePortfolio(_userLeverageArr[i])
                .deployLeverageStableToCoveragePools(
                ILeveragePortfolio.LeveragePortfolio.USERLEVERAGEPOOL
            );
            // update user leverage pool apy after rebalancing
            ILeveragePortfolio(_userLeverageArr[i]).forceUpdateBMICoverStakingRewardMultiplier();

            if (_deployedAmount > 0) {
                userLeveragePools.add(_userLeverageArr[i]);
            } else {
                userLeveragePools.remove(_userLeverageArr[i]);
            }
            LUuserLeveragePool[_userLeverageArr[i]] = _deployedAmount;
            _LUuserLeveragePool = _LUuserLeveragePool.add(_deployedAmount);
        }

        totalLeveragedLiquidity = VUreinsurnacePool.add(LUreinsurnacePool).add(
            _LUuserLeveragePool
        );
    }

    function isExceedMaxLeveragePools(address _userLeverageAdd)
        internal
        view
        returns (bool _isExceed)
    {
        if (
            !userLeveragePools.contains(_userLeverageAdd) &&
            userLeveragePools.length() >= MAX_LEVERAGE_POOLS
        ) {
            _isExceed = true;
        }
    }

    function _updateShieldMining(
        address liquidityProvider,
        uint256 liquidityAmount,
        bool isWithdraw
    ) internal {
        // check if SM active
        if (shieldMining.getShieldTokenAddress(address(policyBook)) != address(0)) {
            shieldMining.updateTotalSupply(address(policyBook), address(0), liquidityProvider);
        }

        if (isWithdraw) {
            if (userLiquidity[liquidityProvider] >= liquidityAmount) {
                userLiquidity[liquidityProvider] = userLiquidity[liquidityProvider].sub(
                    liquidityAmount
                );
            } else {
                userLiquidity[liquidityProvider] = 0;
            }
        } else {
            userLiquidity[liquidityProvider] = userLiquidity[liquidityProvider].add(
                liquidityAmount
            );
        }
    }

    /// @notice Let user to withdraw deposited liqiudity, access: ANY
    function withdrawLiquidity() external override {
        (uint256 _tokensToWithdraw, uint256 _stblTokensToWithdraw) =
            policyBook.withdrawLiquidity(msg.sender);
        _reevaluateProvidedLeverageStable(_stblTokensToWithdraw);
        _updateShieldMining(msg.sender, _tokensToWithdraw, true);
    }

    /// @notice set the MPL for the user leverage and the reinsurance leverage
    /// @param _userLeverageMPL uint256 value of the user leverage MPL
    /// @param _reinsuranceLeverageMPL uint256  value of the reinsurance leverage MPL
    function setMPLs(uint256 _userLeverageMPL, uint256 _reinsuranceLeverageMPL)
        external
        override
        onlyPolicyBookAdmin
    {
        userleveragedMPL = _userLeverageMPL;
        reinsurancePoolMPL = _reinsuranceLeverageMPL;
    }

    /// @notice sets the rebalancing threshold value
    /// @param _newRebalancingThreshold uint256 rebalancing threshhold value
    function setRebalancingThreshold(uint256 _newRebalancingThreshold)
        external
        override
        onlyPolicyBookAdmin
    {
        require(_newRebalancingThreshold > 0, "PBF: threshold can not be 0");
        rebalancingThreshold = _newRebalancingThreshold;
    }

    /// @notice sets the rebalancing threshold value
    /// @param _safePricingModel bool is pricing model safe (true) or not (false)
    function setSafePricingModel(bool _safePricingModel) external override onlyPolicyBookAdmin {
        safePricingModel = _safePricingModel;
    }

    // TODO possible sandwich attack or allowance fluctuation
    function getClaimApprovalAmount(address user) external view override returns (uint256) {
        (uint256 _coverTokens, , , , ) = policyBook.policyHolders(user);
        _coverTokens = DecimalsConverter.convertFrom18(
            _coverTokens.div(100),
            policyBook.stblDecimals()
        );

        return IPriceFeed(priceFeed).howManyBMIsInUSDT(_coverTokens);
    }

    /// @notice upserts a withdraw request
    /// @dev prevents adding a request if an already pending or ready request is open.
    /// @param _tokensToWithdraw uint256 amount of tokens to withdraw
    function requestWithdrawal(uint256 _tokensToWithdraw) external override {
        require(_tokensToWithdraw > 0, "PB: Amount is zero");

        IPolicyBook.WithdrawalStatus _withdrawlStatus = policyBook.getWithdrawalStatus(msg.sender);

        require(
            _withdrawlStatus == IPolicyBook.WithdrawalStatus.NONE ||
                _withdrawlStatus == IPolicyBook.WithdrawalStatus.EXPIRED,
            "PBf: ongoing withdrawl request"
        );

        require(
            !claimingRegistry.hasProcedureOngoing(address(policyBook)),
            "PBf: ongoing claim procedure"
        );

        policyBook.requestWithdrawal(_tokensToWithdraw, msg.sender);

        liquidityRegistry.registerWithdrawl(address(policyBook), msg.sender);
    }

    /// @notice Used to get a list of user leverage pools which provide leverage to this pool , use with count()
    /// @return _userLeveragePools a list containing policybook addresses
    function listUserLeveragePools(uint256 offset, uint256 limit)
        external
        view
        override
        returns (address[] memory _userLeveragePools)
    {
        uint256 to = (offset.add(limit)).min(userLeveragePools.length()).max(offset);

        _userLeveragePools = new address[](to - offset);

        for (uint256 i = offset; i < to; i++) {
            _userLeveragePools[i - offset] = userLeveragePools.at(i);
        }
    }

    /// @notice get count of user leverage pools which provide leverage to this pool
    function countUserLeveragePools() external view override returns (uint256) {
        return userLeveragePools.length();
    }

    function secondsToEndCurrentEpoch() public view override returns (uint256) {
        uint256 epochNumber =
            block.timestamp.sub(policyBook.epochStartTime()).div(EPOCH_DURATION) + 1;

        return
            epochNumber.mul(EPOCH_DURATION).sub(block.timestamp.sub(policyBook.epochStartTime()));
    }

    function forceUpdateBMICoverStakingRewardMultiplier() external override {
        uint256 rewardMultiplier;

        if (policyBook.whitelisted()) {
            rewardMultiplier = MINIMUM_REWARD;
            uint256 liquidity = policyBook.totalLiquidity();
            uint256 coverTokens = policyBook.totalCoverTokens();

            if (coverTokens > 0 && liquidity > 0) {
                rewardMultiplier = BASE_REWARD;

                uint256 utilizationRatio = coverTokens.mul(PERCENTAGE_100).div(liquidity);

                if (utilizationRatio < MODERATE_UTILIZATION_RATIO) {
                    rewardMultiplier = Math
                        .max(utilizationRatio, PRECISION)
                        .sub(PRECISION)
                        .mul(BASE_REWARD.sub(MINIMUM_REWARD))
                        .div(MODERATE_UTILIZATION_RATIO)
                        .add(MINIMUM_REWARD);
                } else if (utilizationRatio > RISKY_UTILIZATION_RATIO) {
                    rewardMultiplier = MAXIMUM_REWARD
                        .sub(BASE_REWARD)
                        .mul(utilizationRatio.sub(RISKY_UTILIZATION_RATIO))
                        .div(PERCENTAGE_100.sub(RISKY_UTILIZATION_RATIO))
                        .add(BASE_REWARD);
                }
            }
        }

        bool isStablecoin =
            policyBook.contractType() == IPolicyBookFabric.ContractType.STABLECOIN ? true : false;

        rewardsGenerator.updatePolicyBookShare(
            rewardMultiplier.div(10**22),
            address(policyBook),
            isStablecoin
        ); // 5 decimal places or zero
    }

    function getPolicyPrice(
        uint256 _epochsNumber,
        uint256 _coverTokens,
        address _holder
    )
        public
        view
        override
        returns (
            uint256 totalSeconds,
            uint256 totalPrice,
            uint256 pricePercentage
        )
    {
        require(_coverTokens >= MINUMUM_COVERAGE, "PB: Wrong cover");
        require(_epochsNumber > 0 && _epochsNumber <= MAXIMUM_EPOCHS, "PB: Wrong epoch duration");

        (uint256 newTotalCoverTokens, uint256 newTotalLiquidity) =
            policyBook.getNewCoverAndLiquidity();

        totalSeconds = secondsToEndCurrentEpoch().add(_epochsNumber.sub(1).mul(EPOCH_DURATION));
        (totalPrice, pricePercentage) = policyQuote.getQuotePredefined(
            totalSeconds,
            _coverTokens,
            newTotalCoverTokens,
            newTotalLiquidity,
            totalLeveragedLiquidity,
            safePricingModel
        );

        ///@notice commented this because of PB size when adding a new feature
        /// and it is not used anymore ATM
        // reduce premium by reward NFT locked by user
        // uint256 _reductionMultiplier = nftStaking.getUserReductionMultiplier(_holder);
        // if (_reductionMultiplier > 0) {
        //     totalPrice = totalPrice.sub(totalPrice.mul(_reductionMultiplier).div(PERCENTAGE_100));
        // }
    }

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
        return (
            ERC20(address(policyBook)).symbol(),
            policyBook.insuranceContractAddress(),
            policyBook.contractType(),
            policyBook.whitelisted()
        );
    }
}