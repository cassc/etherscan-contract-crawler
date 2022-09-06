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
import "./interfaces/IRewardsGenerator.sol";
import "./helpers/PriceFeed.sol";

import "./abstract/AbstractDependant.sol";

import "./Globals.sol";

contract RewardsGenerator is IRewardsGenerator, OwnableUpgradeable, AbstractDependant {
    using SafeMath for uint256;
    using Math for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    IERC20 public bmiToken;
    IPolicyBookRegistry public policyBookRegistry;
    IPriceFeed public priceFeed;
    address public bmiCoverStakingAddress;
    address public bmiStakingAddress;
    address public legacyRewardsGeneratorAddress;

    uint256 public stblDecimals;

    uint256 public rewardPerBlock; // is zero by default
    uint256 public totalPoolStaked; // includes 5 decimal places

    uint256 public cumulativeSum; // includes 100 percentage
    uint256 public toUpdateRatio; // includes 100 percentage

    uint256 public lastUpdateBlock;

    mapping(address => PolicyBookRewardInfo) internal _policyBooksRewards; // policybook -> policybook info
    mapping(uint256 => StakeRewardInfo) internal _stakes; // nft index -> stake info

    address public bmiCoverStakingViewAddress;

    uint256 public policyBookStableRatio; // % with precision 10^25

    Networks private _currentNetwork;

    event TokensSent(address stakingAddress, uint256 amount);
    event TokensRecovered(address to, uint256 amount);
    event RewardPerBlockSet(uint256 rewardPerBlock);
    event PercentageStblSet(uint256 policyBookStableRatio);

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

    /// @notice withdraws all underlying BMIs to the owner
    function recoverTokens() external onlyOwner {
        uint256 balance = bmiToken.balanceOf(address(this));

        bmiToken.transfer(_msgSender(), balance);

        emit TokensRecovered(_msgSender(), balance);
    }

    //disbaled becuase of multichain integration
    // function sendFundsToBMIStaking(uint256 amount) external onlyOwner {
    //     bmiToken.transfer(bmiStakingAddress, amount);

    //     emit TokensSent(bmiStakingAddress, amount);
    // }

    function sendFundsToBMICoverStaking(uint256 amount) external onlyOwner {
        bmiToken.transfer(bmiCoverStakingAddress, amount);

        emit TokensSent(bmiCoverStakingAddress, amount);
    }

    function setRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        rewardPerBlock = _rewardPerBlock;

        _updateCumulativeSum(address(0));

        emit RewardPerBlockSet(_rewardPerBlock);
    }

    function setPolicyBookStableRatio(uint256 _policyBookStableRatio) external onlyOwner {
        policyBookStableRatio = _policyBookStableRatio;

        _updateCumulativeSum(address(0));

        emit PercentageStblSet(_policyBookStableRatio);
    }

    /// @notice updates cumulative sum for a particular PB or for all of them if policyBookAddress is zero
    function _updateCumulativeSum(address policyBookAddress) internal {
        uint256 toAddSum = block.number.sub(lastUpdateBlock).mul(toUpdateRatio);
        uint256 totalStaked = totalPoolStaked;

        uint256 newCumulativeSum = cumulativeSum.add(toAddSum);

        totalStaked > 0
            ? toUpdateRatio = rewardPerBlock.mul(PERCENTAGE_100 * 10**5).div(totalStaked)
            : toUpdateRatio = 0;

        if (policyBookAddress != address(0)) {
            PolicyBookRewardInfo storage info = _policyBooksRewards[policyBookAddress];

            info.cumulativeReward = info.cumulativeReward.add(
                newCumulativeSum.sub(info.lastCumulativeSum).mul(info.rewardMultiplier).div(10**5)
            );

            info.lastCumulativeSum = newCumulativeSum;
        }

        cumulativeSum = newCumulativeSum;
        lastUpdateBlock = block.number;
    }

    /// @notice emulates a cumulative sum update for a specific PB and returns its accumulated reward (per token)
    function _getPBCumulativeReward(address policyBookAddress) internal view returns (uint256) {
        PolicyBookRewardInfo storage info = _policyBooksRewards[policyBookAddress];

        uint256 toAddSum = block.number.sub(lastUpdateBlock).mul(toUpdateRatio);

        return
            info.cumulativeReward.add(
                cumulativeSum
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
    function updatePolicyBookShare(
        uint256 newRewardMultiplier,
        address policyBook,
        bool isStablecoin
    ) external override onlyPolicyBooks {
        PolicyBookRewardInfo storage info = _policyBooksRewards[policyBook];

        if (isStablecoin) {
            newRewardMultiplier = newRewardMultiplier.mul(policyBookStableRatio).div(
                PERCENTAGE_100
            );
        }

        uint256 totalPBStaked = info.totalStaked;
        uint256 totalStaked = totalPoolStaked;

        totalStaked = totalStaked.sub(totalPBStaked.mul(info.rewardMultiplier));
        totalStaked = totalStaked.add(totalPBStaked.mul(newRewardMultiplier));

        totalPoolStaked = totalStaked;

        _updateCumulativeSum(_msgSender());

        info.rewardMultiplier = newRewardMultiplier;
    }

    /// @notice aggregates specified NFTs into a single one, including the rewards
    function aggregate(
        address policyBookAddress,
        uint256[] calldata nftIndexes,
        uint256 nftIndexTo
    ) external override onlyBMICoverStaking {
        require(_stakes[nftIndexTo].stakeAmount == 0, "RewardsGenerator: Aggregator is staked");

        _updateCumulativeSum(policyBookAddress);

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

        PolicyBookRewardInfo storage info = _policyBooksRewards[policyBookAddress];

        if (info.totalStaked == 0) {
            info.lastUpdateBlock = block.number;
            info.cumulativeReward = 0;
        }

        totalPoolStaked = totalPoolStaked.add(amount.mul(info.rewardMultiplier));

        _updateCumulativeSum(policyBookAddress);

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
        uint256 policyBookRewardMultiplier =
            _policyBooksRewards[policyBookAddress].rewardMultiplier;

        ///@dev in case called by user leverage pool and no leveraged pools invested
        if (policyBookRewardMultiplier == 0) {
            return 0;
        }

        uint256 totalStakedPolicyBook =
            _policyBooksRewards[policyBookAddress].totalStaked.add(APY_TOKENS);

        uint256 rewardPerBlockPolicyBook =
            policyBookRewardMultiplier.mul(totalStakedPolicyBook).mul(rewardPerBlock).div(
                totalPoolStaked.add(policyBookRewardMultiplier.mul(APY_TOKENS))
            );

        if (rewardPerBlockPolicyBook == 0) {
            return 0;
        }

        //@dev always use the eth usdt decimals for bmi price, it is only on Ethereum
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

    /// @dev returns PolicyBook reward per block multiplied by 10**25
    function getPolicyBookRewardPerBlock(address policyBookAddress)
        external
        view
        override
        returns (uint256)
    {
        uint256 totalStaked = totalPoolStaked;

        return
            totalStaked > 0
                ? _policyBooksRewards[policyBookAddress]
                    .rewardMultiplier
                    .mul(_policyBooksRewards[policyBookAddress].totalStaked)
                    .mul(rewardPerBlock)
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

        PolicyBookRewardInfo storage info = _policyBooksRewards[policyBookAddress];

        if (!onlyReward) {
            uint256 amount = _stakes[nftIndex].stakeAmount;

            totalPoolStaked = totalPoolStaked.sub(amount.mul(info.rewardMultiplier));

            _updateCumulativeSum(policyBookAddress);

            info.totalStaked = info.totalStaked.sub(amount);
        } else {
            _updateCumulativeSum(policyBookAddress);
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
}