//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";

import "./IStake.sol";

contract StakeCall is Initializable, OwnableUpgradeable {
    address public stake;
    struct StakePoolOtherInfo {
        address pool;
        address owner;
        uint256 totalStaked;
        uint256 hardCap;
        address stakeToken;
        address rewardToken;
        IStakePool.StakeStatus status;
        uint256 depositAmount;
        uint256 totalRewardsDistributed;
        uint256 lastDistributeTime;
        bool is_hide;
        uint8 stakeTokenDecimals;
        uint8 rewardTokenDecimals;
        string name;
        string symbol;
        string stakeTokenSymbol;
        string stakeTokenName;
        string rewardTokenSymbol;
        string rewardTokenName;
        uint256 totalStakers;
    }
    struct StakeTotalInfo {
        StakePoolOtherInfo stakePoolOtherInfo;
        IStakePool.StakeModel stakePoolModel;
        int256 indexForUser;
    }

    function initialize(address _stake) public initializer {
        __Ownable_init();
        stake = _stake;
    }

    function updateStake(address _stake) external onlyOwner {
        stake = _stake;
    }

    function getStakePoolsByIndices(uint256 start, uint256 end, address account)
        external 
        view
        returns(
            StakeTotalInfo[] memory
        )
    {
        StakeTotalInfo[] memory stakeTotalInfo=new StakeTotalInfo[](
            end-start+1
        );
        for(uint256 i=start;i<=end;i++){
            (   StakePoolOtherInfo memory stakePoolOtherInfo,
            IStakePool.StakeModel memory stakePoolModel, int256 indexForUser)=getStakePoolByIndex(i, account);
            stakeTotalInfo[i-start]=StakeTotalInfo({
                stakePoolOtherInfo:stakePoolOtherInfo,
                stakePoolModel:stakePoolModel,
                indexForUser:indexForUser                
            });
        }
        return stakeTotalInfo;
    }

    function getStakePoolByIndex(uint256 i, address account)
        public
        view
        returns (
            StakePoolOtherInfo memory stakePoolOtherInfo,
            IStakePool.StakeModel memory stakePoolModel,
            int256 indexForUser
        )
    {
        stakePoolOtherInfo.pool = IStake(stake).pools(i);
        stakePoolModel = getStakeModel(stakePoolOtherInfo.pool);
        stakePoolOtherInfo.totalStakers = IStakePool(stakePoolOtherInfo.pool)
            .getNumberOfStakers();
        stakePoolOtherInfo.owner = IStakePool(stakePoolOtherInfo.pool)
            .stakeOwner();
        stakePoolOtherInfo.totalStaked = IERC20MetadataUpgradeable(
            stakePoolOtherInfo.pool
        ).totalSupply();
        stakePoolOtherInfo.hardCap = ERC20CappedUpgradeable(
            stakePoolOtherInfo.pool
        ).cap();
        stakePoolOtherInfo.stakeToken = IStakePool(stakePoolOtherInfo.pool)
            .stakeToken();
        stakePoolOtherInfo.rewardToken = IStakePool(stakePoolOtherInfo.pool)
            .rewardToken();
        stakePoolOtherInfo.status = IStakePool(stakePoolOtherInfo.pool)
            .status();
        stakePoolOtherInfo.depositAmount = IStakePool(stakePoolOtherInfo.pool)
            .depositAmount();
        stakePoolOtherInfo.totalRewardsDistributed = IStakePool(
            stakePoolOtherInfo.pool
        ).totalRewardsDistributed();
        stakePoolOtherInfo.lastDistributeTime = IStakePool(
            stakePoolOtherInfo.pool
        ).lastDistributeTime();
        stakePoolOtherInfo.name = IERC20MetadataUpgradeable(
            stakePoolOtherInfo.pool
        ).name();
        stakePoolOtherInfo.symbol = IERC20MetadataUpgradeable(
            stakePoolOtherInfo.pool
        ).symbol();
        (stakePoolOtherInfo.is_hide, , ) = IStake(stake).poolModel(
            stakePoolOtherInfo.pool
        );
        stakePoolOtherInfo.stakeTokenDecimals = IERC20MetadataUpgradeable(
            stakePoolOtherInfo.stakeToken
        ).decimals();
        stakePoolOtherInfo.stakeTokenSymbol = IERC20MetadataUpgradeable(
            stakePoolOtherInfo.stakeToken
        ).symbol();
        stakePoolOtherInfo.stakeTokenName = IERC20MetadataUpgradeable(
            stakePoolOtherInfo.stakeToken
        ).name();
        if(stakePoolOtherInfo.rewardToken!=address(0)){
            stakePoolOtherInfo.rewardTokenDecimals = IERC20MetadataUpgradeable(
                stakePoolOtherInfo.rewardToken
            ).decimals();
            stakePoolOtherInfo.rewardTokenSymbol = IERC20MetadataUpgradeable(
                stakePoolOtherInfo.rewardToken
            ).symbol();
            stakePoolOtherInfo.rewardTokenName = IERC20MetadataUpgradeable(
                stakePoolOtherInfo.rewardToken
            ).name();
        }else{
            stakePoolOtherInfo.rewardTokenDecimals = 18;
            stakePoolOtherInfo.rewardTokenSymbol = "NoReward";
            stakePoolOtherInfo.rewardTokenName = "NoReward";
        }
        try IStakePool(stakePoolOtherInfo.pool).getAccount(account) returns (
            address _account,
            int256 _index,
            uint256 _withdrawableRewards,
            uint256 _totalRewards,
            uint256 _lastClaimTime) {
            indexForUser=_index;
        } catch {
            indexForUser=-1;
        }
    }

    function getStakePoolByAddress(address pool)
        external
        view
        returns (
            StakePoolOtherInfo memory stakePoolOtherInfo,
            IStakePool.StakeModel memory stakePoolModel
        )
    {
        stakePoolOtherInfo.pool = pool;
        stakePoolModel = getStakeModel(stakePoolOtherInfo.pool);
        stakePoolOtherInfo.totalStakers = IStakePool(stakePoolOtherInfo.pool)
            .getNumberOfStakers();
        stakePoolOtherInfo.owner = IStakePool(stakePoolOtherInfo.pool)
            .stakeOwner();
        stakePoolOtherInfo.totalStaked = IERC20MetadataUpgradeable(
            stakePoolOtherInfo.pool
        ).totalSupply();
        stakePoolOtherInfo.hardCap = ERC20CappedUpgradeable(
            stakePoolOtherInfo.pool
        ).cap();
        stakePoolOtherInfo.stakeToken = IStakePool(stakePoolOtherInfo.pool)
            .stakeToken();
        stakePoolOtherInfo.rewardToken = IStakePool(stakePoolOtherInfo.pool)
            .rewardToken();
        stakePoolOtherInfo.status = IStakePool(stakePoolOtherInfo.pool)
            .status();
        stakePoolOtherInfo.depositAmount = IStakePool(stakePoolOtherInfo.pool)
            .depositAmount();
        stakePoolOtherInfo.totalRewardsDistributed = IStakePool(
            stakePoolOtherInfo.pool
        ).totalRewardsDistributed();
        stakePoolOtherInfo.lastDistributeTime = IStakePool(
            stakePoolOtherInfo.pool
        ).lastDistributeTime();
        stakePoolOtherInfo.name = IERC20MetadataUpgradeable(
            stakePoolOtherInfo.pool
        ).name();
        stakePoolOtherInfo.symbol = IERC20MetadataUpgradeable(
            stakePoolOtherInfo.pool
        ).symbol();
        (stakePoolOtherInfo.is_hide, , ) = IStake(stake).poolModel(
            stakePoolOtherInfo.pool
        );
        stakePoolOtherInfo.stakeTokenDecimals = IERC20MetadataUpgradeable(
            stakePoolOtherInfo.stakeToken
        ).decimals();
        stakePoolOtherInfo.stakeTokenSymbol = IERC20MetadataUpgradeable(
            stakePoolOtherInfo.stakeToken
        ).symbol();
        stakePoolOtherInfo.stakeTokenName = IERC20MetadataUpgradeable(
            stakePoolOtherInfo.stakeToken
        ).name();
        if(stakePoolOtherInfo.rewardToken!=address(0)){
            stakePoolOtherInfo.rewardTokenDecimals = IERC20MetadataUpgradeable(
                stakePoolOtherInfo.rewardToken
            ).decimals();
            stakePoolOtherInfo.rewardTokenSymbol = IERC20MetadataUpgradeable(
                stakePoolOtherInfo.rewardToken
            ).symbol();
            stakePoolOtherInfo.rewardTokenName = IERC20MetadataUpgradeable(
                stakePoolOtherInfo.rewardToken
            ).name();
        }else{
            stakePoolOtherInfo.rewardTokenDecimals = 18;
            stakePoolOtherInfo.rewardTokenSymbol = "NoReward";
            stakePoolOtherInfo.rewardTokenName = "NoReward";
        }   
    }

    function getStakePoolForAccountByAddress(address pool, address account)
        external
        view
        returns (
            int256 indexForUser,
            uint256 withdrawableRewardsForUser,
            uint256 totalRewardsForUser,
            uint256 lastClaimTimeForUser,
            uint256 stakedAmountForUser,
            uint256 stakeDateTimeForUser
        )
    {           
        try IStakePool(pool).getAccount(account) returns (
            address _account,
            int256 _index,
            uint256 _withdrawableRewards,
            uint256 _totalRewards,
            uint256 _lastClaimTime) {
            indexForUser=_index;
            withdrawableRewardsForUser=_withdrawableRewards;
            totalRewardsForUser=_totalRewards;
            lastClaimTimeForUser=_lastClaimTime;
        } catch {
            indexForUser=-1;
            withdrawableRewardsForUser=0;
            totalRewardsForUser=0;
            lastClaimTimeForUser=0;
        }
        stakedAmountForUser=IERC20MetadataUpgradeable(pool).balanceOf(account);
        stakeDateTimeForUser=IStakePool(pool).stakeDateTime(account);
    }

    function getStakeModel(address pool)
        internal
        view
        returns (IStakePool.StakeModel memory stakeModel)
    {
        (
            IStakePool.RewardType rewardType,
            uint256 rewardRatio,
            uint256 startDateTime,
            uint256 endDateTime,
            uint256 minAmountToStake,
            bool transferrable,
            uint256 minPeriodToStake,
            bool canClaimAnyTime,
            uint256 claimDateTime,
            string memory extraData
        ) = IStakePool(pool).stakeModel();
        stakeModel = IStakePool.StakeModel(
            rewardType,
            rewardRatio,
            startDateTime,
            endDateTime,
            minAmountToStake,
            transferrable,
            minPeriodToStake,
            canClaimAnyTime,
            claimDateTime,
            extraData
        );
    }
}