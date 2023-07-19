// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeCastUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {IPoolMaster} from "./interfaces/IPoolMaster.sol";
import {IQuadReader} from "@quadrata/contracts/interfaces/IQuadReader.sol";
import {IQuadPassportStore} from "@quadrata/contracts/interfaces/IQuadPassportStore.sol";
import {IMembershipStaking} from "./interfaces/IMembershipStaking.sol";
import {Decimal} from "./libraries/Decimal.sol";

contract PoolFactory is OwnableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using SafeCastUpgradeable for uint256;
  using Decimal for uint256;

  /// @notice CPOOL token contract
  IERC20Upgradeable public cpool;

  /// @notice MembershipStaking contract
  IMembershipStaking public staking;

  /// @notice Variable is not in use anymore, but we keep it to prevent storage slot collisions
  address private _removedInternal;

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

  /// @notice List of active pools
  address[] public pools;

  /// @notice Mapping of markets to their open pool addresses
  mapping(address => address[]) public marketPools;

  /// @notice Quadrata reader contract instance
  IQuadReader public quadrataReader;

  /// @notice Pool utilization that to what borrower should repay after entering provisionalDefaultUtilization (as 18-digit decimal)
  uint256 public provisionalRepaymentUtilization;

  // EVENTS

  /// @notice Event emitted when new pool is created
  /// @param pool Address of the created pool
  /// @param manager Pool's manager
  /// @param currency Pool's currency
  event PoolCreated(address indexed pool, address indexed manager, address indexed currency);

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

  /// @notice Event emitted when new pool beacon is set
  /// @param newPoolBeacon Address of the new pool beacon contract
  event PoolBeaconSet(address newPoolBeacon);

  /// @notice Event emitted when new auction is set
  /// @param newAuction Address of the new auction contract
  event AuctionSet(address newAuction);

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

  /// @notice Event emitted when new provisional repayment utilization is set
  /// @param utilization New provisional repayment utilization value
  event ProvisionalRepaymentUtilizationSet(uint256 utilization);

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

  /// @notice Event emitted when new quadrata contract address is set
  /// @param newReader Address of the new quadrata contract
  event QuadrataReaderSet(address newReader);

  // CONSTRUCTOR

  ///
  /// @notice Upgradeable contract constructor
  /// @param cpool_ The address of the CPOOL contract
  /// @param staking_ The address of the Staking contract
  /// @param poolBeacon_ The address of the PoolBeacon contract
  /// @param interestRateModel_ The address of the InterestRateModel contract
  /// @param auction_ The address of the Auction contract
  function initialize(
    IERC20Upgradeable cpool_,
    IMembershipStaking staking_,
    address poolBeacon_,
    address interestRateModel_,
    address auction_
  ) external initializer {
    require(address(cpool_) != address(0), "AIZ");
    require(address(staking_) != address(0), "AIZ");
    require(poolBeacon_ != address(0), "AIZ");
    require(interestRateModel_ != address(0), "AIZ");
    require(auction_ != address(0), "AIZ");

    __Ownable_init();

    cpool = cpool_;
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
  /// @param requireKYC Flag to enable KYC middleware for pool actions
  function createPoolInitial(
    address manager,
    address currency,
    bytes32 ipfsHash,
    string memory managerSymbol,
    bool requireKYC
  ) external onlyOwner notZeroAddress(manager) notZeroAddress(currency) {
    _setManager(manager, ipfsHash, managerSymbol);
    _createPool(manager, currency, requireKYC);
  }

  /// @notice Function used to immediately create new pool for some manager (when info already exist)
  /// @param manager Manager of the pool
  /// @param currency Currency of the pool
  /// @param requireKYC Flag to enable KYC middleware for pool actions
  function createPool(
    address manager,
    address currency,
    bool requireKYC
  ) external onlyOwner notZeroAddress(manager) notZeroAddress(currency) {
    require(managerInfo[manager].ipfsHash != bytes32(0), "MHI");
    _createPool(manager, currency, requireKYC);
  }

  /// @notice Function used to transfer existing pool to another manager
  /// @param oldManager Manager who owns pool now
  /// @param newManager Manager to transfer pool to
  function transferPool(
    address oldManager,
    address newManager
  ) external onlyOwner notZeroAddress(newManager) {
    require(managerInfo[oldManager].pool != address(0), "NAP");
    require(managerInfo[newManager].pool == address(0), "AHP");

    managerInfo[newManager] = managerInfo[oldManager];
    delete managerInfo[oldManager];

    IPoolMaster(managerInfo[newManager].pool).setManager(newManager);

    emit PoolTransferred(managerInfo[newManager].pool, oldManager, newManager);
  }

  /// @notice Function used to update manager's info IPFS hash
  /// @param manager Manager to update
  /// @param ipfsHash New info IPFS hash
  function setManagerInfo(
    address manager,
    bytes32 ipfsHash
  ) external onlyOwner notZeroAddress(manager) {
    require(managerInfo[manager].ipfsHash != bytes32(0), "MHZ");
    managerInfo[manager].ipfsHash = ipfsHash;
    emit ManagerInfoSet(manager, ipfsHash);
  }

  /// @notice Function is called by contract owner to update currency allowance in the protocol
  /// @param currency Address of the ERC20 token
  /// @param allowed Should currency be allowed or forbidden
  function setCurrency(address currency, bool allowed) external onlyOwner notZeroAddress(currency) {
    currencyAllowed[currency] = allowed;
    emit CurrencySet(currency, allowed);
  }

  /// @notice Function is called by contract owner to set new pool beacon
  /// @param poolBeacon_ New pool beacon contract address
  function setPoolBeacon(address poolBeacon_) external onlyOwner notZeroAddress(poolBeacon_) {
    poolBeacon = poolBeacon_;
    emit PoolBeaconSet(poolBeacon_);
  }

  /// @notice Function is called by contract owner to set new auction
  /// @param auction_ New auction contract address
  function setAuction(address auction_) external onlyOwner notZeroAddress(auction_) {
    auction = auction_;
    emit AuctionSet(auction_);
  }

  /// @notice Function is called by contract owner to set new quadrata contract
  /// @param reader_ New quadrata contract address
  function setQuadrataReader(address reader_) external onlyOwner notZeroAddress(reader_) {
    quadrataReader = IQuadReader(reader_);
    emit QuadrataReaderSet(reader_);
  }

  /// @notice Function is called by contract owner to set new InterestRateModel
  /// @param interestRateModel_ Address of the new InterestRateModel contract
  function setInterestRateModel(
    address interestRateModel_
  ) external onlyOwner notZeroAddress(interestRateModel_) {
    interestRateModel = interestRateModel_;
    emit InterestRateModelSet(interestRateModel_);
  }

  /// @notice Function is called by contract owner to set new treasury
  /// @param treasury_ Address of the new treasury
  function setTreasury(address treasury_) external onlyOwner notZeroAddress(treasury_) {
    treasury = treasury_;
    emit TreasurySet(treasury_);
  }

  /// @notice Function is called by contract owner to set new reserve factor
  /// @param reserveFactor_ New reserve factor as 18-digit decimal
  function setReserveFactor(
    uint256 reserveFactor_
  ) external onlyOwner notGraterThanOne(reserveFactor_ + insuranceFactor) {
    reserveFactor = reserveFactor_;
    emit ReserveFactorSet(reserveFactor_);
  }

  /// @notice Function is called by contract owner to set new insurance factor
  /// @param insuranceFactor_ New reserve factor as 18-digit decimal
  function setInsuranceFactor(
    uint256 insuranceFactor_
  ) external onlyOwner notGraterThanOne(reserveFactor + insuranceFactor_) {
    insuranceFactor = insuranceFactor_;
    emit InsuranceFactorSet(insuranceFactor_);
  }

  /// @notice Function is called by contract owner to set new warning utilization
  /// @param warningUtilization_ New warning utilization as 18-digit decimal
  function setWarningUtilization(
    uint256 warningUtilization_
  ) external onlyOwner notGraterThanOne(warningUtilization_) {
    require(warningUtilization_ < provisionalDefaultUtilization, "WLP");
    warningUtilization = warningUtilization_;
    emit WarningUtilizationSet(warningUtilization_);
  }

  /// @notice Function is called by contract owner to set new provisional repayment utilization
  /// @param provisionalRepaymentUtilization_ New provisional repayment utilization as 18-digit decimal
  function setProvisionalRepaymentUtilization(
    uint256 provisionalRepaymentUtilization_
  ) external onlyOwner notGraterThanOne(provisionalRepaymentUtilization_) {
    require(warningUtilization > provisionalRepaymentUtilization_, "WLP");
    provisionalRepaymentUtilization = provisionalRepaymentUtilization_;
    emit ProvisionalRepaymentUtilizationSet(provisionalRepaymentUtilization_);
  }

  /// @notice Function is called by contract owner to set new provisional default utilization
  /// @param provisionalDefaultUtilization_ New provisional default utilization as 18-digit decimal
  function setProvisionalDefaultUtilization(
    uint256 provisionalDefaultUtilization_
  ) external onlyOwner notGraterThanOne(provisionalDefaultUtilization_) {
    require(warningUtilization < provisionalDefaultUtilization_, "WLP");
    require(maxInactivePeriod > 0, "MIP");
    provisionalDefaultUtilization = provisionalDefaultUtilization_;
    emit ProvisionalDefaultUtilizationSet(provisionalDefaultUtilization_);
  }

  /// @notice Function is called by contract owner to set new warning grace period
  /// @param warningGracePeriod_ New warning grace period in seconds
  function setWarningGracePeriod(
    uint256 warningGracePeriod_
  ) external onlyOwner notZeroAmount(warningGracePeriod_) {
    warningGracePeriod = warningGracePeriod_;
    emit WarningGracePeriodSet(warningGracePeriod_);
  }

  /// @notice Function is called by contract owner to set new max inactive period
  /// @param maxInactivePeriod_ New max inactive period in seconds
  function setMaxInactivePeriod(
    uint256 maxInactivePeriod_
  ) external onlyOwner notZeroAmount(maxInactivePeriod_) {
    maxInactivePeriod = maxInactivePeriod_;
    emit MaxInactivePeriodSet(maxInactivePeriod_);
  }

  /// @notice Function is called by contract owner to set new period to start auction
  /// @param periodToStartAuction_ New period to start auction
  function setPeriodToStartAuction(
    uint256 periodToStartAuction_
  ) external onlyOwner notZeroAmount(periodToStartAuction_) {
    periodToStartAuction = periodToStartAuction_;
    emit PeriodToStartAuctionSet(periodToStartAuction_);
  }

  /// @notice Function is called by contract owner to set new CPOOl reward per block speed in some pool
  /// @param pool Pool where to set reward
  /// @param rewardPerSecond Reward per block value
  function setPoolRewardPerSecond(address pool, uint256 rewardPerSecond) external onlyOwner {
    IPoolMaster(pool).setRewardPerSecond(rewardPerSecond);
    emit PoolRewardPerSecondSet(pool, rewardPerSecond);
  }

  /// @notice Function is used to withdraw any ERC20 token except CPOOL from contract
  /// @param token Address of token to withdraw
  /// @param to Address where to transfer
  /// @param amount Amount to transfer
  function sweep(address token, address to, uint256 amount) external onlyOwner {
    /// @dev CPOOL withdrawal should be done by `closePool` or `burnStake`
    require(token != address(cpool), "SNA");
    IERC20Upgradeable(token).safeTransfer(to, amount);
  }

  /// @notice Function is called through pool at closing to unlock manager's stake
  function closePool() external {
    require(isPool[msg.sender], "SNP");
    address manager = IPoolMaster(msg.sender).manager();
    ManagerInfo storage info = managerInfo[manager];

    uint256 poolsLength = pools.length;
    for (uint256 i = 0; i < poolsLength; i++) {
      if (pools[i] == msg.sender) {
        pools[i] = pools[poolsLength - 1];
        pools.pop();
        address market = IPoolMaster(msg.sender).currency();
        uint256 marketLength = marketPools[market].length;
        address[] storage marketPools_ = marketPools[market];
        for (uint256 j = 0; j < marketLength; j++) {
          if (marketPools_[j] == msg.sender) {
            marketPools_[j] = marketPools_[marketLength - 1];
            marketPools_.pop();
            break;
          }
        }
        break;
      }
    }

    staking.unlockAndWithdrawStake(info.staker, manager, info.stakedAmount);

    info.pool = address(0);
    info.staker = address(0);
    info.stakedAmount = 0;

    emit PoolClosed(msg.sender, manager);
  }

  /// @notice Function is called through pool to burn manager's stake when auction starts
  function burnStake() external {
    require(isPool[msg.sender], "SNP");
    ManagerInfo storage info = managerInfo[IPoolMaster(msg.sender).manager()];

    staking.burnStake(info.staker, info.stakedAmount);
    info.staker = address(0);
    info.stakedAmount = 0;
  }

  /// @notice Function is used to withdraw CPOOL rewards from multiple pools
  /// @param poolsList List of pools to withdrawm from
  function withdrawReward(address[] memory poolsList) external {
    uint256 totalReward;
    for (uint256 i = 0; i < poolsList.length; i++) {
      require(isPool[poolsList[i]], "NPA");
      totalReward += IPoolMaster(poolsList[i]).withdrawReward(msg.sender);
    }

    if (totalReward > 0) {
      cpool.safeTransfer(msg.sender, totalReward);
    }
  }

  // VIEW FUNCTIONS

  /// @notice Function returns symbol for new pool based on currency and manager
  /// @param currency Pool's currency address
  /// @param manager Manager's address
  /// @return Pool symbol
  function getPoolSymbol(address currency, address manager) external view returns (string memory) {
    return
      string(
        bytes.concat(
          bytes("cp"),
          bytes(managerInfo[manager].managerSymbol),
          bytes("-"),
          bytes(IERC20MetadataUpgradeable(currency).symbol())
        )
      );
  }

  /// @notice Returns list of all active pools
  /// @return List of existing pools
  function getPools() external view returns (address[] memory) {
    return pools;
  }

  /// @notice Returns list of all active pools of some currency
  /// @return List of existing pools
  function getPoolsByMarket(address market) external view returns (address[] memory) {
    return marketPools[market];
  }

  // INTERNAL FUNCTIONS

  /// @notice Internal function that creates pool
  /// @param manager Manager of the pool
  /// @param currency Currency of the pool
  /// @param requireKYC Flag to enable KYC middleware for pool actions
  function _createPool(address manager, address currency, bool requireKYC) private {
    require(manager != address(0), "MZ");
    require(treasury != address(0), "TZ");
    require(reserveFactor != 0, "RFZ");
    require(insuranceFactor != 0, "IFZ");
    require(warningUtilization != 0, "WUZ");
    require(provisionalRepaymentUtilization != 0, "PUZ");
    require(provisionalDefaultUtilization != 0, "PUZ");
    require(warningGracePeriod != 0, "WGZ");
    require(periodToStartAuction != 0, "PAZ");
    require(maxInactivePeriod > 0, "MIP");

    if (requireKYC) {
      require(address(quadrataReader) != address(0), "QRZ");
    }

    require(currencyAllowed[currency], "CNA");
    ManagerInfo storage info = managerInfo[manager];
    require(info.pool == address(0), "AHP");

    IPoolMaster pool = IPoolMaster(address(new BeaconProxy(poolBeacon, "")));
    pool.initialize(manager, currency, requireKYC);
    info.pool = address(pool);
    info.staker = msg.sender;
    info.stakedAmount = staking.lockStake(msg.sender);
    isPool[address(pool)] = true;
    pools.push(address(pool));
    marketPools[currency].push(address(pool));

    emit PoolCreated(address(pool), manager, currency);
  }

  /// @notice Internal function that sets manager's info
  /// @param manager Manager to set info for
  /// @param info Manager's info IPFS hash
  /// @param symbol Manager's symbol
  function _setManager(address manager, bytes32 info, string memory symbol) private {
    require(managerInfo[manager].ipfsHash == bytes32(0), "AHI");
    require(info != bytes32(0), "CEI");
    require(!usedManagerSymbols[symbol], "SAU");

    managerInfo[manager].ipfsHash = info;
    managerInfo[manager].managerSymbol = symbol;
    usedManagerSymbols[symbol] = true;
  }

  /// @notice Public function that request Quadrata passport attributes
  /// @param lender Address of the lender
  /// @return IQuadPassportStore.Attributes[] - array of attribute structure
  function getKYCAttributes(
    address lender
  ) external returns (IQuadPassportStore.Attribute[] memory, uint256 queriedAttributes) {
    require(isPool[msg.sender], "SNP");

    bytes32[] memory attributesToQuery = new bytes32[](2);

    attributesToQuery[0] = keccak256("COUNTRY");
    attributesToQuery[1] = keccak256("AML");

    return (quadrataReader.getAttributesBulk(lender, attributesToQuery), attributesToQuery.length);
  }

  modifier notZeroAmount(uint256 amount) {
    require(amount != 0, "ZAM");
    _;
  }

  modifier notGraterThanOne(uint256 amount) {
    require(amount <= 1e18, "GTO");
    _;
  }

  modifier notZeroAddress(address addr) {
    require(addr != address(0), "AIZ");
    _;
  }
}