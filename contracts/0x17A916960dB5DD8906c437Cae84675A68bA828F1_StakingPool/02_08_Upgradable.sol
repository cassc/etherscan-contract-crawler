// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract Upgradable {
    mapping(address => bool) adminList; // admin list for updating pool
    mapping(address => bool) blackList; // blocked users
    uint256 constant ONE_YEAR_IN_SECONDS = 31536000;
    uint256 constant ONE_DAY_IN_SECONDS = 86400;
    uint256 public totalAmountStaked; // balance of nft and token staked to the pools
    uint256 public totalRewardClaimed; // total reward user has claimed
    uint256 public totalPoolCreated; // total pool created by admin
    uint256 public totalRewardFund; // total pools reward fund
    uint256 public totalUserStaked; // total user has staked to pools
    mapping(string => PoolInfo) public poolInfo; // poolId => data: pools info
    mapping(address => uint256) public totalStakedBalancePerUser; // userAddr => amount: total value users staked to the pool
    mapping(address => uint256) public totalRewardClaimedPerUser; // userAddr => amount: total reward users claimed
    mapping(string => mapping(address => StakingData)) public tokenStakingData; // poolId => user => token staked data
    mapping(string => mapping(address => uint256)) public stakedBalancePerUser; // poolId => userAddr => amount: total value each user staked to the pool
    mapping(string => mapping(address => uint256)) public rewardClaimedPerUser; // poolId => userAddr => amount: reward each user has claimed
    address public controller;
    mapping(string => mapping(address => mapping(uint256 => uint256))) public rewardNFT1155pPerPool; // poolId => tokenAddress =>  tokenId => amount: reward NFT in pool 
    mapping(string => mapping(address => mapping(uint256 => uint256))) public rewardNFT721pPerPool; //poolId => tokenAddress => tokenId =>amount: reward NFT in pool 
    mapping(bytes => bool) public invalidSignature; //signature => true/false : check invalid signature
    address public signer;
    string amountInvalid = "Amount is invalid";

    /*================================ MODIFIERS ================================*/
    
    modifier onlyAdmins() {
        require(adminList[msg.sender] || msg.sender == controller, "Only admins");
        _;
    }
    
    modifier poolExist(string memory poolId) {
        require(poolInfo[poolId].initialFund != 0, "Pool is not exist");
        require(poolInfo[poolId].active == 1, "Pool has been disabled");
        _;
    }

    modifier notBlocked() {
        require(!blackList[msg.sender], "Caller has been blocked");
        _;
    }

    modifier onlyController() {
        require(msg.sender == controller, "Only controller");
        _;
    }
    
    /*================================ EVENTS ================================*/
    // infoBeforeAndAfter: rewardPerTokenPaidBefore, rewardPerTokenStoredBefore, rewardPerTokenStoredAfter, poolLastUpdateTime
    // strs: PoolID, internalTxID
    event StakingEvent(
        uint256 amount,
        address indexed account,
        string poolId,
        string internalTxId,
        uint256[] infoBeforeAndAfter
    );
    
    event PoolUpdated(
        uint256 rewardFund,
        address indexed creator,
        string poolId,
        string internalTxID
    );

    event AdminSet(
        address indexed admin,
        bool isSet
    );

    event BlacklistSet(
        address indexed user,
        bool isSet
    );

    event PoolActivationSet(
        address indexed admin,
        string poolId,
        uint256 isActive
    );

    event ControllerTransferred(
        address indexed previousController, 
        address indexed newController
    );

    event ClaimRewardNFT(
        address tokenAddress,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        string poolId,
        string internalTxID
    );

    event DepositNFT(
        address tokenAddress,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        string poolId,
        string internalTxID
    );

    event WithdrawNFT(
        address tokenAddress,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        string poolId,
        string internalTxID
    );

    event StopPool(
        string poolId
    );
    // infoBeforeAndAfter: rewardPerTokenPaidBefore, rewardPerTokenStoredBefore, rewardPerTokenStoredAfter, poolLastUpdateTime
    // strs: PoolID, internalTxID
    event UnStakingEvent( 
        uint256 amount,
        address indexed account,
        string poolId,
        string internalTxId,
        uint256[] infoBeforeAndAfter
    );
    // infoBeforeAndAfter: rewardPerTokenPaidBefore, rewardPerTokenStoredBefore, rewardPerTokenStoredAfter, poolLastUpdateTime
    event ClaimTokenEvent( 
        uint256 amount,
        address indexed account,
        string poolId,
        string internalTxId,
        uint256[] infoBeforeAndAfter
    );
    
    /*================================ STRUCTS ================================*/
     
    struct StakingData {
        uint256 balance; // staked value
        uint256 stakedTime; // staked time
        uint256 unstakedTime; // unstaked time
        uint256 reward; // the total reward
        uint256 rewardPerTokenPaid; // reward per token paid
        address account; // staked account
    }
    
    struct PoolInfo {
        address stakingToken; // token staking of the pool
        address rewardToken; //  reward token of  the pool
        uint256 stakedBalance; // total balance staked the pool
        uint256 totalRewardClaimed; // total reward user has claimed
        uint256 rewardFund; // pool amount for reward token available
        uint256 initialFund; // initial reward fund
        uint256 lastUpdateTime; // last update time
        uint256 rewardPerTokenStored; // reward distributed
        uint256 totalUserStaked; // total user staked
        uint256 active; // pool activation status, 0: disable, 1: active
        uint256[] configs; // startDate(0), endDate(1), duration(2), endStakeDate(3), stakingLimit(4),stopPool(5), exchangeRateRewardToStaking(6),
        uint256 typePool; // 0: pool tokenReward, 1: pool tokenReward and NFT reward
        uint256 pool; // 0: poolAlowcation, 1: poolLinear;
        uint256 apr; //annual percentage rate
    }
}