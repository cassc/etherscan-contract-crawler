// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./libraries/DecimalsConverter.sol";

import "./tokens/erc20permit-upgradeable/ERC20PermitUpgradeable.sol";

import "./interfaces/IPolicyBook.sol";
import "./interfaces/IBMICoverStaking.sol";
import "./interfaces/ICapitalPool.sol";
import "./interfaces/IBMICoverStakingView.sol";
import "./interfaces/IContractsRegistry.sol";
import "./interfaces/IPolicyRegistry.sol";
import "./interfaces/IClaimVoting.sol";
import "./interfaces/IClaimingRegistry.sol";
import "./interfaces/ILiquidityMining.sol";
import "./interfaces/IPolicyQuote.sol";
import "./interfaces/IRewardsGenerator.sol";
import "./interfaces/ILiquidityRegistry.sol";
import "./interfaces/INFTStaking.sol";

import "./abstract/AbstractDependant.sol";

import "./Globals.sol";

contract PolicyBook is IPolicyBook, ERC20PermitUpgradeable, AbstractDependant {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;
    using Math for uint256;

    uint256 public constant override EPOCH_DURATION = 1 weeks;
    uint256 public constant MAXIMUM_EPOCHS = SECONDS_IN_THE_YEAR / EPOCH_DURATION;
    uint256 public constant VIRTUAL_EPOCHS = 1;

    uint256 public constant override READY_TO_WITHDRAW_PERIOD = 2 days;

    bool public override whitelisted;

    uint256 public override epochStartTime;
    uint256 public lastDistributionEpoch;

    uint256 public lastPremiumDistributionEpoch;
    int256 public lastPremiumDistributionAmount;

    address public override insuranceContractAddress;
    IPolicyBookFabric.ContractType public override contractType;

    ERC20 public stblToken;
    IPolicyRegistry public policyRegistry;
    IBMICoverStaking public bmiCoverStaking;
    IRewardsGenerator public rewardsGenerator;
    ILiquidityMining public liquidityMining;
    IClaimVoting public claimVoting;
    IClaimingRegistry public claimingRegistry;
    ILiquidityRegistry public liquidityRegistry;
    address public reinsurancePoolAddress;
    IPolicyQuote public policyQuote;
    address public policyBookAdmin;
    address public policyBookRegistry;
    address public policyBookFabricAddress;

    uint256 public override totalLiquidity;
    uint256 public override totalCoverTokens;

    mapping(address => WithdrawalInfo) public override withdrawalsInfo;
    mapping(address => PolicyHolder) public override policyHolders;
    mapping(address => uint256) public liquidityFromLM;
    mapping(uint256 => uint256) public epochAmounts;
    mapping(uint256 => int256) public premiumDistributionDeltas;

    uint256 public override stblDecimals;

    // new state variables here , avoid break the storage when upgrade
    INFTStaking public nftStaking;
    IBMICoverStakingView public bmiCoverStakingView;
    ICapitalPool public capitalPool;
    IPolicyBookFacade public override policyBookFacade;

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
    event LiquidityWithdrawn(
        address _liquidityHolder,
        uint256 _tokensToWithdraw,
        uint256 _newTotalLiquidity
    );
    event PolicyBought(
        address _policyHolder,
        uint256 _coverTokens,
        uint256 _price,
        uint256 _newTotalCoverTokens,
        address _distributor
    );
    event CoverageChanged(uint256 _newTotalCoverTokens);

    modifier onlyClaimingRegistry() {
        require(_msgSender() == address(claimingRegistry), "PB: Not a CM");
        _;
    }

    modifier onlyClaimVoting() {
        require(_msgSender() == address(claimVoting), "PB: Not a CV");
        _;
    }

    modifier onlyPolicyBookFacade() {
        require(_msgSender() == address(policyBookFacade), "PB: Not a PBFc");
        _;
    }

    modifier onlyPolicyBookFabric() {
        require(_msgSender() == policyBookFabricAddress, "PB: Not PBF");
        _;
    }

    modifier onlyPolicyBookAdmin() {
        require(_msgSender() == policyBookAdmin, "PB: Not a PBA");
        _;
    }

    modifier onlyLiquidityAdders() {
        require(
            _msgSender() == policyBookFabricAddress || _msgSender() == address(policyBookFacade),
            "PB: Not allowed"
        );
        _;
    }

    modifier onlyCapitalPool() {
        require(_msgSender() == address(capitalPool), "PB: Not a CP");
        _;
    }

    modifier updateBMICoverStakingReward() {
        _;
        policyBookFacade.forceUpdateBMICoverStakingRewardMultiplier();
    }

    modifier withPremiumsDistribution() {
        _distributePremiums();
        _;
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

    function __PolicyBook_init(
        address _insuranceContract,
        IPolicyBookFabric.ContractType _contractType,
        string calldata _description,
        string calldata _projectSymbol
    ) external override initializer {
        string memory fullSymbol = string(abi.encodePacked("bmiV2", _projectSymbol, "Cover"));
        __ERC20Permit_init(fullSymbol);
        __ERC20_init(_description, fullSymbol);

        insuranceContractAddress = _insuranceContract;
        contractType = _contractType;

        epochStartTime = block.timestamp;
        lastDistributionEpoch = 1;

        lastPremiumDistributionEpoch = _getPremiumDistributionEpoch();
    }

    function setPolicyBookFacade(address _policyBookFacade)
        external
        override
        onlyPolicyBookFabric
    {
        policyBookFacade = IPolicyBookFacade(_policyBookFacade);
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
        claimVoting = IClaimVoting(_contractsRegistry.getClaimVotingContract());
        policyRegistry = IPolicyRegistry(_contractsRegistry.getPolicyRegistryContract());
        reinsurancePoolAddress = _contractsRegistry.getReinsurancePoolContract();
        capitalPool = ICapitalPool(_contractsRegistry.getCapitalPoolContract());
        policyQuote = IPolicyQuote(_contractsRegistry.getPolicyQuoteContract());
        claimingRegistry = IClaimingRegistry(_contractsRegistry.getClaimingRegistryContract());
        liquidityRegistry = ILiquidityRegistry(_contractsRegistry.getLiquidityRegistryContract());
        policyBookAdmin = _contractsRegistry.getPolicyBookAdminContract();
        policyBookRegistry = _contractsRegistry.getPolicyBookRegistryContract();
        policyBookFabricAddress = _contractsRegistry.getPolicyBookFabricContract();
        nftStaking = INFTStaking(_contractsRegistry.getNFTStakingContract());
        stblDecimals = stblToken.decimals();
    }

    function whitelist(bool _whitelisted)
        external
        override
        onlyPolicyBookAdmin
        updateBMICoverStakingReward
    {
        whitelisted = _whitelisted;
    }

    function getEpoch(uint256 time) public view override returns (uint256) {
        return time.sub(epochStartTime).div(EPOCH_DURATION) + 1;
    }

    function _getPremiumDistributionEpoch() internal view returns (uint256) {
        return block.timestamp / PREMIUM_DISTRIBUTION_EPOCH;
    }

    // 1655913114 is unix epoch date of upgrade of PolicyBook (modification of VIRTUAL_EPOCHS)
    function getVirtualEpochs(address user) public view virtual returns (uint256 virtualEpochs) {
        virtualEpochs = VIRTUAL_EPOCHS;
        if (epochStartTime < 1655913114) {
            if (
                policyHolders[user].startEpochNumber > 0 &&
                policyHolders[user].startEpochNumber < getEpoch(1655913114)
            ) {
                virtualEpochs = 2;
            }
        }
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

    function _submitClaimAndInitializeVoting(string memory evidenceURI, bool appeal) internal {
        uint256 cover = policyHolders[_msgSender()].coverTokens;
        uint256 virtualEpochs = getVirtualEpochs(_msgSender());
        uint256 virtualEndEpochNumber = policyHolders[_msgSender()].endEpochNumber + virtualEpochs;

        /// @dev "lock" claim and appeal tokens
        if (!appeal) {
            epochAmounts[virtualEndEpochNumber] = epochAmounts[virtualEndEpochNumber].sub(cover);
        } else {
            uint256 claimIndex = claimingRegistry.claimIndex(_msgSender(), address(this));
            uint256 endLockEpoch =
                Math.max(
                    getEpoch(claimingRegistry.claimEndTime(claimIndex)) + 1,
                    virtualEndEpochNumber
                );

            epochAmounts[endLockEpoch] = epochAmounts[endLockEpoch].sub(cover);
        }

        /// @dev if appeal period expired, this would fail in case of appeal (no button is displayed on FE)
        claimVoting.initializeVoting(_msgSender(), evidenceURI, cover, appeal);
    }

    function submitClaimAndInitializeVoting(string calldata evidenceURI) external override {
        _submitClaimAndInitializeVoting(evidenceURI, false);
    }

    function submitAppealAndInitializeVoting(string calldata evidenceURI) external override {
        _submitClaimAndInitializeVoting(evidenceURI, true);
    }

    function commitClaim(
        address claimer,
        uint256 claimEndTime,
        IClaimingRegistry.ClaimStatus status
    ) external override onlyClaimingRegistry withPremiumsDistribution updateBMICoverStakingReward {
        bool _rebalance = true;
        uint256 virtualEpochs = getVirtualEpochs(claimer);
        uint256 virtualEndEpochNumber = policyHolders[claimer].endEpochNumber.add(virtualEpochs);
        if (
            status != IClaimingRegistry.ClaimStatus.ACCEPTED &&
            lastDistributionEpoch > virtualEndEpochNumber
        ) {
            _rebalance = false;
        }

        updateEpochsInfo(_rebalance);

        uint256 cover = policyHolders[claimer].coverTokens;

        if (
            status == IClaimingRegistry.ClaimStatus.REJECTED_CAN_APPEAL ||
            status == IClaimingRegistry.ClaimStatus.EXPIRED
        ) {
            uint256 endUnlockEpoch =
                Math.max(
                    getEpoch(claimEndTime) + 1,
                    policyHolders[claimer].endEpochNumber + virtualEpochs
                );

            epochAmounts[endUnlockEpoch] = epochAmounts[endUnlockEpoch].add(cover);
        } else {
            if (status != IClaimingRegistry.ClaimStatus.ACCEPTED) {
                if (lastDistributionEpoch <= virtualEndEpochNumber) {
                    epochAmounts[virtualEndEpochNumber] = epochAmounts[virtualEndEpochNumber].add(
                        cover
                    );
                } else {
                    uint256 newTotalCover = totalCoverTokens.sub(cover);
                    totalCoverTokens = newTotalCover;
                    policyBookFacade.reevaluateProvidedLeverageStable();
                    emit CoverageChanged(newTotalCover);
                }
            }
        }
    }

    function commitWithdrawnClaim(address claimer)
        external
        override
        onlyClaimingRegistry
        withPremiumsDistribution
        updateBMICoverStakingReward
    {
        updateEpochsInfo(false);

        uint256 cover = policyHolders[claimer].coverTokens;

        uint256 newTotalCover = totalCoverTokens.sub(cover);
        totalCoverTokens = newTotalCover;

        delete policyHolders[claimer];
        policyRegistry.removePolicy(claimer);
        policyBookFacade.reevaluateProvidedLeverageStable();
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

    function getNewCoverAndLiquidity()
        public
        view
        override
        returns (uint256 newTotalCoverTokens, uint256 newTotalLiquidity)
    {
        newTotalLiquidity = totalLiquidity;
        newTotalCoverTokens = totalCoverTokens;

        uint256 lastEpoch = lastPremiumDistributionEpoch;
        uint256 currentEpoch = _getPremiumDistributionEpoch();

        if (currentEpoch > lastEpoch) {
            (, , newTotalLiquidity) = _getPremiumsDistribution(lastEpoch, currentEpoch);
        }

        uint256 newDistributionEpoch = Math.min(getEpoch(block.timestamp), MAXIMUM_EPOCHS);

        for (uint256 i = lastDistributionEpoch; i < newDistributionEpoch; i++) {
            newTotalCoverTokens = newTotalCoverTokens.sub(epochAmounts[i]);
        }
    }

    function buyPolicy(
        address _buyer,
        address _holder,
        uint256 _epochsNumber,
        uint256 _coverTokens,
        uint256 _distributorFee,
        address _distributor
    ) external override returns (uint256, uint256) {
        return
            _buyPolicy(
                BuyPolicyParameters(
                    _buyer,
                    _holder,
                    _epochsNumber,
                    _coverTokens,
                    _distributorFee,
                    _distributor
                )
            );
    }

    function _buyPolicy(BuyPolicyParameters memory parameters)
        internal
        onlyPolicyBookFacade
        withPremiumsDistribution
        updateBMICoverStakingReward
        returns (uint256, uint256)
    {
        // check if there is a previous policy not expired
        require(
            !policyRegistry.isPolicyValid(parameters.holder, address(this)),
            "PB: The holder already exists"
        );

        claimingRegistry.canBuyNewPolicy(parameters.holder, address(this));
        updateEpochsInfo(false);

        uint256 _totalCoverTokens = totalCoverTokens.add(parameters.coverTokens);
        require(
            totalLiquidity >= _totalCoverTokens.add(_getPendingWithdrawalAmount()),
            "PB: Not enough liquidity"
        );

        (uint256 _totalSeconds, uint256 _totalPrice, uint256 pricePercentage) =
            policyBookFacade.getPolicyPrice(
                parameters.epochsNumber,
                parameters.coverTokens,
                parameters.holder
            );

        // Partners are rewarded with X% of the Premium, coming from the Protocol’s fee part.
        // It's a part of 20% initially send to the Reinsurance pool
        // (the other 80% of the Premium is a yield for coverage providers).

        uint256 _distributorFeeAmount;
        if (parameters.distributorFee > 0) {
            _distributorFeeAmount = _totalPrice.mul(parameters.distributorFee).div(PERCENTAGE_100);
        }

        uint256 _reinsurancePrice =
            _totalPrice.mul(PROTOCOL_PERCENTAGE).div(PERCENTAGE_100).sub(_distributorFeeAmount);

        uint256 _price = _totalPrice.sub(_distributorFeeAmount);

        _addPolicyHolder(parameters, _totalPrice, _reinsurancePrice);

        totalCoverTokens = _totalCoverTokens;

        if (_distributorFeeAmount > 0) {
            stblToken.safeTransferFrom(
                parameters.buyer,
                parameters.distributor,
                DecimalsConverter.convertFrom18(_distributorFeeAmount, stblDecimals)
            );
        }
        stblToken.safeTransferFrom(
            parameters.buyer,
            address(capitalPool),
            DecimalsConverter.convertFrom18(_price, stblDecimals)
        );
        _price = capitalPool.addPolicyHoldersHardSTBL(
            DecimalsConverter.convertFrom18(_price, stblDecimals),
            parameters.epochsNumber,
            DecimalsConverter.convertFrom18(_reinsurancePrice, stblDecimals)
        );

        _addPolicyPremiumToDistributions(
            _totalSeconds.add(VIRTUAL_EPOCHS * EPOCH_DURATION),
            _price
        );

        policyRegistry.addPolicy(parameters.holder, parameters.coverTokens, _price, _totalSeconds);

        emit PolicyBought(
            parameters.holder,
            parameters.coverTokens,
            _totalPrice,
            _totalCoverTokens,
            parameters.distributor
        );

        return (_price, pricePercentage);
    }

    function _addPolicyHolder(
        BuyPolicyParameters memory parameters,
        uint256 _totalPrice,
        uint256 _reinsurancePrice
    ) internal {
        uint256 _currentEpochNumber = getEpoch(block.timestamp);
        uint256 _endEpochNumber = _currentEpochNumber.add(parameters.epochsNumber.sub(1));
        uint256 _virtualEndEpochNumber = _endEpochNumber + VIRTUAL_EPOCHS;

        policyHolders[parameters.holder] = PolicyHolder(
            parameters.coverTokens,
            _currentEpochNumber,
            _endEpochNumber,
            _totalPrice,
            _reinsurancePrice
        );

        epochAmounts[_virtualEndEpochNumber] = epochAmounts[_virtualEndEpochNumber].add(
            parameters.coverTokens
        );
    }

    function endActivePolicy(address _holder) external override onlyClaimingRegistry {
        uint256 _cover = policyHolders[_holder].coverTokens;
        uint256 virtualEpochs = getVirtualEpochs(_holder);
        // remove cover from epoch management
        uint256 _virtualEndEpochNumberPrevious =
            policyHolders[_holder].endEpochNumber + virtualEpochs;
        epochAmounts[_virtualEndEpochNumberPrevious] = epochAmounts[_virtualEndEpochNumberPrevious]
            .sub(_cover);
        // remove cover form totalCoverToken
        uint256 newTotalCover = totalCoverTokens.sub(_cover);
        totalCoverTokens = newTotalCover;

        delete policyHolders[_holder];
        policyRegistry.removePolicy(_holder);
        policyBookFacade.reevaluateProvidedLeverageStable();
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

    function updateEpochsInfo(bool _rebalance) public override {
        uint256 _lastDistributionEpoch = lastDistributionEpoch;
        uint256 _newDistributionEpoch =
            Math.min(getEpoch(block.timestamp), _lastDistributionEpoch + MAXIMUM_EPOCHS);

        if (_lastDistributionEpoch < _newDistributionEpoch) {
            uint256 _newTotalCoverTokens = totalCoverTokens;

            for (uint256 i = _lastDistributionEpoch; i < _newDistributionEpoch; i++) {
                _newTotalCoverTokens = _newTotalCoverTokens.sub(epochAmounts[i]);
                delete epochAmounts[i];
            }

            lastDistributionEpoch = _newDistributionEpoch;
            totalCoverTokens = _newTotalCoverTokens;
            if (_rebalance) {
                policyBookFacade.reevaluateProvidedLeverageStable();
            }
            emit CoverageChanged(_newTotalCoverTokens);
        }
    }

    function addLiquidityFor(address _liquidityHolderAddr, uint256 _liquidityAmount)
        external
        override
    {
        addLiquidity(_liquidityHolderAddr, _liquidityHolderAddr, _liquidityAmount, 0);
    }

    /// @notice adds liquidity on behalf of a sender
    /// @dev only allowed to be called from its facade
    /// @param _liquidityBuyerAddr, address  of the one who pays
    /// @param _liquidityHolderAddr, address  of the one who hold
    /// @param _liquidityAmount, uint256 amount to be added on behalf the sender
    /// @param _stakeSTBLAmount uint256 the staked amount if add liq and stake
    function addLiquidity(
        address _liquidityBuyerAddr,
        address _liquidityHolderAddr,
        uint256 _liquidityAmount,
        uint256 _stakeSTBLAmount
    )
        public
        override
        onlyLiquidityAdders
        withPremiumsDistribution
        updateBMICoverStakingReward
        returns (uint256)
    {
        if (_stakeSTBLAmount > 0) {
            require(_stakeSTBLAmount <= _liquidityAmount, "PB: Wrong staking amount");
        }
        uint256 stblLiquidity = DecimalsConverter.convertFrom18(_liquidityAmount, stblDecimals);
        require(stblLiquidity > 0, "PB: Liquidity amount is zero");

        updateEpochsInfo(true);

        /// @dev PBF already sent stable tokens
        /// TODO: track PB sblIngress individually ? or only the _mint
        if (_msgSender() != policyBookFabricAddress) {
            stblToken.safeTransferFrom(_liquidityBuyerAddr, address(capitalPool), stblLiquidity);
        }
        capitalPool.addCoverageProvidersHardSTBL(stblLiquidity);

        uint256 _liquidityAmountBMIX = convertSTBLToBMIX(_liquidityAmount);

        _mint(_liquidityHolderAddr, _liquidityAmountBMIX);
        uint256 liquidity = totalLiquidity.add(_liquidityAmount);
        totalLiquidity = liquidity;

        liquidityRegistry.tryToAddPolicyBook(_liquidityHolderAddr, address(this));
        if (_stakeSTBLAmount > 0) {
            bmiCoverStaking.stakeBMIXFrom(
                _liquidityHolderAddr,
                convertSTBLToBMIX(_stakeSTBLAmount)
            );
        }

        emit LiquidityAdded(_liquidityHolderAddr, _liquidityAmount, liquidity);

        return _liquidityAmountBMIX;
    }

    function getAvailableBMIXWithdrawableAmount(address _userAddr)
        external
        view
        override
        returns (uint256)
    {
        (uint256 newTotalCoverTokens, uint256 newTotalLiquidity) = getNewCoverAndLiquidity();

        return
            convertSTBLToBMIX(
                Math.min(
                    newTotalLiquidity.sub(newTotalCoverTokens).sub(_getPendingWithdrawalAmount()),
                    _getUserAvailableSTBL(_userAddr)
                )
            );
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

        if (block.timestamp >= readyToWithdrawDate.add(READY_TO_WITHDRAW_PERIOD)) {
            return WithdrawalStatus.EXPIRED;
        }

        return WithdrawalStatus.READY;
    }

    function requestWithdrawal(uint256 _tokensToWithdraw, address _user)
        external
        override
        onlyPolicyBookFacade
        withPremiumsDistribution
    {
        uint256 _stblTokensToWithdraw = convertBMIXToSTBL(_tokensToWithdraw);
        uint256 _availableSTBLBalance = _getUserAvailableSTBL(_user);

        require(_availableSTBLBalance >= _stblTokensToWithdraw, "PB: Wrong announced amount");

        updateEpochsInfo(true);
        require(
            totalLiquidity >=
                totalCoverTokens.add(_stblTokensToWithdraw).add(_getPendingWithdrawalAmount()),
            "PB: Not enough free liquidity"
        );

        _lockTokens(_user, _tokensToWithdraw);

        _requestWithdrawal(_tokensToWithdraw, _user);
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

        require(_lockedAmount > 0, "PB: Amount is zero");

        this.transfer(_msgSender(), _lockedAmount);
        delete withdrawalsInfo[_msgSender()];
        liquidityRegistry.removeExpiredWithdrawalRequest(_msgSender(), address(this));
    }

    function withdrawLiquidity(address sender)
        external
        override
        onlyPolicyBookFacade
        withPremiumsDistribution
        updateBMICoverStakingReward
        returns (uint256 _tokensToWithdraw, uint256 _stblTokensToWithdraw)
    {
        require(
            getWithdrawalStatus(sender) == WithdrawalStatus.READY,
            "PB: Withdrawal is not ready"
        );

        updateEpochsInfo(true);

        uint256 liquidity = totalLiquidity;
        uint256 _currentWithdrawalAmount = withdrawalsInfo[sender].withdrawalAmount;
        _tokensToWithdraw = Math.min(
            _currentWithdrawalAmount,
            convertSTBLToBMIX(liquidity.sub(totalCoverTokens))
        );

        _stblTokensToWithdraw = convertBMIXToSTBL(_tokensToWithdraw);

        uint256 _stblTokensToWithdrawConverted =
            DecimalsConverter.convertFrom18(_stblTokensToWithdraw, stblDecimals);

        uint256 _actualStblTokensToWithdraw =
            capitalPool.withdrawLiquidity(sender, _stblTokensToWithdrawConverted, false);

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
            delete withdrawalsInfo[sender];
            liquidityRegistry.tryToRemovePolicyBook(sender, address(this));
        } else {
            _requestWithdrawal(_currentWithdrawalAmount, sender);
        }

        totalLiquidity = liquidity;

        emit LiquidityWithdrawn(sender, _stblTokensToWithdraw, liquidity);
    }

    function updateLiquidity(uint256 _lostLiquidity) external override onlyCapitalPool {
        updateEpochsInfo(false);

        uint256 _newLiquidity = totalLiquidity.sub(_lostLiquidity);
        totalLiquidity = _newLiquidity;

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

    function userStats(address _user) external view override returns (PolicyHolder memory) {
        return policyHolders[_user];
    }

    /// @notice _annualProfitYields is multiplied by 10**5
    /// @notice _annualInsuranceCost is calculated for 1000 STBL cover (or _maxCapacities if it is less)
    /// @notice _bmiXRatio is multiplied by 10**18. To get STBL representation,
    ///     multiply BMIX tokens by this value and then divide by 10**18
    /// @notice _buyPolicyCapacity the capacity for buying a new policy include the requested withdraw amount
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
        uint256 newTotalCoverTokens;

        (newTotalCoverTokens, _totalSTBLLiquidity) = getNewCoverAndLiquidity();
        _maxCapacities = _totalSTBLLiquidity - newTotalCoverTokens;

        _buyPolicyCapacity = _maxCapacities.sub(_getPendingWithdrawalAmount());

        _stakedSTBL = rewardsGenerator.getStakedPolicyBookSTBL(address(this));
        _annualProfitYields = getAPY();

        uint256 possibleCoverage = Math.min(ANNUAL_COVERAGE_TOKENS, _maxCapacities);
        _totalLeveragedLiquidity = policyBookFacade.totalLeveragedLiquidity();

        if (possibleCoverage >= MINUMUM_COVERAGE) {
            (_annualInsuranceCost, ) = policyQuote.getQuotePredefined(
                SECONDS_IN_THE_YEAR,
                possibleCoverage,
                newTotalCoverTokens,
                _totalSTBLLiquidity,
                _totalLeveragedLiquidity,
                policyBookFacade.safePricingModel()
            );

            _annualInsuranceCost = _annualInsuranceCost
                .mul(ANNUAL_COVERAGE_TOKENS.mul(PRECISION).div(possibleCoverage))
                .div(PRECISION)
                .div(10);
        }

        _bmiXRatio = convertBMIXToSTBL(10**18);
    }

    function _getPendingWithdrawalAmount() internal view returns (uint256) {
        return
            liquidityRegistry.getPendingWithdrawalAmountByPolicyBook(
                address(this),
                liquidityRegistry.getPoolWithdrawlRequestsUsersListCount(address(this))
            );
    }
}