// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../common/Storage.sol";
import "../interfaces/IBetting.sol";
import "../interfaces/IProxy.sol";
import "hardhat/console.sol";

contract BettingAdmin is Storage, UUPSUpgradeable, AccessControlUpgradeable {
    IERC20Upgradeable public erc20Contract;
    // Vault contract address where unclaimed winnings and payouts will be transferred for insurance
    address public vaultContract;

    // Array of all pools
    Pool[] public pools;
    // Array of all bets
    Bet[] public bets;

    // Mapping from poolid -> Teams in a pool
    mapping(uint256 => Team[]) public poolTeams;
    // Address used to sign commission amount for the user
    // Off-chain commission calculated is signed by this address so that user cannot claim more than they are eligible
    address public signer;

    // Address of main betting contract
    IBetting public betting;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MULTISIG_ROLE = keccak256("MULTISIG_ROLE");

    // Mapping from poolid -> bet indexes placed against this pool
    mapping (uint256 => uint256[]) public poolBets;

    // Mapping from poolstatus -> poolId. Used to filter pools based on status
    mapping(uint256 => uint256) public poolStatus;

    IProxy public proxy;

    bytes32 public constant GAME_ADMIN_ROLE = keccak256("GAME_ADMIN_ROLE");

    event PoolCreated(uint256 indexed poolId, uint256 numberOfTeams, uint256 startTime);
    event PoolCanceled(uint256 indexed poolId);
    event PoolStarted(uint256 indexed poolId);
    event PoolClosed(uint256 indexed poolId);
    event PoolGraded(uint256 indexed poolId, uint256[] winnerId);
    event PoolStateUpdated(uint256 indexed poolId_, uint256 indexed status_);

    event CommissionTransferredToVault(uint256 indexed poolId, uint256 amount);
    event PayoutTransferredToVault(uint256 indexed poolId, uint256 amount);

    event TeamAdded(uint256 indexed poolId, uint256 teamId);
    event TeamRemoved(uint256 indexed poolId, uint256 teamId);

    // poolId should be > 0 and less than total number of pools
    modifier validPool(uint256 poolId_) {
        require(poolId_ >= 0 && poolId_ < pools.length, "BettingAdmin: Id is not valid");
        _;
    }

    // Checks if status of pool matches required status
    modifier validStatus(uint256 status_, uint256 requiredStatus_) {
        require(status_ == requiredStatus_, "BettingAdmin: pool status does not match");
        _;
    }

    modifier onlyBetting() {
        require(msg.sender == address(betting), "BettingAdmin: Only betting contract is authorized for this operation");
        _;
    }

    // Initializes initial contract state
    // Since we are using UUPS proxy, we cannot use contructor instead need to use this
    function initialize(address erc20Contract_, address vaultContract_, address signer_, address proxy_) public initializer {
        __UUPSUpgradeable_init();

        require(erc20Contract_ != address(0), "BettingAdmin: erc20Contract cannot be zero");
        require(vaultContract_ != address(0), "BettingAdmin: vaultContract cannot be zero");
        require(signer_ != address(0), "BettingAdmin: signer cannot be zero");
        require(proxy_ != address(0), "BettingAdmin: proxy cannot be zero");

        erc20Contract = IERC20Upgradeable(erc20Contract_);
        vaultContract = vaultContract_;
        signer = signer_;
        proxy = IProxy(proxy_);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Allow only admins to perform a future upgrade to the contract
    function _authorizeUpgrade (address newImplementation) internal virtual override onlyRole(ADMIN_ROLE) {

    }

    // Allows admin to create a new pool
    function createPool(uint256 numberOfTeams_, string memory eventName_, uint256 startTime_, uint256 duration_, string[] memory teams_, string memory uri_) external onlyRole(GAME_ADMIN_ROLE) {
        uint256 poolId = pools.length;
        require(teams_.length == numberOfTeams_, "BettingAdmin: Mismatching teams and numberOfTeams");

        address _mint = proxy.createClone(keccak256(abi.encodePacked(poolId)));
        require(_mint != address(0), "BettingAdmin: Could not create mint");
        IERC1155PresetMinterPauser erc1155 = IERC1155PresetMinterPauser(_mint);
        erc1155.initialize(msg.sender, address(betting), uri_);

        uint256[] memory _winners;
        pools.push(Pool(poolId, numberOfTeams_, eventName_, 0, 0, 0, 0, 0, PoolStatus.Created, _winners, startTime_, startTime_ + duration_, erc1155, false, false));

        for (uint256 i = 0; i < numberOfTeams_; ++i) {
            poolTeams[poolId].push(Team(i, teams_[i], TeamStatus.Created, 0));
        }

        emit PoolCreated(poolId, numberOfTeams_, startTime_);
    }

    // Allows admin to cancel a pool making all pool proceeds including commission to be eligible for refund
    function cancelPool(uint256 poolId_) external onlyRole(MULTISIG_ROLE) validPool(poolId_) {
        Pool storage pool = pools[poolId_];
        require(pool.status == PoolStatus.Created || pool.status == PoolStatus.Running, "BettingAdmin: Pool status should be Created or Running");

        pool.status = PoolStatus.Canceled;

        emit PoolCanceled(poolId_);
    }

    // Allows admin to start a pool
    function startPool(uint256 poolId_) external onlyRole(MULTISIG_ROLE) validPool(poolId_) {
        Pool storage pool = pools[poolId_];
        require(pool.status == PoolStatus.Created, "BettingAdmin: Pool status should be Created");

        pool.status = PoolStatus.Running;

        emit PoolStarted(poolId_);
    }

    // Allows admin to close a pool
    function closePool(uint256 poolId_) external onlyRole(MULTISIG_ROLE) validPool(poolId_) {
        Pool storage pool = pools[poolId_];
        require(pool.status == PoolStatus.Running, "BettingAdmin: Pool status should be Running");

        pool.status = PoolStatus.Closed;

        emit PoolClosed(poolId_);
    }

    // Allows admin to decide winner of a pool. More than 1 winners can be in case of a tie/washout.
    function gradePool(uint256 poolId_, uint256 winnerId_) external onlyRole(MULTISIG_ROLE) validPool(poolId_) {
        Pool storage pool = pools[poolId_];
        require(pool.status == PoolStatus.Closed || pool.status == PoolStatus.Running, "BettingAdmin: Pool status should be Running or Closed");
        require(poolTeams[poolId_][winnerId_].status == TeamStatus.Created, "BettingAdmin: Team status should be Created");

        // Mark pool as closed
        pool.status = PoolStatus.Decided;
        pool.winners.push(winnerId_);

        emit PoolGraded(poolId_, pool.winners);
    }

    // Allows admin to decide more than one winners of a pool. More than 1 winners can be in case of a tie/washout.
    function markPoolTie(uint256 poolId_, uint256[] memory winnerIds_) external onlyRole(MULTISIG_ROLE) validPool(poolId_) {
        Pool storage pool = pools[poolId_];
        require(pool.status == PoolStatus.Closed || pool.status == PoolStatus.Running, "BettingAdmin: Pool status should be Running or Closed");
        require(winnerIds_.length > 0, "BettingAdmin: Should specify atleast one winner");

        // Mark pool as closed
        pool.status = PoolStatus.Decided;
        pool.winners = winnerIds_;

        emit PoolGraded(poolId_, pool.winners);
    }

    // Allows admin to transfer unclaimed commission to insurance vault
    function transferCommissionToVault(uint256 poolId_) external onlyRole(MULTISIG_ROLE) validPool(poolId_) {
        Pool storage pool = pools[poolId_];
        require(pool.status == PoolStatus.Decided, "BettingAdmin: Pool status should be Decided");
        require((pool.endTime + 30 days) < block.timestamp, "BettingAdmin: Cannot transfer before 30 days deadline");

        uint256 _unclaimedCommission = pool.totalCommissions - pool.commissionsClaimed;
        require(_unclaimedCommission > 0, "BettingAdmin: No commission available to transfer");
        require(!pool.commissionDisabled, "BettingAdmin: Commission already transferred");

        betting.transferCommissionToVault(_unclaimedCommission);
        pool.commissionDisabled = true;

        emit CommissionTransferredToVault(poolId_, _unclaimedCommission);
    }

    // Allows admin to transfer unclaimed payout to insurance vault
    function transferPayoutToVault(uint256 poolId_) external onlyRole(MULTISIG_ROLE) validPool(poolId_) {
        Pool storage pool = pools[poolId_];
        require(pool.status == PoolStatus.Decided, "BettingAdmin: Pool status should be Decided");
        require((pool.endTime + 90 days) < block.timestamp, "BettingAdmin: Cannot transfer before 90 days deadline");

        uint256 _unclaimedPayout = pool.totalAmount - pool.payoutClaimed;
        require(_unclaimedPayout > 0, "BettingAdmin: No payout available to transfer");
        require(!pool.paymentDisabled, "BettingAdmin: Payout already transferred");

        betting.transferPayoutToVault(_unclaimedPayout);
        pool.paymentDisabled = true;

        emit PayoutTransferredToVault(poolId_, _unclaimedPayout);
    }

    // Allows admin to update start time and duration of a pool
    function updateStartTime(uint256 poolId_, uint256 startTime_, uint256 duration_) external onlyRole(MULTISIG_ROLE) validPool(poolId_) {
        Pool storage pool = pools[poolId_];
        require(pool.status == PoolStatus.Created || pool.status == PoolStatus.Running, "BettingAdmin: Pool status should be Created or Running");

        pool.startTime = startTime_;
        pool.endTime = startTime_ + duration_;
    }

    // Allows admin to update signer address
    function updateVeraSignerAddress(address signer_)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(signer_ != address(0), "BettingAdmin: Zero Signer address");
        signer = signer_;
    }

    // Allows admin to update usdc contract address
    function updateerc20Contract(address erc20Contract_)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(erc20Contract_ != address(0), "BettingAdmin: Zero erc20Contract address");
        erc20Contract = IERC20Upgradeable(erc20Contract_);
    }

    // Allows admin to update vault contract address
    function updateVaultContract(address vaultContract_)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(vaultContract_ != address(0), "BettingAdmin: Zero vaultContract address");
        vaultContract = vaultContract_;
    }

    // Allows admin to update vault contract address
    function updateBettingAddress(address betting_)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(betting_ != address(0), "BettingAdmin: Zero betting address");
        betting = IBetting(betting_);
    }

    // Allows admin to update proxy address
    function updateProxyAddress(address proxy_)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(proxy_ != address(0), "BettingAdmin: Zero proxy address");
        proxy = IProxy(proxy_);
    }

    function betPlaced(address player_, uint256 poolId_, uint256 teamId_, uint256 amount_, uint256 commission_) external onlyBetting returns (bool) {
        Pool storage pool = pools[poolId_];

        // Update pool statistics
        pool.totalAmount += amount_;
        pool.totalBets += 1;
        pool.totalCommissions += commission_;

        poolTeams[poolId_][teamId_].totalAmount += amount_;
        return true;
    }

    function payoutClaimed(address player_, uint256 poolId_, uint256 amount_) external onlyBetting returns (bool) {
        Pool storage pool = pools[poolId_];
        pool.payoutClaimed += amount_;

        return true;
    }

    function commissionClaimed(address player_, uint256 poolId_, uint256 amount_) external onlyBetting returns (bool) {
        Pool storage pool = pools[poolId_];
        pool.commissionsClaimed += amount_;

        return true;
    }

    function refundClaimed(address player_, uint256 poolId_, uint256 amount_) external onlyBetting returns (bool) {

    }

    // Returns all teams of a pool
    function getPoolTeams(uint256 poolId_) external view returns(Team[] memory) {
        return poolTeams[poolId_];
    }

    function getTotalPools() external view returns(uint256) {
        return pools.length;
    }

    function getPool(uint256 poolId_) external view returns (Pool memory) {
        return pools[poolId_];
    }

    // Returns all teams of a pool
    function getPoolTeam(uint256 poolId_, uint256 teamId_) external view returns(Team memory) {
        return poolTeams[poolId_][teamId_];
    }
}