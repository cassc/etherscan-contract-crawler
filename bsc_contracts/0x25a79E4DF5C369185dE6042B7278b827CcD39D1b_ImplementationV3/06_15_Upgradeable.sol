// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract Upgradeable is Ownable, ReentrancyGuard, IERC721Receiver {

    // == VARIABLES == //
    address public collection721;
    address public collection1155;
    address public mintHandler;
    address public buyHandler;
    address public cancelHandler;
    address public adminMintHandler;
    address public recipient;
    address public signer;
    uint64 constant public DAY_TO_SECOND = 86400;
    address public rentHandler;
    uint256 public adminFee;
    address public superAdmin;
    address public rentFeeRecipient;
    
    mapping(address => bool) saleAdminList;
    mapping(address => bool) blackList;
    mapping(address => bool) creatorAdmins;

    mapping(bytes => bool) public invalidSaleOrder;
    mapping(bytes => uint256) public soldQuantityBySaleOrder;   // signature sale order -> sold quantity
    mapping(bytes => uint256) public soldQuantity;              // nftId -> sold quantity
    mapping(bytes => bool) public invalidRentOrder;
    
    mapping(address => bool) public isUser;

    uint256 constant ONE_DAY_IN_SECONDS = 86400;
    uint256 constant ONE_YEAR_IN_SECONDS = 31536000;
    uint256 public totalAmountStaked; // balance of nft and token staked to the pools
    uint256 public totalRewardClaimed; // total reward user has claimed
    uint256 public totalPoolCreated; // total pool created by admin
    uint256 public totalRewardFund; // total pools reward fund
    uint256 public totalUserStaked; // total user has staked to pools
    address public rewardToken; // reward token address
    mapping(bytes => PoolInfo) public poolInfo; // poolId => data: pools info
    mapping(address => uint256) public totalStakedBalancePerUser; // userAddr => amount: total value users staked to the pool
    mapping(address => uint256) public totalRewardClaimedPerUser; // userAddr => amount: total reward users claimed
    mapping(bytes => mapping(address => StakingData)) public tokenStakingData; // poolId => user => token staked data
    mapping(bytes => mapping(address => mapping(uint256 => StakingData))) public nftStaked; // poolId => owner => tokenId => data
    mapping(bytes => mapping(address => uint256)) public stakedBalancePerUser; // poolId => userAddr => amount: total value each user staked to the pool
    mapping(bytes => mapping(address => uint256)) public rewardClaimedPerUser; // poolId => userAddr => amount: reward each user has claimed
    mapping(bytes => mapping(address => uint256)) public totalNftStakedInPool; // poolId => userAddr => amount: totalNftStakedInPool by user 

    address public stakingHandler;
    mapping(uint256 => bytes) tokenStakedIn;
    mapping(uint256 => address) tokenOwnedBy;


    struct StakingData {
        uint256 balance; // staked value
        uint256 stakedTime; // staked time
        uint256 unstakedTime; // unstaked time
        uint256 reward; // the total reward
        uint256 rewardPerTokenPaid; // reward per token paid
        address account; // staked account
    }
    
    struct PoolInfo {
        // address stakingToken; // nft reward token or token staking of the pool
        uint256 stakedAmount; // amount of nfts staked to the pool
        uint256 stakedBalance; // total balance staked the pool
        uint256 totalRewardClaimed; // total reward user has claimed
        uint256 rewardFund; // pool amount for reward token available
        uint256 initialFund; // initial reward fund
        uint256 lastUpdateTime; // last update time
        uint256 rewardPerTokenStored; // reward distributed
        uint256 totalUserStaked; // total user staked
        // uint256 poolType; // 0: nft, 1: token
        uint256 active; // pool activation status, 0: disable, 1: active
        uint256[] configs; // startDate(0), endDate(1), duration(2), endStakeDate(3)
    }



    modifier onlyAdmins() {
        require(
            saleAdminList[msg.sender] || msg.sender == owner() || msg.sender == superAdmin,
            "Implementation: Only admins"
        );
        _;
    }

    modifier notBlocked() {
        require(!blackList[msg.sender], "Implementation: Caller was blocked");
        _;
    }

    modifier notZeroAddress(address _addr) {
        require(_addr != address(0), "Implemenation: Receive a zero address");
        _;
    }

    modifier notCurrentAddress(address _current, address _target) {
        require(
            _target != _current,
            "Implementation: Cannot set to the current address"
        );
        _;
    }

    modifier notAdmins() {
        require(!saleAdminList[msg.sender], "Implementation: Not for sale admins");
        _;
    }

    modifier onlySuperAdmin(){
        require(msg.sender == superAdmin || msg.sender == owner());
        _;
    }


    modifier notUsers(address _addr) {
        require(!isUser[_addr], "Implementation: Not for user");
        _;
    }

    modifier poolExist(bytes memory poolId) {
        require(poolInfo[poolId].initialFund != 0, "Pool is not exist");
        require(poolInfo[poolId].active == 1, "Pool has been disabled");
        _;
    }



    // == EVENTS == //
    event SetSaleAdminEvent(address indexed account, bool value);
    
    event SetSaleAdminsEvent(address[] accounts, bool[] values);
    
    event SetCreatorAdminEvent(address indexed account, bool value);
    
    event SetCreatorAdminsEvent(address[] accounts, bool[] values);

    event SetSignerEvent(address indexed account);

    event SetSuperAdminEvent( address indexed account);

    event SetAdminFeeEvent(uint256 fee);

    event RentNFTEvent(
        uint256 tokenId,
        uint256 totalFee,
        uint256 expDate,
        uint256 startDate,
        address owner,
        address renter,
        bytes transactionId
    );

    event PutUpForRentEvent(
        uint256 tokenId,
        uint256 expDate,
        uint256 startDate,
        uint256 fee,
        address tokenAddress,
        address owner,
        bytes transactionId
    );

    event CancelPutUpForRentEvent(
        uint256 tokenId,
        uint256 expDate,
        uint256 fee,
        address tokenAddress,
        address owner,
        bytes transactionId
    );

    event StakingEvent(
        uint256 amount, 
        address indexed account,
        bytes poolId,
        bytes internalTxID,
        uint256 eventType // (0) stake, (1) unstake(not claim), (2) claimReward (3) unstake(claim)
    );
    
    event PoolUpdated(
        uint256 rewardFund,
        address indexed creator,
        bytes poolId,
        bytes internalTxID,
        uint256 eventType // (0) createPool, (1) updatePool
    );

    // == COMMON FUNCTIONS == //
    function _delegatecall(address _impl) internal virtual {
        require(
            _impl != address(0),
            "Implementation: impl address is zero address"
        );
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(
                sub(gas(), 10000),
                _impl,
                0,
                calldatasize(),
                0,
                0
            )
            let size := returndatasize()
            returndatacopy(0, 0, size)
            switch result
            case 0 {
                revert(0, size)
            }
            default {
                return(0, size)
            }
        }
    }


    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override pure returns (bytes4){
        return this.onERC721Received.selector;
    }
}