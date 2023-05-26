pragma solidity 0.5.17;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./lib/ReentrancyGuard.sol";
import "./interfaces/IMiniMeToken.sol";
import "./tokens/minime/TokenController.sol";
import "./Utils.sol";
import "./PeakDeFiProxyInterface.sol";
import "./peak/reward/PeakReward.sol";
import "./peak/staking/PeakStaking.sol";

/**
 * @title The storage layout of PeakDeFiFund
 * @author Zefram Lou (Zebang Liu)
 */
contract PeakDeFiStorage is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    enum CyclePhase {Intermission, Manage}
    enum VoteDirection {Empty, For, Against}
    enum Subchunk {Propose, Vote}

    struct Investment {
        address tokenAddress;
        uint256 cycleNumber;
        uint256 stake;
        uint256 tokenAmount;
        uint256 buyPrice; // token buy price in 18 decimals in USDC
        uint256 sellPrice; // token sell price in 18 decimals in USDC
        uint256 buyTime;
        uint256 buyCostInUSDC;
        bool isSold;
    }

    // Fund parameters
    uint256 public constant COMMISSION_RATE = 15 * (10**16); // The proportion of profits that gets distributed to RepToken holders every cycle.
    uint256 public constant ASSET_FEE_RATE = 1 * (10**15); // The proportion of fund balance that gets distributed to RepToken holders every cycle.
    uint256 public constant NEXT_PHASE_REWARD = 1 * (10**18); // Amount of RepToken rewarded to the user who calls nextPhase().
    uint256 public constant COLLATERAL_RATIO_MODIFIER = 75 * (10**16); // Modifies Compound's collateral ratio, gets 2:1 from 1.5:1 ratio
    uint256 public constant MIN_RISK_TIME = 3 days; // Mininum risk taken to get full commissions is 9 days * reptokenBalance
    uint256 public constant INACTIVE_THRESHOLD = 2; // Number of inactive cycles after which a manager's RepToken balance can be burned
    uint256 public constant ROI_PUNISH_THRESHOLD = 1 * (10**17); // ROI worse than 10% will see punishment in stake
    uint256 public constant ROI_BURN_THRESHOLD = 25 * (10**16); // ROI worse than 25% will see their stake all burned
    uint256 public constant ROI_PUNISH_SLOPE = 6; // repROI = -(6 * absROI - 0.5)
    uint256 public constant ROI_PUNISH_NEG_BIAS = 5 * (10**17); // repROI = -(6 * absROI - 0.5)
    uint256 public constant PEAK_COMMISSION_RATE = 20 * (10**16); // The proportion of profits that gets distributed to PeakDeFi referrers every cycle.

    // Instance variables

    // Checks if the token listing initialization has been completed.
    bool public hasInitializedTokenListings;

    // Checks if the fund has been initialized
    bool public isInitialized;

    // Address of the RepToken token contract.
    address public controlTokenAddr;

    // Address of the share token contract.
    address public shareTokenAddr;

    // Address of the PeakDeFiProxy contract.
    address payable public proxyAddr;

    // Address of the CompoundOrderFactory contract.
    address public compoundFactoryAddr;

    // Address of the PeakDeFiLogic contract.
    address public peakdefiLogic;
    address public peakdefiLogic2;
    address public peakdefiLogic3;

    // Address to which the development team funding will be sent.
    address payable public devFundingAccount;

    // Address of the previous version of PeakDeFiFund.
    address payable public previousVersion;

    // The number of the current investment cycle.
    uint256 public cycleNumber;

    // The amount of funds held by the fund.
    uint256 public totalFundsInUSDC;

    // The total funds at the beginning of the current management phase
    uint256 public totalFundsAtManagePhaseStart;

    // The start time for the current investment cycle phase, in seconds since Unix epoch.
    uint256 public startTimeOfCyclePhase;

    // The proportion of PeakDeFi Shares total supply to mint and use for funding the development team. Fixed point decimal.
    uint256 public devFundingRate;

    // Total amount of commission unclaimed by managers
    uint256 public totalCommissionLeft;

    // Stores the lengths of each cycle phase in seconds.
    uint256[2] public phaseLengths;

    // The number of managers onboarded during the current cycle
    uint256 public managersOnboardedThisCycle;

    // The amount of RepToken tokens a new manager receves
    uint256 public newManagerRepToken;

    // The max number of new managers that can be onboarded in one cycle
    uint256 public maxNewManagersPerCycle;

    // The price of RepToken in USDC
    uint256 public reptokenPrice;

    // The last cycle where a user redeemed all of their remaining commission.
    mapping(address => uint256) internal _lastCommissionRedemption;

    // Marks whether a manager has redeemed their commission for a certain cycle
    mapping(address => mapping(uint256 => bool))
        internal _hasRedeemedCommissionForCycle;

    // The stake-time measured risk that a manager has taken in a cycle
    mapping(address => mapping(uint256 => uint256)) internal _riskTakenInCycle;

    // In case a manager joined the fund during the current cycle, set the fallback base stake for risk threshold calculation
    mapping(address => uint256) internal _baseRiskStakeFallback;

    // List of investments of a manager in the current cycle.
    mapping(address => Investment[]) public userInvestments;

    // List of short/long orders of a manager in the current cycle.
    mapping(address => address payable[]) public userCompoundOrders;

    // Total commission to be paid for work done in a certain cycle (will be redeemed in the next cycle's Intermission)
    mapping(uint256 => uint256) internal _totalCommissionOfCycle;

    // The block number at which the Manage phase ended for a given cycle
    mapping(uint256 => uint256) internal _managePhaseEndBlock;

    // The last cycle where a manager made an investment
    mapping(address => uint256) internal _lastActiveCycle;

    // Checks if an address points to a whitelisted Kyber token.
    mapping(address => bool) public isKyberToken;

    // Checks if an address points to a whitelisted Compound token. Returns false for cUSDC and other stablecoin CompoundTokens.
    mapping(address => bool) public isCompoundToken;

    // The current cycle phase.
    CyclePhase public cyclePhase;

    // Upgrade governance related variables
    bool public hasFinalizedNextVersion; // Denotes if the address of the next smart contract version has been finalized
    address payable public nextVersion; // Address of the next version of PeakDeFiFund.

    // Contract instances
    IMiniMeToken internal cToken;
    IMiniMeToken internal sToken;
    PeakDeFiProxyInterface internal proxy;

    // PeakDeFi
    uint256 public peakReferralTotalCommissionLeft;
    uint256 public peakManagerStakeRequired;
    mapping(uint256 => uint256) internal _peakReferralTotalCommissionOfCycle;
    mapping(address => uint256) internal _peakReferralLastCommissionRedemption;
    mapping(address => mapping(uint256 => bool))
        internal _peakReferralHasRedeemedCommissionForCycle;
    IMiniMeToken public peakReferralToken;
    PeakReward public peakReward;
    PeakStaking public peakStaking;
    bool public isPermissioned;
    mapping(address => mapping(uint256 => bool)) public hasUsedSalt;

    // Events

    event ChangedPhase(
        uint256 indexed _cycleNumber,
        uint256 indexed _newPhase,
        uint256 _timestamp,
        uint256 _totalFundsInUSDC
    );

    event Deposit(
        uint256 indexed _cycleNumber,
        address indexed _sender,
        address _tokenAddress,
        uint256 _tokenAmount,
        uint256 _usdcAmount,
        uint256 _timestamp
    );
    event Withdraw(
        uint256 indexed _cycleNumber,
        address indexed _sender,
        address _tokenAddress,
        uint256 _tokenAmount,
        uint256 _usdcAmount,
        uint256 _timestamp
    );

    event CreatedInvestment(
        uint256 indexed _cycleNumber,
        address indexed _sender,
        uint256 _id,
        address _tokenAddress,
        uint256 _stakeInWeis,
        uint256 _buyPrice,
        uint256 _costUSDCAmount,
        uint256 _tokenAmount
    );
    event SoldInvestment(
        uint256 indexed _cycleNumber,
        address indexed _sender,
        uint256 _id,
        address _tokenAddress,
        uint256 _receivedRepToken,
        uint256 _sellPrice,
        uint256 _earnedUSDCAmount
    );

    event CreatedCompoundOrder(
        uint256 indexed _cycleNumber,
        address indexed _sender,
        uint256 _id,
        address _order,
        bool _orderType,
        address _tokenAddress,
        uint256 _stakeInWeis,
        uint256 _costUSDCAmount
    );
    event SoldCompoundOrder(
        uint256 indexed _cycleNumber,
        address indexed _sender,
        uint256 _id,
        address _order,
        bool _orderType,
        address _tokenAddress,
        uint256 _receivedRepToken,
        uint256 _earnedUSDCAmount
    );
    event RepaidCompoundOrder(
        uint256 indexed _cycleNumber,
        address indexed _sender,
        uint256 _id,
        address _order,
        uint256 _repaidUSDCAmount
    );

    event CommissionPaid(
        uint256 indexed _cycleNumber,
        address indexed _sender,
        uint256 _commission
    );
    event TotalCommissionPaid(
        uint256 indexed _cycleNumber,
        uint256 _totalCommissionInUSDC
    );

    event Register(
        address indexed _manager,
        uint256 _donationInUSDC,
        uint256 _reptokenReceived
    );
    event BurnDeadman(address indexed _manager, uint256 _reptokenBurned);

    event DeveloperInitiatedUpgrade(
        uint256 indexed _cycleNumber,
        address _candidate
    );
    event FinalizedNextVersion(
        uint256 indexed _cycleNumber,
        address _nextVersion
    );

    event PeakReferralCommissionPaid(
        uint256 indexed _cycleNumber,
        address indexed _sender,
        uint256 _commission
    );
    event PeakReferralTotalCommissionPaid(
        uint256 indexed _cycleNumber,
        uint256 _totalCommissionInUSDC
    );

    /*
  Helper functions shared by both PeakDeFiLogic & PeakDeFiFund
  */

    function lastCommissionRedemption(address _manager)
        public
        view
        returns (uint256)
    {
        if (_lastCommissionRedemption[_manager] == 0) {
            return
                previousVersion == address(0)
                    ? 0
                    : PeakDeFiStorage(previousVersion).lastCommissionRedemption(
                        _manager
                    );
        }
        return _lastCommissionRedemption[_manager];
    }

    function hasRedeemedCommissionForCycle(address _manager, uint256 _cycle)
        public
        view
        returns (bool)
    {
        if (_hasRedeemedCommissionForCycle[_manager][_cycle] == false) {
            return
                previousVersion == address(0)
                    ? false
                    : PeakDeFiStorage(previousVersion)
                        .hasRedeemedCommissionForCycle(_manager, _cycle);
        }
        return _hasRedeemedCommissionForCycle[_manager][_cycle];
    }

    function riskTakenInCycle(address _manager, uint256 _cycle)
        public
        view
        returns (uint256)
    {
        if (_riskTakenInCycle[_manager][_cycle] == 0) {
            return
                previousVersion == address(0)
                    ? 0
                    : PeakDeFiStorage(previousVersion).riskTakenInCycle(
                        _manager,
                        _cycle
                    );
        }
        return _riskTakenInCycle[_manager][_cycle];
    }

    function baseRiskStakeFallback(address _manager)
        public
        view
        returns (uint256)
    {
        if (_baseRiskStakeFallback[_manager] == 0) {
            return
                previousVersion == address(0)
                    ? 0
                    : PeakDeFiStorage(previousVersion).baseRiskStakeFallback(
                        _manager
                    );
        }
        return _baseRiskStakeFallback[_manager];
    }

    function totalCommissionOfCycle(uint256 _cycle)
        public
        view
        returns (uint256)
    {
        if (_totalCommissionOfCycle[_cycle] == 0) {
            return
                previousVersion == address(0)
                    ? 0
                    : PeakDeFiStorage(previousVersion).totalCommissionOfCycle(
                        _cycle
                    );
        }
        return _totalCommissionOfCycle[_cycle];
    }

    function managePhaseEndBlock(uint256 _cycle) public view returns (uint256) {
        if (_managePhaseEndBlock[_cycle] == 0) {
            return
                previousVersion == address(0)
                    ? 0
                    : PeakDeFiStorage(previousVersion).managePhaseEndBlock(
                        _cycle
                    );
        }
        return _managePhaseEndBlock[_cycle];
    }

    function lastActiveCycle(address _manager) public view returns (uint256) {
        if (_lastActiveCycle[_manager] == 0) {
            return
                previousVersion == address(0)
                    ? 0
                    : PeakDeFiStorage(previousVersion).lastActiveCycle(_manager);
        }
        return _lastActiveCycle[_manager];
    }

    /**
    PeakDeFi
   */
    function peakReferralLastCommissionRedemption(address _manager)
        public
        view
        returns (uint256)
    {
        if (_peakReferralLastCommissionRedemption[_manager] == 0) {
            return
                previousVersion == address(0)
                    ? 0
                    : PeakDeFiStorage(previousVersion)
                        .peakReferralLastCommissionRedemption(_manager);
        }
        return _peakReferralLastCommissionRedemption[_manager];
    }

    function peakReferralHasRedeemedCommissionForCycle(
        address _manager,
        uint256 _cycle
    ) public view returns (bool) {
        if (
            _peakReferralHasRedeemedCommissionForCycle[_manager][_cycle] ==
            false
        ) {
            return
                previousVersion == address(0)
                    ? false
                    : PeakDeFiStorage(previousVersion)
                        .peakReferralHasRedeemedCommissionForCycle(
                        _manager,
                        _cycle
                    );
        }
        return _peakReferralHasRedeemedCommissionForCycle[_manager][_cycle];
    }

    function peakReferralTotalCommissionOfCycle(uint256 _cycle)
        public
        view
        returns (uint256)
    {
        if (_peakReferralTotalCommissionOfCycle[_cycle] == 0) {
            return
                previousVersion == address(0)
                    ? 0
                    : PeakDeFiStorage(previousVersion)
                        .peakReferralTotalCommissionOfCycle(_cycle);
        }
        return _peakReferralTotalCommissionOfCycle[_cycle];
    }
}