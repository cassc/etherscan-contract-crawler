// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./libraries/DecimalsConverter.sol";

import "./interfaces/IContractsRegistry.sol";
import "./interfaces/IPolicyBookRegistry.sol";
import "./interfaces/IPolicyBook.sol";
import "./interfaces/IRewardsGenerator.sol";
import "./interfaces/IPolicyBookFabric.sol";

import "./helpers/PriceFeed.sol";

import "./abstract/AbstractDependant.sol";

import "./Globals.sol";

contract RewardsGenerator is IRewardsGenerator, OwnableUpgradeable, AbstractDependant {
    using SafeMath for uint256;
    using Math for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    IERC20 public bmiToken;
    IPolicyBookRegistry public policyBookRegistry;
    IPriceFeed public priceFeed;
    address public bmiCoverStakingAddress;
    address public bmiStakingAddress;
    address public legacyRewardsGeneratorAddress;

    uint256 public stblDecimals;

    uint256 public rewardPerBlock; // is zero by default

    uint256 public totalPoolStaked; // disused
    uint256 public cumulativeSum; // disused
    uint256 public toUpdateRatio; // disused
    uint256 public lastUpdateBlock; // disused

    mapping(address => PolicyBookRewardInfo) internal _policyBooksRewards; // policybook -> policybook info
    mapping(uint256 => StakeRewardInfo) internal _stakes; // nft index -> stake info

    address public bmiCoverStakingViewAddress;

    uint256 public policyBookStableRatio; // disused

    Networks private _currentNetwork;

    mapping(IPolicyBookFabric.ContractType => DistributionInfo) public distributionInfo;

    event TokensSent(address stakingAddress, uint256 amount);
    event TokensRecovered(address to, uint256 amount);
    event RewardPerBlockSet(uint256 rewardPerBlock);
    event PercentageSet(IPolicyBookFabric.ContractType contractType, uint256 rewardRatio);

    modifier onlyBMICoverStaking() {
        require(
            _msgSender() == bmiCoverStakingAddress || _msgSender() == bmiCoverStakingViewAddress,
            "RewardsGenerator: Caller is not a BMICoverStaking contract"
        );
        _;
    }

    modifier onlyPolicyBooks() {
        require(
            policyBookRegistry.isPolicyBook(_msgSender()) ||
                policyBookRegistry.isPolicyBookFacade(_msgSender()),
            "RewardsGenerator: The caller does not have access"
        );
        _;
    }

    function __RewardsGenerator_init(Networks _network) external initializer {
        __Ownable_init();
        _currentNetwork = _network;
    }

    function configureNetwork(Networks _network) public onlyOwner {
        _currentNetwork = _network;
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        bmiToken = IERC20(_contractsRegistry.getBMIContract());
        //bmiStakingAddress = _contractsRegistry.getBMIStakingContract();
        bmiCoverStakingAddress = _contractsRegistry.getBMICoverStakingContract();
        bmiCoverStakingViewAddress = _contractsRegistry.getBMICoverStakingViewContract();
        policyBookRegistry = IPolicyBookRegistry(
            _contractsRegistry.getPolicyBookRegistryContract()
        );
        priceFeed = IPriceFeed(_contractsRegistry.getPriceFeedContract());

        stblDecimals = ERC20(_contractsRegistry.getUSDTContract()).decimals();
    }

    /// @dev to update each time a contract type is added in IPolicyBookFabric
    function getContractTypes()
        public
        pure
        returns (IPolicyBookFabric.ContractType[] memory contractTypes)
    {
        contractTypes = new IPolicyBookFabric.ContractType[](5);
        contractTypes[0] = IPolicyBookFabric.ContractType.CONTRACT;
        contractTypes[1] = IPolicyBookFabric.ContractType.STABLECOIN;
        contractTypes[2] = IPolicyBookFabric.ContractType.SERVICE;
        contractTypes[3] = IPolicyBookFabric.ContractType.EXCHANGE;
        contractTypes[4] = IPolicyBookFabric.ContractType.VARIOUS;
    }

    /// @notice withdraws all underlying BMIs to the owner
    function recoverTokens() external onlyOwner {
        uint256 balance = bmiToken.balanceOf(address(this));

        bmiToken.transfer(_msgSender(), balance);

        emit TokensRecovered(_msgSender(), balance);
    }

    function sendFundsToBMICoverStaking(uint256 amount) external onlyOwner {
        bmiToken.transfer(bmiCoverStakingAddress, amount);

        emit TokensSent(bmiCoverStakingAddress, amount);
    }

    function setRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        rewardPerBlock = _rewardPerBlock;

        IPolicyBookFabric.ContractType[] memory contractTypes = getContractTypes();

        for (uint256 i = 0; i < contractTypes.length; i++) {
            _updateCumulativeSum(address(0), contractTypes[i]);
        }

        emit RewardPerBlockSet(_rewardPerBlock);
    }

    function setRewardRatios(uint256[] memory rewardRatios) external onlyOwner {
        IPolicyBookFabric.ContractType[] memory contractTypes = getContractTypes();

        require(
            contractTypes.length == rewardRatios.length,
            "RewardGenerator : Lengths mismatches"
        );
        uint256 totalPercentage;
        for (uint256 i = 0; i < rewardRatios.length; i++) {
            totalPercentage = totalPercentage.add(rewardRatios[i]);
        }
        require(totalPercentage == PERCENTAGE_100, "RewardGenerator : Data mismatch");

        for (uint256 i = 0; i < contractTypes.length; i++) {
            distributionInfo[contractTypes[i]].rewardRatio = rewardRatios[i];

            _updateCumulativeSum(address(0), contractTypes[i]);
            emit PercentageSet(contractTypes[i], rewardRatios[i]);
        }
    }

    /// @notice updates cumulative sum for a particular PB or for all of them if policyBookAddress is zero
    function _updateCumulativeSum(
        address policyBookAddress,
        IPolicyBookFabric.ContractType contractType
    ) internal {
        uint256 toAddSum =
            block.number.sub(distributionInfo[contractType].lastUpdateBlock).mul(
                distributionInfo[contractType].toUpdateRatio
            );
        uint256 totalStaked = distributionInfo[contractType].totalContractTypeStaked;

        uint256 newCumulativeSum = distributionInfo[contractType].cumulativeSum.add(toAddSum);

        uint256 contractTypeRewardPerBlock = getContractTypeRewardPerBlock(contractType);

        totalStaked > 0
            ? distributionInfo[contractType].toUpdateRatio = contractTypeRewardPerBlock
                .mul(PERCENTAGE_100 * 10**5)
                .div(totalStaked)
            : distributionInfo[contractType].toUpdateRatio = 0;

        if (policyBookAddress != address(0)) {
            PolicyBookRewardInfo storage info = _policyBooksRewards[policyBookAddress];

            info.cumulativeReward = info.cumulativeReward.add(
                newCumulativeSum.sub(info.lastCumulativeSum).mul(info.rewardMultiplier).div(10**5)
            );

            info.lastCumulativeSum = newCumulativeSum;
        }

        distributionInfo[contractType].cumulativeSum = newCumulativeSum;
        distributionInfo[contractType].lastUpdateBlock = block.number;
    }

    /// @notice emulates a cumulative sum update for a specific PB and returns its accumulated reward (per token)
    function _getPBCumulativeReward(address policyBookAddress) internal view returns (uint256) {
        IPolicyBookFabric.ContractType contractType =
            IPolicyBook(policyBookAddress).contractType();

        PolicyBookRewardInfo storage info = _policyBooksRewards[policyBookAddress];

        uint256 toAddSum =
            block.number.sub(distributionInfo[contractType].lastUpdateBlock).mul(
                distributionInfo[contractType].toUpdateRatio
            );

        return
            info.cumulativeReward.add(
                distributionInfo[contractType]
                    .cumulativeSum
                    .add(toAddSum)
                    .sub(info.lastCumulativeSum)
                    .mul(info.rewardMultiplier)
                    .div(10**5)
            );
    }

    function _getNFTCumulativeReward(uint256 nftIndex, uint256 pbCumulativeReward)
        internal
        view
        returns (uint256)
    {
        return
            _stakes[nftIndex].cumulativeReward.add(
                pbCumulativeReward
                    .sub(_stakes[nftIndex].lastCumulativeSum)
                    .mul(_stakes[nftIndex].stakeAmount)
                    .div(PERCENTAGE_100)
            );
    }

    /// @notice updates the share of the PB based on the new rewards multiplier (also changes the share of others)
    function updatePolicyBookShare(uint256 newRewardMultiplier, address policyBookAddress)
        external
        override
        onlyPolicyBooks
    {
        IPolicyBookFabric.ContractType contractType =
            IPolicyBook(policyBookAddress).contractType();

        PolicyBookRewardInfo storage info = _policyBooksRewards[policyBookAddress];

        uint256 totalPBStaked = info.totalStaked;
        uint256 totalStaked = distributionInfo[contractType].totalContractTypeStaked;

        totalStaked = totalStaked.sub(totalPBStaked.mul(info.rewardMultiplier));
        totalStaked = totalStaked.add(totalPBStaked.mul(newRewardMultiplier));

        distributionInfo[contractType].totalContractTypeStaked = totalStaked;

        _updateCumulativeSum(_msgSender(), contractType);

        info.rewardMultiplier = newRewardMultiplier;
    }

    /// @notice aggregates specified NFTs into a single one, including the rewards
    function aggregate(
        address policyBookAddress,
        uint256[] calldata nftIndexes,
        uint256 nftIndexTo
    ) external override onlyBMICoverStaking {
        require(_stakes[nftIndexTo].stakeAmount == 0, "RewardsGenerator: Aggregator is staked");

        IPolicyBookFabric.ContractType contractType =
            IPolicyBook(policyBookAddress).contractType();

        _updateCumulativeSum(policyBookAddress, contractType);

        uint256 pbCumulativeReward = _policyBooksRewards[policyBookAddress].cumulativeReward;
        uint256 aggregatedReward;
        uint256 aggregatedStakeAmount;

        for (uint256 i = 0; i < nftIndexes.length; i++) {
            uint256 nftReward = _getNFTCumulativeReward(nftIndexes[i], pbCumulativeReward);
            uint256 stakedAmount = _stakes[nftIndexes[i]].stakeAmount;

            require(stakedAmount > 0, "RewardsGenerator: Aggregated not staked");

            aggregatedReward = aggregatedReward.add(nftReward);
            aggregatedStakeAmount = aggregatedStakeAmount.add(stakedAmount);

            delete _stakes[nftIndexes[i]];
        }

        _stakes[nftIndexTo] = StakeRewardInfo(
            pbCumulativeReward,
            aggregatedReward,
            aggregatedStakeAmount
        );
    }

    function _stake(
        address policyBookAddress,
        uint256 nftIndex,
        uint256 amount,
        uint256 currentReward
    ) internal {
        require(_stakes[nftIndex].stakeAmount == 0, "RewardsGenerator: Already staked");

        IPolicyBookFabric.ContractType contractType =
            IPolicyBook(policyBookAddress).contractType();

        PolicyBookRewardInfo storage info = _policyBooksRewards[policyBookAddress];

        if (info.totalStaked == 0) {
            info.lastUpdateBlock = block.number;
            info.cumulativeReward = 0;
        }

        distributionInfo[contractType].totalContractTypeStaked = distributionInfo[contractType]
            .totalContractTypeStaked
            .add(amount.mul(info.rewardMultiplier));

        _updateCumulativeSum(policyBookAddress, contractType);

        info.totalStaked = info.totalStaked.add(amount);

        _stakes[nftIndex] = StakeRewardInfo(info.cumulativeReward, currentReward, amount);
    }

    /// @notice attaches underlying STBL tokens to an NFT and initiates rewards gain
    function stake(
        address policyBookAddress,
        uint256 nftIndex,
        uint256 amount
    ) external override onlyBMICoverStaking {
        _stake(policyBookAddress, nftIndex, amount, 0);
    }

    /// @notice calculates APY of the specific PB
    /// @dev returns APY% in STBL multiplied by 10**5
    function getPolicyBookAPY(address policyBookAddress, uint256 bmiPriceInUSDT)
        external
        view
        override
        onlyBMICoverStaking
        returns (uint256)
    {
        IPolicyBookFabric.ContractType contractType =
            IPolicyBook(policyBookAddress).contractType();

        uint256 policyBookRewardMultiplier =
            _policyBooksRewards[policyBookAddress].rewardMultiplier;

        ///@dev in case called by user leverage pool and no leveraged pools invested
        if (policyBookRewardMultiplier == 0) {
            return 0;
        }

        uint256 totalStakedPolicyBook =
            _policyBooksRewards[policyBookAddress].totalStaked.add(APY_TOKENS);

        uint256 contractTypeRewardPerBlock = getContractTypeRewardPerBlock(contractType);

        uint256 rewardPerBlockPolicyBook =
            policyBookRewardMultiplier
                .mul(totalStakedPolicyBook)
                .mul(contractTypeRewardPerBlock)
                .div(
                distributionInfo[contractType].totalContractTypeStaked.add(
                    policyBookRewardMultiplier.mul(APY_TOKENS)
                )
            );

        if (rewardPerBlockPolicyBook == 0) {
            return 0;
        }

        uint256 rewardPerBlockPolicyBookSTBL =
            DecimalsConverter
                .convertTo18(bmiPriceInUSDT, 6)
                .mul(rewardPerBlockPolicyBook)
                .div(APY_TOKENS)
                .mul(10**5); // 5 decimals of precision

        return
            rewardPerBlockPolicyBookSTBL.mul(_getBlocksPerDay() * 365).mul(100).div(
                totalStakedPolicyBook
            );
    }

    function _getBlocksPerDay() internal view returns (uint256 _blockPerDays) {
        if (_currentNetwork == Networks.ETH) {
            _blockPerDays = BLOCKS_PER_DAY;
        } else if (_currentNetwork == Networks.BSC) {
            _blockPerDays = BLOCKS_PER_DAY_BSC;
        } else if (_currentNetwork == Networks.POL) {
            _blockPerDays = BLOCKS_PER_DAY_POLYGON;
        }
    }

    /// @notice returns policybook's RewardMultiplier multiplied by 10**5
    function getPolicyBookRewardMultiplier(address policyBookAddress)
        external
        view
        override
        onlyPolicyBooks
        returns (uint256)
    {
        return _policyBooksRewards[policyBookAddress].rewardMultiplier;
    }

    function getContractTypeRewardPerBlock(IPolicyBookFabric.ContractType contractType)
        public
        view
        returns (uint256)
    {
        return rewardPerBlock.mul(distributionInfo[contractType].rewardRatio).div(PERCENTAGE_100);
    }

    /// @dev returns PolicyBook reward per block multiplied by 10**25
    function getPolicyBookRewardPerBlock(address policyBookAddress)
        external
        view
        override
        returns (uint256)
    {
        IPolicyBookFabric.ContractType contractType =
            IPolicyBook(policyBookAddress).contractType();
        uint256 contractTypeRewardPerBlock = getContractTypeRewardPerBlock(contractType);

        uint256 totalStaked = distributionInfo[contractType].totalContractTypeStaked;

        return
            totalStaked > 0
                ? _policyBooksRewards[policyBookAddress]
                    .rewardMultiplier
                    .mul(_policyBooksRewards[policyBookAddress].totalStaked)
                    .mul(contractTypeRewardPerBlock)
                    .mul(PRECISION)
                    .div(totalStaked)
                : 0;
    }

    /// @notice returns how much STBL are using in rewards generation in the specific PB
    function getStakedPolicyBookSTBL(address policyBookAddress)
        external
        view
        override
        returns (uint256)
    {
        return _policyBooksRewards[policyBookAddress].totalStaked;
    }

    /// @notice returns how much STBL are used by an NFT
    function getStakedNFTSTBL(uint256 nftIndex) external view override returns (uint256) {
        return _stakes[nftIndex].stakeAmount;
    }

    /// @notice returns current reward of an NFT
    function getReward(address policyBookAddress, uint256 nftIndex)
        external
        view
        override
        onlyBMICoverStaking
        returns (uint256)
    {
        return _getNFTCumulativeReward(nftIndex, _getPBCumulativeReward(policyBookAddress));
    }

    /// @notice withdraws funds/rewards of this NFT
    /// if funds are withdrawn, updates shares of the PBs
    function _withdraw(
        address policyBookAddress,
        uint256 nftIndex,
        bool onlyReward
    ) internal returns (uint256) {
        require(_stakes[nftIndex].stakeAmount > 0, "RewardsGenerator: Not staked");

        IPolicyBookFabric.ContractType contractType =
            IPolicyBook(policyBookAddress).contractType();

        PolicyBookRewardInfo storage info = _policyBooksRewards[policyBookAddress];

        if (!onlyReward) {
            uint256 amount = _stakes[nftIndex].stakeAmount;

            distributionInfo[contractType].totalContractTypeStaked = distributionInfo[contractType]
                .totalContractTypeStaked
                .sub(amount.mul(info.rewardMultiplier));

            _updateCumulativeSum(policyBookAddress, contractType);

            info.totalStaked = info.totalStaked.sub(amount);
        } else {
            _updateCumulativeSum(policyBookAddress, contractType);
        }

        /// @dev no need to update the NFT reward, because it will be erased just after
        return _getNFTCumulativeReward(nftIndex, info.cumulativeReward);
    }

    /// @notice withdraws funds (rewards + STBL tokens) of this NFT
    function withdrawFunds(address policyBookAddress, uint256 nftIndex)
        external
        override
        onlyBMICoverStaking
        returns (uint256)
    {
        uint256 reward = _withdraw(policyBookAddress, nftIndex, false);

        delete _stakes[nftIndex];

        return reward;
    }

    /// @notice withdraws rewards of this NFT
    function withdrawReward(address policyBookAddress, uint256 nftIndex)
        external
        override
        onlyBMICoverStaking
        returns (uint256)
    {
        uint256 reward = _withdraw(policyBookAddress, nftIndex, true);

        _stakes[nftIndex].lastCumulativeSum = _policyBooksRewards[policyBookAddress]
            .cumulativeReward;
        _stakes[nftIndex].cumulativeReward = 0;

        return reward;
    }

    function migrateDataforOtheChains() external onlyOwner {
        distributionInfo[IPolicyBookFabric.ContractType.CONTRACT]
            .totalContractTypeStaked = totalPoolStaked;
        distributionInfo[IPolicyBookFabric.ContractType.CONTRACT].cumulativeSum = cumulativeSum;
        distributionInfo[IPolicyBookFabric.ContractType.CONTRACT].toUpdateRatio = toUpdateRatio;
        distributionInfo[IPolicyBookFabric.ContractType.CONTRACT]
            .lastUpdateBlock = lastUpdateBlock;
    }

    function migrateData() external onlyOwner {
        uint256 stakedLeverage =
            _policyBooksRewards[0x421e747B172E2Cc132dD8ABd71f6F430CB7d3408].totalStaked;
        uint256 multiplierLeverage =
            _policyBooksRewards[0x421e747B172E2Cc132dD8ABd71f6F430CB7d3408].rewardMultiplier;

        distributionInfo[IPolicyBookFabric.ContractType.VARIOUS]
            .totalContractTypeStaked = stakedLeverage.mul(multiplierLeverage);

        distributionInfo[IPolicyBookFabric.ContractType.CONTRACT]
            .totalContractTypeStaked = totalPoolStaked.sub(
            distributionInfo[IPolicyBookFabric.ContractType.VARIOUS].totalContractTypeStaked
        );

        distributionInfo[IPolicyBookFabric.ContractType.CONTRACT].toUpdateRatio = toUpdateRatio;
        distributionInfo[IPolicyBookFabric.ContractType.VARIOUS].toUpdateRatio = toUpdateRatio;

        distributionInfo[IPolicyBookFabric.ContractType.CONTRACT].cumulativeSum = cumulativeSum;
        distributionInfo[IPolicyBookFabric.ContractType.VARIOUS].cumulativeSum = cumulativeSum;

        distributionInfo[IPolicyBookFabric.ContractType.CONTRACT]
            .lastUpdateBlock = lastUpdateBlock;
        distributionInfo[IPolicyBookFabric.ContractType.VARIOUS].lastUpdateBlock = lastUpdateBlock;
    }
}