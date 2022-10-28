// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract Upgradable {
    uint256 constant ONE_DAY_IN_SECONDS = 86400;
    address public nftToken; // contract address of NFTToken
    address public controller;
    address public signer;
    address public signatureUtils;
    mapping(address => uint256) public adminList; // 1: admin, 3: controller
    mapping(uint256 => FNFTInfo) public fnftInfos;
    mapping(uint256 => FNFTPool) public fnftPools;
    mapping(uint256 => TierPool) public tierPools;
    mapping(uint256 => RewardPool) public rewardPools;
    mapping(uint256 => mapping(address => UserInfo)) public userInfos;
    mapping(address => uint256) public stakingBalances;
    mapping(bytes => uint256) public nonceSignatures;
    
    /// --------------------------------
    /// -------- MODIFIERS --------
    /// --------------------------------

    modifier onlyController() {
        require(msg.sender == controller || adminList[msg.sender] == 3, "NFTFractional: Only controller");
        _;
    }

    modifier notEmpty(string memory _value) {
        require(bytes(_value).length > 0, "NFTFractional: Not Empty");
        _;
    }

    modifier onlyAdmins() {
        require(msg.sender == controller || adminList[msg.sender] == 1 || adminList[msg.sender] == 3, "NFTFractional: Only controller and admins");
        _;
    }

    modifier checkTierIndex(uint256[] memory tiers, uint256 _index) {
        require(tiers.length > _index, "NFTFractional: Invalid tier index");
        _;
    }

    modifier isFractionalizedNFT(uint256 id) {
        require(fnftInfos[id].totalSupply == 0, "NFT fractionalized");
        _;
    }

    /// --------------------------------
    /// -------- EVENTS --------
    /// --------------------------------

    event AdminSet(
        address indexed admin,
        uint256 isSet
    );

    event MintNFT(
        address indexed _nftToken,
        address indexed _receiver,
        uint256 _tokenId
    );

    event ControllerTransferred(
        address indexed previousController, 
        address indexed newController
    );

    event FractionalizeNFT(
        address indexed _tokenNFT,
        address indexed _tokenFNFT,
        address indexed _curator,
        uint256 _totalSupply,
        uint256 _tokenId,
        string _symbol,
        string _name
    );

    event CreateFNFTPool(
        address _acceptToken,
        address _receiveAddress,
        uint256 _poolId,
        uint256 _fnftId,
        uint256 _poolBalance,
        uint256 _active // pool activation status, 0: disable, 1: active
    );

    event CreateTierPool(
        address _stakingToken,
        uint256 _poolId,
        uint256 _lockDuration,
        uint256 _withdrawDelayDuration
    );

    event CreateRewardPool(
        address _rewardToken,
        uint256 _rewardPoolId,
        uint256 _fnftPoolId,
        uint256 _totalRewardAmount,
        uint256 _poolOpenTime,
        uint256 _active
    );

    event StakeTierPool(
        address account,
        uint256 poolId,
        uint256 amount 
    );

    event UnStakeTierPool(
        address account,
        uint256 poolId,
        uint256 amount 
    );

    event PurchaseFNFT(
        uint256 poolId,
        uint256 purchased,
        uint256 remaining,
        uint256 purchasedFNFT,
        address account,
        string purchaseId
    );

    event ClaimReward(
        uint256 poolId,
        uint256 amountFNFT,
        uint256 remaining,
        uint256 rewardUSDT,
        address account,
        string claimId
    );

    event WithdrawFun(
        uint256 poolId,
        uint256 amount,
        address token,
        address account
    );

    /// --------------------------------
    /// -------- STRUCT --------
    /// --------------------------------

    struct FNFTInfo {
        uint256 id;
        uint256 totalSupply;
        uint256 availableSupply;
        address curator;
        address tokenNFT;
        address tokenFNFT;
    }

    struct FNFTPool {
        address acceptToken;
        address receiveAddress;
        uint256 poolId;
        uint256 fnftId;
        uint256 poolBalance;
        uint256 availableBalance;
        uint256 active; // pool activation status, 0: disable, 1: active
        uint256 poolType; // 1: tiered, 2: FCFS
        uint256[] configs; // registrationStartTime(0), registrationEndTime(1), purchaseStartTime(2), purchaseEndTime(3)
    }

    struct TierPool {
        address stakingToken; // staking token of the pool
        uint256 stakedBalance; // total balance staked the pool
        uint256 totalUserStaked; // total user staked
        uint256 lockDuration;
        uint256 withdrawDelayDuration;
        uint256 active;
    }

    struct RewardPool {
        address rewardToken;
        uint256 fnftPoolId;
        uint256 totalRewardAmount;
        uint256 poolOpenTime;
        uint256 active;
    }

    struct UserInfo {
        uint256 alloction;
        uint256 purchased;
        uint256 stakeBalance;
        uint256 stakeLastTime;
        uint256 unStakeLastTime;
        uint256 pendingWithdraw;
    }

}