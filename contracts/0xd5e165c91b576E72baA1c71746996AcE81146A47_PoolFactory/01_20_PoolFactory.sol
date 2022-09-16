// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "./interfaces/IPoolMaster.sol";
import "./interfaces/IMembershipStaking.sol";
import "./libraries/Decimal.sol";

contract PoolFactory is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCastUpgradeable for uint256;
    using Decimal for uint256;

    /// @notice RBN token contract
    IERC20Upgradeable public rbn;

    /// @notice MembershipStaking contract
    IMembershipStaking public staking;

    /// @notice FlashGovernor contract
    address public flashGovernor;

    /// @notice Address in charge of updating liquidity mining APR. No access to critical vault changes
    address public keeper;

    /// @notice PoolBeacon contract address (used as EIP-1967 beacon for all new pools)
    address public poolBeacon;

    /// @notice Interest Rate Model contract address
    address public interestRateModel;

    /// @notice Address of the auction contract
    address public auction;

    /// @notice Address of the treasury
    address public treasury;

    /// @notice Reserve factor as 18-digit decimal
    uint256 public reserveFactor;

    /// @notice Insurance factor as 18-digit decimal
    uint256 public insuranceFactor;

    /// @notice Pool utilization that leads to warning state (as 18-digit decimal)
    uint256 public warningUtilization;

    /// @notice Pool utilization that leads to provisional default (as 18-digit decimal)
    uint256 public provisionalDefaultUtilization;

    /// @notice Grace period for warning state before pool goes to default (in seconds)
    uint256 public warningGracePeriod;

    /// @notice Max period for which pool can stay not active before it can be closed by governor (in seconds)
    uint256 public maxInactivePeriod;

    /// @notice Period after default to start auction after which pool can be closed by anyone (in seconds)
    uint256 public periodToStartAuction;

    /// @notice Allowance of different currencies in protocol
    mapping(address => bool) public currencyAllowed;

    /// Structure describing information about some manager
    struct ManagerInfo {
        address currency;
        address pool;
        address staker;
        uint32 proposalId;
        uint256 stakedAmount;
        bytes32 ipfsHash;
        string managerSymbol;
    }

    /// @notice Mapping of manager addresses to their manager's info
    mapping(address => ManagerInfo) public managerInfo;

    /// @notice Mapping of manager symbols to flags if they are already used
    mapping(string => bool) public usedManagerSymbols;

    /// @notice Mapping of addresses to flags indicating if they are pools
    mapping(address => bool) public isPool;

    // EVENTS

    /// @notice Event emitted when new pool is created
    /// @param pool Address of the created pool
    /// @param manager Pool's manager
    /// @param currency Pool's currency
    event PoolCreated(
        address indexed pool,
        address indexed manager,
        address indexed currency
    );

    /// @notice Event emitted when pool is closed
    /// @param pool Address of the closed pool
    /// @param manager Pool's manager
    event PoolClosed(address indexed pool, address indexed manager);

    /// @notice Event emitted when pool is transferred to another manager
    /// @param pool Address of the transferred pool
    /// @param oldManager Previous pool's manager
    /// @param newManager New pool's manager
    event PoolTransferred(
        address indexed pool,
        address indexed oldManager,
        address indexed newManager
    );

    /// @notice Event emitted when manager's info is updated
    /// @param manager Address of the manager who's info was updated
    /// @param ipfsHash IPFS hash of new manager's info
    event ManagerInfoSet(address manager, bytes32 ipfsHash);

    /// @notice Event emitted when status of the currency is set
    /// @param currency Address of the currency which status was updated
    /// @param allowed True if currency is allowed, false otherwise
    event CurrencySet(address currency, bool allowed);

    /// @notice Event emitted when new keeper is set
    /// @param newKeeper Address of the new keeper
    event KeeperSet(address newKeeper);

    /// @notice Event emitted when new pool beacon is set
    /// @param newPoolBeacon Address of the new pool beacon contract
    event PoolBeaconSet(address newPoolBeacon);

    /// @notice Event emitted when new interest rate model is set
    /// @param newModel Address of the new IRM contract
    event InterestRateModelSet(address newModel);

    /// @notice Event emitted when new treasury is set
    /// @param newTreasury New treasury address
    event TreasurySet(address newTreasury);

    /// @notice Event emitted when new reserve factor is set
    /// @param factor New reserve factor value
    event ReserveFactorSet(uint256 factor);

    /// @notice Event emitted when new insurance factor is set
    /// @param factor New insurance factor value
    event InsuranceFactorSet(uint256 factor);

    /// @notice Event emitted when new warning utilization is set
    /// @param utilization New warning utilization value
    event WarningUtilizationSet(uint256 utilization);

    /// @notice Event emitted when new provisional default utilization is set
    /// @param utilization New provisional default utilization value
    event ProvisionalDefaultUtilizationSet(uint256 utilization);

    /// @notice Event emitted when new warning grace period is set
    /// @param period New warning grace period value
    event WarningGracePeriodSet(uint256 period);

    /// @notice Event emitted when new max inactive period is set
    /// @param period New max inactive period value
    event MaxInactivePeriodSet(uint256 period);

    /// @notice Event emitted when new period to start auction is set
    /// @param period New period to start auction value
    event PeriodToStartAuctionSet(uint256 period);

    /// @notice Event emitted when new reward per block is set for some pool
    /// @param pool Address of the pool where new reward per block is set
    /// @param rewardPerSecond New reward amount distributed per second in that pool
    event PoolRewardPerSecondSet(address indexed pool, uint256 rewardPerSecond);

    // CONSTRUCTOR

    ///
    /// @notice Upgradeable contract constructor
    /// @param rbn_ The address of the RBN contract
    /// @param staking_ The address of the Staking contract
    /// @param poolBeacon_ The address of the PoolBeacon contract
    /// @param interestRateModel_ The address of the InterestRateModel contract
    /// @param auction_ The address of the Auction contract
    function initialize(
        IERC20Upgradeable rbn_,
        IMembershipStaking staking_,
        address poolBeacon_,
        address interestRateModel_,
        address auction_
    ) external initializer {
        require(address(rbn_) != address(0), "AIZ");
        require(address(staking_) != address(0), "AIZ");
        require(poolBeacon_ != address(0), "AIZ");
        require(interestRateModel_ != address(0), "AIZ");
        require(auction_ != address(0), "AIZ");

        __Ownable_init();

        rbn = rbn_;
        staking = staking_;
        poolBeacon = poolBeacon_;
        interestRateModel = interestRateModel_;
        auction = auction_;
    }

    // PUBLIC FUNCTIONS

    /// @notice Function used to immedeately create new pool for some manager for the first time
    /// @param manager Manager of the pool
    /// @param currency Currency of the pool
    /// @param ipfsHash IPFS hash of the manager's info
    /// @param managerSymbol Manager's symbol
    function createPoolInitial(
        address manager,
        address currency,
        bytes32 ipfsHash,
        string memory managerSymbol
    ) external onlyOwner {
        _setManager(manager, ipfsHash, managerSymbol);
        _createPool(manager, currency);
    }

    /// @notice Function used to immediately create new pool for some manager (when info already exist)
    /// @param manager Manager of the pool
    /// @param currency Currency of the pool
    function createPool(address manager, address currency) external onlyOwner {
        require(managerInfo[manager].ipfsHash != bytes32(0), "MHI");
        _createPool(manager, currency);
    }

    /// @notice Function used to transfer existing pool to another manager
    /// @param oldManager Manager who owns pool now
    /// @param newManager Manager to transfer pool to
    function transferPool(address oldManager, address newManager)
        external
        onlyOwner
    {
        require(managerInfo[oldManager].pool != address(0), "NAP");
        require(managerInfo[newManager].pool == address(0), "AHP");

        managerInfo[newManager] = managerInfo[oldManager];
        delete managerInfo[oldManager];

        IPoolMaster(managerInfo[newManager].pool).setManager(newManager);

        emit PoolTransferred(
            managerInfo[newManager].pool,
            oldManager,
            newManager
        );
    }

    /// @notice Function used to update manager's info IPFS hash
    /// @param manager Manager to update
    /// @param ipfsHash New info IPFS hash
    function setManagerInfo(address manager, bytes32 ipfsHash)
        external
        onlyOwner
    {
        managerInfo[manager].ipfsHash = ipfsHash;
        emit ManagerInfoSet(manager, ipfsHash);
    }

    /// @notice Function is called by contract owner to update currency allowance in the protocol
    /// @param currency Address of the ERC20 token
    /// @param allowed Should currency be allowed or forbidden
    function setCurrency(address currency, bool allowed) external onlyOwner {
        currencyAllowed[currency] = allowed;
        emit CurrencySet(currency, allowed);
    }

    /// @notice Function is called by contract owner to set new keeper
    /// @param keeper_ New keeper address
    function setKeeper(address keeper_) external onlyOwner {
        require(keeper_ != address(0), "AIZ");
        keeper = keeper_;
        emit KeeperSet(keeper_);
    }

    /// @notice Function is called by contract owner to set new pool beacon
    /// @param poolBeacon_ New pool beacon contract address
    function setPoolBeacon(address poolBeacon_) external onlyOwner {
        require(poolBeacon_ != address(0), "AIZ");
        poolBeacon = poolBeacon_;
        emit PoolBeaconSet(poolBeacon_);
    }

    /// @notice Function is called by contract owner to set new InterestRateModel
    /// @param interestRateModel_ Address of the new InterestRateModel contract
    function setInterestRateModel(address interestRateModel_)
        external
        onlyOwner
    {
        require(interestRateModel_ != address(0), "AIZ");
        interestRateModel = interestRateModel_;
        emit InterestRateModelSet(interestRateModel_);
    }

    /// @notice Function is called by contract owner to set new treasury
    /// @param treasury_ Address of the new treasury
    function setTreasury(address treasury_) external onlyOwner {
        require(treasury_ != address(0), "AIZ");
        treasury = treasury_;
        emit TreasurySet(treasury_);
    }

    /// @notice Function is called by contract owner to set new reserve factor
    /// @param reserveFactor_ New reserve factor as 18-digit decimal
    function setReserveFactor(uint256 reserveFactor_) external onlyOwner {
        require(reserveFactor_ <= Decimal.ONE, "GTO");
        reserveFactor = reserveFactor_;
        emit ReserveFactorSet(reserveFactor_);
    }

    /// @notice Function is called by contract owner to set new insurance factor
    /// @param insuranceFactor_ New reserve factor as 18-digit decimal
    function setInsuranceFactor(uint256 insuranceFactor_) external onlyOwner {
        require(insuranceFactor_ <= Decimal.ONE, "GTO");
        insuranceFactor = insuranceFactor_;
        emit InsuranceFactorSet(insuranceFactor_);
    }

    /// @notice Function is called by contract owner to set new warning utilization
    /// @param warningUtilization_ New warning utilization as 18-digit decimal
    function setWarningUtilization(uint256 warningUtilization_)
        external
        onlyOwner
    {
        require(warningUtilization_ <= Decimal.ONE, "GTO");
        warningUtilization = warningUtilization_;
        emit WarningUtilizationSet(warningUtilization_);
    }

    /// @notice Function is called by contract owner to set new provisional default utilization
    /// @param provisionalDefaultUtilization_ New provisional default utilization as 18-digit decimal
    function setProvisionalDefaultUtilization(
        uint256 provisionalDefaultUtilization_
    ) external onlyOwner {
        require(provisionalDefaultUtilization_ <= Decimal.ONE, "GTO");
        provisionalDefaultUtilization = provisionalDefaultUtilization_;
        emit ProvisionalDefaultUtilizationSet(provisionalDefaultUtilization_);
    }

    /// @notice Function is called by contract owner to set new warning grace period
    /// @param warningGracePeriod_ New warning grace period in seconds
    function setWarningGracePeriod(uint256 warningGracePeriod_)
        external
        onlyOwner
    {
        warningGracePeriod = warningGracePeriod_;
        emit WarningGracePeriodSet(warningGracePeriod_);
    }

    /// @notice Function is called by contract owner to set new max inactive period
    /// @param maxInactivePeriod_ New max inactive period in seconds
    function setMaxInactivePeriod(uint256 maxInactivePeriod_)
        external
        onlyOwner
    {
        maxInactivePeriod = maxInactivePeriod_;
        emit MaxInactivePeriodSet(maxInactivePeriod_);
    }

    /// @notice Function is called by contract owner to set new period to start auction
    /// @param periodToStartAuction_ New period to start auction
    function setPeriodToStartAuction(uint256 periodToStartAuction_)
        external
        onlyOwner
    {
        periodToStartAuction = periodToStartAuction_;
        emit PeriodToStartAuctionSet(periodToStartAuction_);
    }

    /// @notice Function is called by keeper to set new RBN reward per second speed in some pool
    /// @param pool Pool where to set reward
    /// @param rewardPerSecond Reward per block value
    function setPoolRewardPerSecond(address pool, uint256 rewardPerSecond)
        external
    {
        require(msg.sender == keeper, "!keeper");
        IPoolMaster(pool).setRewardPerSecond(rewardPerSecond);
        emit PoolRewardPerSecondSet(pool, rewardPerSecond);
    }

    /// @notice Function is used to withdraw any ERC20 token from contract
    /// @param token Address of token to withdraw
    /// @param to Address where to transfer
    /// @param amount Amount to transfer
    function sweep(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20Upgradeable(token).safeTransfer(to, amount);
    }

    /// @notice Function is called through pool at closing to unlock manager's stake
    function closePool() external {
        require(isPool[msg.sender], "SNP");
        address manager = IPoolMaster(msg.sender).manager();
        ManagerInfo storage info = managerInfo[manager];

        info.pool = address(0);
        staking.unlockAndWithdrawStake(info.staker, manager, info.stakedAmount);

        emit PoolClosed(msg.sender, manager);
    }

    /// @notice Function is called through pool to burn manager's stake when auction starts
    function burnStake() external {
        require(isPool[msg.sender], "SNP");
        ManagerInfo storage info = managerInfo[
            IPoolMaster(msg.sender).manager()
        ];

        staking.burnStake(info.staker, info.stakedAmount);
        info.staker = address(0);
        info.stakedAmount = 0;
    }

    /// @notice Function is used to withdraw RBN rewards from multiple pools
    /// @param pools List of pools to withdrawm from
    function withdrawReward(address[] memory pools) external {
        uint256 totalReward;
        for (uint256 i = 0; i < pools.length; i++) {
            require(isPool[pools[i]], "NPA");
            totalReward += IPoolMaster(pools[i]).withdrawReward(msg.sender);
        }

        if (totalReward > 0) {
            rbn.safeTransfer(msg.sender, totalReward);
        }
    }

    // VIEW FUNCTIONS

    /// @notice Function returns symbol for new pool based on currency and manager
    /// @param currency Pool's currency address
    /// @param manager Manager's address
    /// @return Pool symbol
    function getPoolSymbol(address currency, address manager)
        external
        view
        returns (string memory)
    {
        return
            string(
                bytes.concat(
                    bytes("r"),
                    bytes(managerInfo[manager].managerSymbol),
                    bytes("-"),
                    bytes(IERC20MetadataUpgradeable(currency).symbol())
                )
            );
    }

    // INTERNAL FUNCTIONS

    /// @notice Internal function that creates pool
    /// @param manager Manager of the pool
    /// @param currency Currency of the pool
    function _createPool(address manager, address currency) private {
        require(currencyAllowed[currency], "CNA");
        ManagerInfo storage info = managerInfo[manager];
        require(info.pool == address(0), "AHP");

        IPoolMaster pool = IPoolMaster(
            address(new BeaconProxy(poolBeacon, ""))
        );
        pool.initialize(manager, currency);
        info.pool = address(pool);
        info.staker = msg.sender;
        info.stakedAmount = staking.lockStake(msg.sender);
        isPool[address(pool)] = true;

        emit PoolCreated(address(pool), manager, currency);
    }

    /// @notice Internal function that sets manager's info
    /// @param manager Manager to set info for
    /// @param info Manager's info IPFS hash
    /// @param symbol Manager's symbol
    function _setManager(
        address manager,
        bytes32 info,
        string memory symbol
    ) private {
        require(managerInfo[manager].ipfsHash == bytes32(0), "AHI");
        require(info != bytes32(0), "CEI");
        require(!usedManagerSymbols[symbol], "SAU");

        managerInfo[manager].ipfsHash = info;
        managerInfo[manager].managerSymbol = symbol;
        usedManagerSymbols[symbol] = true;
    }
}