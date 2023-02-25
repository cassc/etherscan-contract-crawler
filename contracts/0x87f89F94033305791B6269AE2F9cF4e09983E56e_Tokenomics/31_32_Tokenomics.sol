// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./TokenomicsConstants.sol";
import "./interfaces/IDonatorBlacklist.sol";
import "./interfaces/IErrorsTokenomics.sol";
import "./interfaces/IOLAS.sol";
import "./interfaces/IServiceRegistry.sol";
import "./interfaces/IToken.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IVotingEscrow.sol";

/*
* In this contract we consider both ETH and OLAS tokens.
* For ETH tokens, there are currently about 121 million tokens.
* Even if the ETH inflation rate is 5% per year, it would take 130+ years to reach 2^96 - 1 of ETH total supply.
* Lately the inflation rate was lower and could actually be deflationary.
*
* For OLAS tokens, the initial numbers will be as follows:
*  - For the first 10 years there will be the cap of 1 billion (1e27) tokens;
*  - After 10 years, the inflation rate is capped at 2% per year.
* Starting from a year 11, the maximum number of tokens that can be reached per the year x is 1e27 * (1.02)^x.
* To make sure that a unit(n) does not overflow the total supply during the year x, we have to check that
* 2^n - 1 >= 1e27 * (1.02)^x. We limit n by 96, thus it would take 220+ years to reach that total supply.
*
* We then limit each time variable to last until the value of 2^32 - 1 in seconds.
* 2^32 - 1 gives 136+ years counted in seconds starting from the year 1970.
* Thus, this counter is safe until the year 2106.
*
* The number of blocks cannot be practically bigger than the number of seconds, since there is more than one second
* in a block. Thus, it is safe to assume that uint32 for the number of blocks is also sufficient.
*
* We also limit the number of registry units by the value of 2^32 - 1.
* We assume that the system is expected to support no more than 2^32-1 units.
*
* Lastly, we assume that the coefficients from tokenomics factors calculation are bound by 2^16 - 1.
*
* In conclusion, this contract is only safe to use until 2106.
*/

// Structure for component / agent point with tokenomics-related statistics
// The size of the struct is 96 + 32 + 8 * 2 = 144 (1 slot)
struct UnitPoint {
    // Summation of all the relative OLAS top-ups accumulated by each component / agent in a service
    // After 10 years, the OLAS inflation rate is 2% per year. It would take 220+ years to reach 2^96 - 1
    uint96 sumUnitTopUpsOLAS;
    // Number of new units
    // This number cannot be practically bigger than the total number of supported units
    uint32 numNewUnits;
    // Reward component / agent fraction
    // This number cannot be practically bigger than 100 as the summation with other fractions gives at most 100 (%)
    uint8 rewardUnitFraction;
    // Top-up component / agent fraction
    // This number cannot be practically bigger than 100 as the summation with other fractions gives at most 100 (%)
    uint8 topUpUnitFraction;
}

// Structure for epoch point with tokenomics-related statistics during each epoch
// The size of the struct is 96 * 2 + 64 + 32 * 2 + 8 * 2 = 256 + 80 (2 slots)
struct EpochPoint {
    // Total amount of ETH donations accrued by the protocol during one epoch
    // Even if the ETH inflation rate is 5% per year, it would take 130+ years to reach 2^96 - 1 of ETH total supply
    uint96 totalDonationsETH;
    // Amount of OLAS intended to fund top-ups for the epoch based on the inflation schedule
    // After 10 years, the OLAS inflation rate is 2% per year. It would take 220+ years to reach 2^96 - 1
    uint96 totalTopUpsOLAS;
    // Inverse of the discount factor
    // IDF is bound by a factor of 18, since (2^64 - 1) / 10^18 > 18
    // IDF uses a multiplier of 10^18 by default, since it is a rational number and must be accounted for divisions
    // The IDF depends on the epsilonRate value, idf = 1 + epsilonRate, and epsilonRate is bound by 17 with 18 decimals
    uint64 idf;
    // Number of new owners
    // Each unit has at most one owner, so this number cannot be practically bigger than numNewUnits
    uint32 numNewOwners;
    // Epoch end timestamp
    // 2^32 - 1 gives 136+ years counted in seconds starting from the year 1970, which is safe until the year of 2106
    uint32 endTime;
    // Parameters for rewards and top-ups (in percentage)
    // Each of these numbers cannot be practically bigger than 100 as they sum up to 100%
    // treasuryFraction + rewardComponentFraction + rewardAgentFraction = 100%
    // Treasury fraction
    uint8 rewardTreasuryFraction;
    // maxBondFraction + topUpComponentFraction + topUpAgentFraction <= 100%
    // Amount of OLAS (in percentage of inflation) intended to fund bonding incentives during the epoch
    uint8 maxBondFraction;
}

// Structure for tokenomics point
// The size of the struct is 256 * 2 + 256 * 2 = 256 * 4 (4 slots)
struct TokenomicsPoint {
    // Two unit points in a representation of mapping and not on array to save on gas
    // One unit point is for component (key = 0) and one is for agent (key = 1)
    mapping(uint256 => UnitPoint) unitPoints;
    // Epoch point
    EpochPoint epochPoint;
}

// Struct for component / agent incentive balances
struct IncentiveBalances {
    // Reward in ETH
    // Even if the ETH inflation rate is 5% per year, it would take 130+ years to reach 2^96 - 1 of ETH total supply
    uint96 reward;
    // Pending relative reward in ETH
    uint96 pendingRelativeReward;
    // Top-up in OLAS
    // After 10 years, the OLAS inflation rate is 2% per year. It would take 220+ years to reach 2^96 - 1
    uint96 topUp;
    // Pending relative top-up
    uint96 pendingRelativeTopUp;
    // Last epoch number the information was updated
    // This number cannot be practically bigger than the number of blocks
    uint32 lastEpoch;
}

/// @title Tokenomics - Smart contract for tokenomics logic with incentives for unit owners and discount factor regulations for bonds.
/// @author AL
/// @author Aleksandr Kuperman - <[email protected]>
contract Tokenomics is TokenomicsConstants, IErrorsTokenomics {
    event OwnerUpdated(address indexed owner);
    event TreasuryUpdated(address indexed treasury);
    event DepositoryUpdated(address indexed depository);
    event DispenserUpdated(address indexed dispenser);
    event EpochLengthUpdated(uint256 epochLen);
    event EffectiveBondUpdated(uint256 effectiveBond);
    event IDFUpdated(uint256 idf);
    event TokenomicsParametersUpdateRequested(uint256 indexed epochNumber, uint256 devsPerCapital, uint256 codePerDev,
        uint256 epsilonRate, uint256 epochLen, uint256 veOLASThreshold);
    event TokenomicsParametersUpdated(uint256 indexed epochNumber);
    event IncentiveFractionsUpdateRequested(uint256 indexed epochNumber, uint256 rewardComponentFraction,
        uint256 rewardAgentFraction, uint256 maxBondFraction, uint256 topUpComponentFraction, uint256 topUpAgentFraction);
    event IncentiveFractionsUpdated(uint256 indexed epochNumber);
    event ComponentRegistryUpdated(address indexed componentRegistry);
    event AgentRegistryUpdated(address indexed agentRegistry);
    event ServiceRegistryUpdated(address indexed serviceRegistry);
    event DonatorBlacklistUpdated(address indexed blacklist);
    event EpochSettled(uint256 indexed epochCounter, uint256 treasuryRewards, uint256 accountRewards, uint256 accountTopUps);
    event TokenomicsImplementationUpdated(address indexed implementation);

    // Owner address
    address public owner;
    // Max bond per epoch: calculated as a fraction from the OLAS inflation parameter
    // After 10 years, the OLAS inflation rate is 2% per year. It would take 220+ years to reach 2^96 - 1
    uint96 public maxBond;

    // OLAS token address
    address public olas;
    // Inflation amount per second
    uint96 public inflationPerSecond;

    // Treasury contract address
    address public treasury;
    // veOLAS threshold for top-ups
    // This number cannot be practically bigger than the number of OLAS tokens
    uint96 public veOLASThreshold;

    // Depository contract address
    address public depository;
    // effectiveBond = sum(MaxBond(e)) - sum(BondingProgram) over all epochs: accumulates leftovers from previous epochs
    // Effective bond is updated before the start of the next epoch such that the bonding limits are accounted for
    // This number cannot be practically bigger than the inflation remainder of OLAS
    uint96 public effectiveBond;

    // Dispenser contract address
    address public dispenser;
    // Number of units of useful code that can be built by a developer during one epoch
    // We assume this number will not be practically bigger than 4,722 of its integer-part (with 18 digits of fractional-part)
    uint72 public codePerDev;
    // Current year number
    // This number is enough for the next 255 years
    uint8 public currentYear;
    // Tokenomics parameters change request flag
    bytes1 public tokenomicsParametersUpdated;
    // Reentrancy lock
    uint8 internal _locked;

    // Component Registry
    address public componentRegistry;
    // Default epsilon rate that contributes to the interest rate: 10% or 0.1
    // We assume that for the IDF calculation epsilonRate must be lower than 17 (with 18 decimals)
    // (2^64 - 1) / 10^18 > 18, however IDF = 1 + epsilonRate, thus we limit epsilonRate by 17 with 18 decimals at most
    uint64 public epsilonRate;
    // Epoch length in seconds
    // By design, the epoch length cannot be practically bigger than one year, or 31_536_000 seconds
    uint32 public epochLen;

    // Agent Registry
    address public agentRegistry;
    // veOLAS threshold for top-ups that will be set in the next epoch
    // This number cannot be practically bigger than the number of OLAS tokens
    uint96 public nextVeOLASThreshold;

    // Service Registry
    address public serviceRegistry;
    // Global epoch counter
    // This number cannot be practically bigger than the number of blocks
    uint32 public epochCounter;
    // Time launch of the OLAS contract
    // 2^32 - 1 gives 136+ years counted in seconds starting from the year 1970, which is safe until the year of 2106
    uint32 public timeLaunch;
    // Epoch length in seconds that will be set in the next epoch
    // By design, the epoch length cannot be practically bigger than one year, or 31_536_000 seconds
    uint32 public nextEpochLen;

    // Voting Escrow address
    address public ve;
    // Number of valuable devs that can be paid per units of capital per epoch in fixed point format
    // We assume this number will not be practically bigger than 4,722 of its integer-part (with 18 digits of fractional-part)
    uint72 public devsPerCapital;

    // Blacklist contract address
    address public donatorBlacklist;
    // Last donation block number to prevent the flash loan attack
    // This number cannot be practically bigger than the number of seconds
    uint32 public lastDonationBlockNumber;

    // Map of service Ids and their amounts in current epoch
    mapping(uint256 => uint256) public mapServiceAmounts;
    // Mapping of owner of component / agent address => reward amount (in ETH)
    mapping(address => uint256) public mapOwnerRewards;
    // Mapping of owner of component / agent address => top-up amount (in OLAS)
    mapping(address => uint256) public mapOwnerTopUps;
    // Mapping of epoch => tokenomics point
    mapping(uint256 => TokenomicsPoint) public mapEpochTokenomics;
    // Map of new component / agent Ids that contribute to protocol owned services
    mapping(uint256 => mapping(uint256 => bool)) public mapNewUnits;
    // Mapping of new owner of component / agent addresses that create them
    mapping(address => bool) public mapNewOwners;
    // Mapping of component / agent Id => incentive balances
    mapping(uint256 => mapping(uint256 => IncentiveBalances)) public mapUnitIncentives;

    /// @dev Tokenomics constructor.
    constructor()
        TokenomicsConstants()
    {}

    /// @dev Tokenomics initializer.
    /// @notice Tokenomics contract must be initialized no later than one year from the launch of the OLAS token contract.
    /// @param _olas OLAS token address.
    /// @param _treasury Treasury address.
    /// @param _depository Depository address.
    /// @param _dispenser Dispenser address.
    /// @param _ve Voting Escrow address.
    /// @param _epochLen Epoch length.
    /// @param _componentRegistry Component registry address.
    /// @param _agentRegistry Agent registry address.
    /// @param _serviceRegistry Service registry address.
    /// @param _donatorBlacklist DonatorBlacklist address.
    /// #if_succeeds {:msg "ep is correct endTime"} mapEpochTokenomics[0].epochPoint.endTime > 0;
    /// #if_succeeds {:msg "maxBond eq effectiveBond form start"} effectiveBond == maxBond;
    /// #if_succeeds {:msg "olas must not be a zero address"} old(_olas) != address(0) ==> olas == _olas;
    /// #if_succeeds {:msg "treasury must not be a zero address"} old(_treasury) != address(0) ==> treasury == _treasury;
    /// #if_succeeds {:msg "depository must not be a zero address"} old(_depository) != address(0) ==> depository == _depository;
    /// #if_succeeds {:msg "dispenser must not be a zero address"} old(_dispenser) != address(0) ==> dispenser == _dispenser;
    /// #if_succeeds {:msg "vaOLAS must not be a zero address"} old(_ve) != address(0) ==> ve == _ve;
    /// #if_succeeds {:msg "epochLen"} old(_epochLen > MIN_EPOCH_LENGTH && _epochLen <= type(uint32).max) ==> epochLen == _epochLen;
    /// #if_succeeds {:msg "componentRegistry must not be a zero address"} old(_componentRegistry) != address(0) ==> componentRegistry == _componentRegistry;
    /// #if_succeeds {:msg "agentRegistry must not be a zero address"} old(_agentRegistry) != address(0) ==> agentRegistry == _agentRegistry;
    /// #if_succeeds {:msg "serviceRegistry must not be a zero address"} old(_serviceRegistry) != address(0) ==> serviceRegistry == _serviceRegistry;
    /// #if_succeeds {:msg "donatorBlacklist assignment"} donatorBlacklist == _donatorBlacklist;
    /// #if_succeeds {:msg "inflationPerSecond must not be zero"} inflationPerSecond > 0 && inflationPerSecond <= getInflationForYear(0);
    /// #if_succeeds {:msg "Zero epoch point end time must be non-zero"} mapEpochTokenomics[0].epochPoint.endTime > 0;
    /// #if_succeeds {:msg "maxBond"} old(_epochLen > MIN_EPOCH_LENGTH && _epochLen <= type(uint32).max && inflationPerSecond > 0 && inflationPerSecond <= getInflationForYear(0))
    /// ==> maxBond == (inflationPerSecond * _epochLen * mapEpochTokenomics[1].epochPoint.maxBondFraction) / 100;
    function initializeTokenomics(
        address _olas,
        address _treasury,
        address _depository,
        address _dispenser,
        address _ve,
        uint256 _epochLen,
        address _componentRegistry,
        address _agentRegistry,
        address _serviceRegistry,
        address _donatorBlacklist
    ) external
    {
        // Check if the contract is already initialized
        if (owner != address(0)) {
            revert AlreadyInitialized();
        }

        // Check for at least one zero contract address
        if (_olas == address(0) || _treasury == address(0) || _depository == address(0) || _dispenser == address(0) ||
            _ve == address(0) || _componentRegistry == address(0) || _agentRegistry == address(0) ||
            _serviceRegistry == address(0)) {
            revert ZeroAddress();
        }

        // Initialize storage variables
        owner = msg.sender;
        _locked = 1;
        epsilonRate = 1e17;
        veOLASThreshold = 10_000e18;

        // Check that the epoch length has at least a practical minimal value
        if (uint32(_epochLen) < MIN_EPOCH_LENGTH) {
            revert LowerThan(_epochLen, MIN_EPOCH_LENGTH);
        }

        // Check that the epoch length is not bigger than one year
        if (uint32(_epochLen) > ONE_YEAR) {
            revert Overflow(_epochLen, ONE_YEAR);
        }

        // Assign other input variables
        olas = _olas;
        treasury = _treasury;
        depository = _depository;
        dispenser = _dispenser;
        ve = _ve;
        epochLen = uint32(_epochLen);
        componentRegistry = _componentRegistry;
        agentRegistry = _agentRegistry;
        serviceRegistry = _serviceRegistry;
        donatorBlacklist = _donatorBlacklist;

        // Time launch of the OLAS contract
        uint256 _timeLaunch = IOLAS(_olas).timeLaunch();
        // Check that the tokenomics contract is initialized no later than one year after the OLAS token is deployed
        if (block.timestamp >= (_timeLaunch + ONE_YEAR)) {
            revert Overflow(_timeLaunch + ONE_YEAR, block.timestamp);
        }
        // Seconds left in the deployment year for the zero year inflation schedule
        // This value is necessary since it is different from a precise one year time, as the OLAS contract started earlier
        uint256 zeroYearSecondsLeft = uint32(_timeLaunch + ONE_YEAR - block.timestamp);
        // Calculating initial inflation per second: (mintable OLAS from getInflationForYear(0)) / (seconds left in a year)
        // Note that we lose precision here dividing by the number of seconds right away, but to avoid complex calculations
        // later we consider it less error-prone and sacrifice at most 6 insignificant digits (or 1e-12) of OLAS per year
        uint256 _inflationPerSecond = getInflationForYear(0) / zeroYearSecondsLeft;
        inflationPerSecond = uint96(_inflationPerSecond);
        timeLaunch = uint32(_timeLaunch);

        // The initial epoch start time is the end time of the zero epoch
        mapEpochTokenomics[0].epochPoint.endTime = uint32(block.timestamp);

        // The epoch counter starts from 1
        epochCounter = 1;
        TokenomicsPoint storage tp = mapEpochTokenomics[1];

        // Setting initial parameters and fractions
        devsPerCapital = 1e18;
        tp.epochPoint.idf = 1e18;

        // Reward fractions
        // 0 stands for components and 1 for agents
        // The initial target is to distribute around 2/3 of incentives reserved to fund owners of the code
        // for components royalties and 1/3 for agents royalties
        tp.unitPoints[0].rewardUnitFraction = 83;
        tp.unitPoints[1].rewardUnitFraction = 17;
        // tp.epochPoint.rewardTreasuryFraction is essentially equal to zero

        // We consider a unit of code as n agents or m components.
        // Initially we consider 1 unit of code as either 2 agents or 1 component.
        // E.g. if we have 2 profitable components and 2 profitable agents, this means there are (2 x 2.0 + 2 x 1.0) / 3 = 2
        // units of code.
        // We assume that during one epoch the developer can contribute with one piece of code (1 component or 2 agents)
        codePerDev = 1e18;

        // Top-up fractions
        uint256 _maxBondFraction = 50;
        tp.epochPoint.maxBondFraction = uint8(_maxBondFraction);
        tp.unitPoints[0].topUpUnitFraction = 41;
        tp.unitPoints[1].topUpUnitFraction = 9;

        // Calculate initial effectiveBond based on the maxBond during the first epoch
        // maxBond = inflationPerSecond * epochLen * maxBondFraction / 100
        uint256 _maxBond = (_inflationPerSecond * _epochLen * _maxBondFraction) / 100;
        maxBond = uint96(_maxBond);
        effectiveBond = uint96(_maxBond);
    }

    /// @dev Gets the tokenomics implementation contract address.
    /// @return implementation Tokenomics implementation contract address.
    function tokenomicsImplementation() external view returns (address implementation) {
        assembly {
            implementation := sload(PROXY_TOKENOMICS)
        }
    }

    /// @dev Changes the tokenomics implementation contract address.
    /// @notice Make sure the implementation contract has a function to change the implementation.
    /// @param implementation Tokenomics implementation contract address.
    /// #if_succeeds {:msg "new implementation"} implementation == tokenomicsImplementation();
    function changeTokenomicsImplementation(address implementation) external {
        // Check for the contract ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        // Check for the zero address
        if (implementation == address(0)) {
            revert ZeroAddress();
        }

        // Store the implementation address under the designated storage slot
        assembly {
            sstore(PROXY_TOKENOMICS, implementation)
        }
        emit TokenomicsImplementationUpdated(implementation);
    }

    /// @dev Changes the owner address.
    /// @param newOwner Address of a new owner.
    function changeOwner(address newOwner) external {
        // Check for the contract ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        // Check for the zero address
        if (newOwner == address(0)) {
            revert ZeroAddress();
        }

        owner = newOwner;
        emit OwnerUpdated(newOwner);
    }

    /// @dev Changes various managing contract addresses.
    /// @param _treasury Treasury address.
    /// @param _depository Depository address.
    /// @param _dispenser Dispenser address.
    function changeManagers(address _treasury, address _depository, address _dispenser) external {
        // Check for the contract ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        // Change Treasury contract address
        if (_treasury != address(0)) {
            treasury = _treasury;
            emit TreasuryUpdated(_treasury);
        }
        // Change Depository contract address
        if (_depository != address(0)) {
            depository = _depository;
            emit DepositoryUpdated(_depository);
        }
        // Change Dispenser contract address
        if (_dispenser != address(0)) {
            dispenser = _dispenser;
            emit DispenserUpdated(_dispenser);
        }
    }

    /// @dev Changes registries contract addresses.
    /// @param _componentRegistry Component registry address.
    /// @param _agentRegistry Agent registry address.
    /// @param _serviceRegistry Service registry address.
    function changeRegistries(address _componentRegistry, address _agentRegistry, address _serviceRegistry) external {
        // Check for the contract ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        // Check for registries addresses
        if (_componentRegistry != address(0)) {
            componentRegistry = _componentRegistry;
            emit ComponentRegistryUpdated(_componentRegistry);
        }
        if (_agentRegistry != address(0)) {
            agentRegistry = _agentRegistry;
            emit AgentRegistryUpdated(_agentRegistry);
        }
        if (_serviceRegistry != address(0)) {
            serviceRegistry = _serviceRegistry;
            emit ServiceRegistryUpdated(_serviceRegistry);
        }
    }

    /// @dev Changes donator blacklist contract address.
    /// @notice DonatorBlacklist contract can be disabled by setting its address to zero.
    /// @param _donatorBlacklist DonatorBlacklist contract address.
    function changeDonatorBlacklist(address _donatorBlacklist) external {
        // Check for the contract ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        donatorBlacklist = _donatorBlacklist;
        emit DonatorBlacklistUpdated(_donatorBlacklist);
    }

    /// @dev Changes tokenomics parameters.
    /// @notice Parameter values are not updated for those that are passed as zero or out of defined bounds.
    /// @param _devsPerCapital Number of valuable devs can be paid per units of capital per epoch.
    /// @param _codePerDev Number of units of useful code that can be built by a developer during one epoch.
    /// @param _epsilonRate Epsilon rate that contributes to the interest rate value.
    /// @param _epochLen New epoch length.
    /// #if_succeeds {:msg "ep is correct endTime"} epochCounter > 1
    /// ==> mapEpochTokenomics[epochCounter - 1].epochPoint.endTime > mapEpochTokenomics[epochCounter - 2].epochPoint.endTime;
    /// #if_succeeds {:msg "epochLen"} old(_epochLen > MIN_EPOCH_LENGTH && _epochLen <= ONE_YEAR && epochLen != _epochLen) ==> nextEpochLen == _epochLen;
    /// #if_succeeds {:msg "devsPerCapital"} _devsPerCapital > MIN_PARAM_VALUE && _devsPerCapital <= type(uint72).max ==> devsPerCapital == _devsPerCapital;
    /// #if_succeeds {:msg "codePerDev"} _codePerDev > MIN_PARAM_VALUE && _codePerDev <= type(uint72).max ==> codePerDev == _codePerDev;
    /// #if_succeeds {:msg "epsilonRate"} _epsilonRate > 0 && _epsilonRate < 17e18 ==> epsilonRate == _epsilonRate;
    /// #if_succeeds {:msg "veOLASThreshold"} _veOLASThreshold > 0 && _veOLASThreshold <= type(uint96).max ==> nextVeOLASThreshold == _veOLASThreshold;
    function changeTokenomicsParameters(
        uint256 _devsPerCapital,
        uint256 _codePerDev,
        uint256 _epsilonRate,
        uint256 _epochLen,
        uint256 _veOLASThreshold
    ) external
    {
        // Check for the contract ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        // devsPerCapital is the part of the IDF calculation and thus its change will be accounted for in the next epoch
        if (uint72(_devsPerCapital) > MIN_PARAM_VALUE) {
            devsPerCapital = uint72(_devsPerCapital);
        } else {
            // This is done in order not to pass incorrect parameters into the event
            _devsPerCapital = devsPerCapital;
        }

        // devsPerCapital is the part of the IDF calculation and thus its change will be accounted for in the next epoch
        if (uint72(_codePerDev) > MIN_PARAM_VALUE) {
            codePerDev = uint72(_codePerDev);
        } else {
            // This is done in order not to pass incorrect parameters into the event
            _codePerDev = codePerDev;
        }

        // Check the epsilonRate value for idf to fit in its size
        // 2^64 - 1 < 18.5e18, idf is equal at most 1 + epsilonRate < 18e18, which fits in the variable size
        // epsilonRate is the part of the IDF calculation and thus its change will be accounted for in the next epoch
        if (_epsilonRate > 0 && _epsilonRate <= 17e18) {
            epsilonRate = uint64(_epsilonRate);
        } else {
            _epsilonRate = epsilonRate;
        }

        // Check for the epochLen value to change
        if (uint32(_epochLen) >= MIN_EPOCH_LENGTH && uint32(_epochLen) <= ONE_YEAR) {
            nextEpochLen = uint32(_epochLen);
        } else {
            _epochLen = epochLen;
        }

        // Adjust veOLAS threshold for the next epoch
        if (uint96(_veOLASThreshold) > 0) {
            nextVeOLASThreshold = uint96(_veOLASThreshold);
        } else {
            _veOLASThreshold = veOLASThreshold;
        }

        // Set the flag that tokenomics parameters are requested to be updated (1st bit is set to one)
        tokenomicsParametersUpdated = tokenomicsParametersUpdated | 0x01;
        emit TokenomicsParametersUpdateRequested(epochCounter + 1, _devsPerCapital, _codePerDev, _epsilonRate, _epochLen,
            _veOLASThreshold);
    }

    /// @dev Sets incentive parameter fractions.
    /// @param _rewardComponentFraction Fraction for component owner rewards funded by ETH donations.
    /// @param _rewardAgentFraction Fraction for agent owner rewards funded by ETH donations.
    /// @param _maxBondFraction Fraction for the maxBond that depends on the OLAS inflation.
    /// @param _topUpComponentFraction Fraction for component owners OLAS top-up.
    /// @param _topUpAgentFraction Fraction for agent owners OLAS top-up.
    /// #if_succeeds {:msg "maxBond"} mapEpochTokenomics[epochCounter + 1].epochPoint.maxBondFraction == _maxBondFraction;
    function changeIncentiveFractions(
        uint256 _rewardComponentFraction,
        uint256 _rewardAgentFraction,
        uint256 _maxBondFraction,
        uint256 _topUpComponentFraction,
        uint256 _topUpAgentFraction
    ) external
    {
        // Check for the contract ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        // Check that the sum of fractions is 100%
        if (_rewardComponentFraction + _rewardAgentFraction > 100) {
            revert WrongAmount(_rewardComponentFraction + _rewardAgentFraction, 100);
        }

        // Same check for top-up fractions
        if (_maxBondFraction + _topUpComponentFraction + _topUpAgentFraction > 100) {
            revert WrongAmount(_maxBondFraction + _topUpComponentFraction + _topUpAgentFraction, 100);
        }

        // All the adjustments will be accounted for in the next epoch
        uint256 eCounter = epochCounter + 1;
        TokenomicsPoint storage tp = mapEpochTokenomics[eCounter];
        // 0 stands for components and 1 for agents
        tp.unitPoints[0].rewardUnitFraction = uint8(_rewardComponentFraction);
        tp.unitPoints[1].rewardUnitFraction = uint8(_rewardAgentFraction);
        // Rewards are always distributed in full: the leftovers will be allocated to treasury
        tp.epochPoint.rewardTreasuryFraction = uint8(100 - _rewardComponentFraction - _rewardAgentFraction);

        tp.epochPoint.maxBondFraction = uint8(_maxBondFraction);
        tp.unitPoints[0].topUpUnitFraction = uint8(_topUpComponentFraction);
        tp.unitPoints[1].topUpUnitFraction = uint8(_topUpAgentFraction);

        // Set the flag that incentive fractions are requested to be updated (2nd bit is set to one)
        tokenomicsParametersUpdated = tokenomicsParametersUpdated | 0x02;
        emit IncentiveFractionsUpdateRequested(eCounter, _rewardComponentFraction, _rewardAgentFraction,
            _maxBondFraction, _topUpComponentFraction, _topUpAgentFraction);
    }

    /// @dev Reserves OLAS amount from the effective bond to be minted during a bond program.
    /// @notice Programs exceeding the limit of the effective bond are not allowed.
    /// @param amount Requested amount for the bond program.
    /// @return success True if effective bond threshold is not reached.
    /// #if_succeeds {:msg "effectiveBond"} old(effectiveBond) > amount ==> effectiveBond == old(effectiveBond) - amount;
    function reserveAmountForBondProgram(uint256 amount) external returns (bool success) {
        // Check for the depository access
        if (depository != msg.sender) {
            revert ManagerOnly(msg.sender, depository);
        }

        // Effective bond must be bigger than the requested amount
        uint256 eBond = effectiveBond;
        if (eBond >= amount) {
            // The effective bond value is adjusted with the amount that is reserved for bonding
            // The unrealized part of the bonding amount will be returned when the bonding program is closed
            eBond -= amount;
            effectiveBond = uint96(eBond);
            success = true;
            emit EffectiveBondUpdated(eBond);
        }
    }

    /// @dev Refunds unused bond program amount when the program is closed.
    /// @param amount Amount to be refunded from the closed bond program.
    /// #if_succeeds {:msg "effectiveBond"} old(effectiveBond + amount) <= type(uint96).max ==> effectiveBond == old(effectiveBond) + amount;
    function refundFromBondProgram(uint256 amount) external {
        // Check for the depository access
        if (depository != msg.sender) {
            revert ManagerOnly(msg.sender, depository);
        }

        uint256 eBond = effectiveBond + amount;
        // This scenario is not realistically possible. It is only possible when closing the bonding program
        // with the effectiveBond value close to uint96 max
        if (eBond > type(uint96).max) {
            revert Overflow(eBond, type(uint96).max);
        }
        effectiveBond = uint96(eBond);
        emit EffectiveBondUpdated(eBond);
    }

    /// @dev Finalizes epoch incentives for a specified component / agent Id.
    /// @param epochNum Epoch number to finalize incentives for.
    /// @param unitType Unit type (component / agent).
    /// @param unitId Unit Id.
    function _finalizeIncentivesForUnitId(uint256 epochNum, uint256 unitType, uint256 unitId) internal {
        // Gets the overall amount of unit rewards for the unit's last epoch
        // The pendingRelativeReward can be zero if the rewardUnitFraction was zero in the first place
        // Note that if the rewardUnitFraction is set to zero at the end of epoch, the whole pending reward will be zero
        // reward = (pendingRelativeReward * rewardUnitFraction) / 100
        uint256 totalIncentives = mapUnitIncentives[unitType][unitId].pendingRelativeReward;
        if (totalIncentives > 0) {
            totalIncentives *= mapEpochTokenomics[epochNum].unitPoints[unitType].rewardUnitFraction;
            // Add to the final reward for the last epoch
            totalIncentives = mapUnitIncentives[unitType][unitId].reward + totalIncentives / 100;
            mapUnitIncentives[unitType][unitId].reward = uint96(totalIncentives);
            // Setting pending reward to zero
            mapUnitIncentives[unitType][unitId].pendingRelativeReward = 0;
        }

        // Add to the final top-up for the last epoch
        totalIncentives = mapUnitIncentives[unitType][unitId].pendingRelativeTopUp;
        // The pendingRelativeTopUp can be zero if the service owner did not stake enough veOLAS
        // The topUpUnitFraction was checked before and if it were zero, pendingRelativeTopUp would be zero as well
        if (totalIncentives > 0) {
            // Summation of all the unit top-ups and total amount of top-ups per epoch
            // topUp = (pendingRelativeTopUp * totalTopUpsOLAS * topUpUnitFraction) / (100 * sumUnitTopUpsOLAS)
            totalIncentives *= mapEpochTokenomics[epochNum].epochPoint.totalTopUpsOLAS;
            totalIncentives *= mapEpochTokenomics[epochNum].unitPoints[unitType].topUpUnitFraction;
            uint256 sumUnitIncentives = uint256(mapEpochTokenomics[epochNum].unitPoints[unitType].sumUnitTopUpsOLAS) * 100;
            totalIncentives = mapUnitIncentives[unitType][unitId].topUp + totalIncentives / sumUnitIncentives;
            mapUnitIncentives[unitType][unitId].topUp = uint96(totalIncentives);
            // Setting pending top-up to zero
            mapUnitIncentives[unitType][unitId].pendingRelativeTopUp = 0;
        }
    }

    /// @dev Records service donations into corresponding data structures.
    /// @param serviceIds Set of service Ids.
    /// @param amounts Correspondent set of ETH amounts provided by services.
    /// @param curEpoch Current epoch number.
    function _trackServiceDonations(uint256[] memory serviceIds, uint256[] memory amounts, uint256 curEpoch) internal {
        // Component / agent registry addresses
        address[] memory registries = new address[](2);
        (registries[0], registries[1]) = (componentRegistry, agentRegistry);

        // Check all the unit fractions and identify those that need accounting of incentives
        bool[] memory incentiveFlags = new bool[](4);
        incentiveFlags[0] = (mapEpochTokenomics[curEpoch].unitPoints[0].rewardUnitFraction > 0);
        incentiveFlags[1] = (mapEpochTokenomics[curEpoch].unitPoints[1].rewardUnitFraction > 0);
        incentiveFlags[2] = (mapEpochTokenomics[curEpoch].unitPoints[0].topUpUnitFraction > 0);
        incentiveFlags[3] = (mapEpochTokenomics[curEpoch].unitPoints[1].topUpUnitFraction > 0);

        // Get the number of services
        uint256 numServices = serviceIds.length;
        // Loop over service Ids to calculate their partial contributions
        for (uint256 i = 0; i < numServices; ++i) {
            // Check if the service owner stakes enough OLAS for its components / agents to get a top-up
            // If both component and agent owner top-up fractions are zero, there is no need to call external contract
            // functions to check each service owner veOLAS balance
            bool topUpEligible;
            if (incentiveFlags[2] || incentiveFlags[3]) {
                address serviceOwner = IToken(serviceRegistry).ownerOf(serviceIds[i]);
                topUpEligible = IVotingEscrow(ve).getVotes(serviceOwner) >= veOLASThreshold ? true : false;
            }

            // Loop over component and agent Ids
            for (uint256 unitType = 0; unitType < 2; ++unitType) {
                // Get the number and set of units in the service
                (uint256 numServiceUnits, uint32[] memory serviceUnitIds) = IServiceRegistry(serviceRegistry).
                    getUnitIdsOfService(IServiceRegistry.UnitType(unitType), serviceIds[i]);
                // Service has to be deployed at least once to be able to receive donations,
                // otherwise its components and agents are undefined
                if (numServiceUnits == 0) {
                    revert ServiceNeverDeployed(serviceIds[i]);
                }
                // Record amounts data only if at least one incentive unit fraction is not zero
                if (incentiveFlags[unitType] || incentiveFlags[unitType + 2]) {
                    // The amount has to be adjusted for the number of units in the service
                    uint96 amount = uint96(amounts[i] / numServiceUnits);
                    // Accumulate amounts for each unit Id
                    for (uint256 j = 0; j < numServiceUnits; ++j) {
                        // Get the last epoch number the incentives were accumulated for
                        uint256 lastEpoch = mapUnitIncentives[unitType][serviceUnitIds[j]].lastEpoch;
                        // Check if there were no donations in previous epochs and set the current epoch
                        if (lastEpoch == 0) {
                            mapUnitIncentives[unitType][serviceUnitIds[j]].lastEpoch = uint32(curEpoch);
                        } else if (lastEpoch < curEpoch) {
                            // Finalize unit rewards and top-ups if there were pending ones from the previous epoch
                            // Pending incentives are getting finalized during the next epoch the component / agent
                            // receives donations. If this is not the case before claiming incentives, the finalization
                            // happens in the accountOwnerIncentives() where the incentives are issued
                            _finalizeIncentivesForUnitId(lastEpoch, unitType, serviceUnitIds[j]);
                            // Change the last epoch number
                            mapUnitIncentives[unitType][serviceUnitIds[j]].lastEpoch = uint32(curEpoch);
                        }
                        // Sum the relative amounts for the corresponding components / agents
                        if (incentiveFlags[unitType]) {
                            mapUnitIncentives[unitType][serviceUnitIds[j]].pendingRelativeReward += amount;
                        }
                        // If eligible, add relative top-up weights in the form of donation amounts.
                        // These weights will represent the fraction of top-ups for each component / agent relative
                        // to the overall amount of top-ups that must be allocated
                        if (topUpEligible && incentiveFlags[unitType + 2]) {
                            mapUnitIncentives[unitType][serviceUnitIds[j]].pendingRelativeTopUp += amount;
                            mapEpochTokenomics[curEpoch].unitPoints[unitType].sumUnitTopUpsOLAS += amount;
                        }
                    }
                }

                // Record new units and new unit owners
                for (uint256 j = 0; j < numServiceUnits; ++j) {
                    // Check if the component / agent is used for the first time
                    if (!mapNewUnits[unitType][serviceUnitIds[j]]) {
                        mapNewUnits[unitType][serviceUnitIds[j]] = true;
                        mapEpochTokenomics[curEpoch].unitPoints[unitType].numNewUnits++;
                        // Check if the owner has introduced component / agent for the first time
                        // This is done together with the new unit check, otherwise it could be just a new unit owner
                        address unitOwner = IToken(registries[unitType]).ownerOf(serviceUnitIds[j]);
                        if (!mapNewOwners[unitOwner]) {
                            mapNewOwners[unitOwner] = true;
                            mapEpochTokenomics[curEpoch].epochPoint.numNewOwners++;
                        }
                    }
                }
            }
        }
    }

    /// @dev Tracks the deposited ETH service donations during the current epoch.
    /// @notice This function is only called by the treasury where the validity of arrays and values has been performed.
    /// @notice Donating to services must not be followed by the checkpoint in the same block.
    /// @param donator Donator account address.
    /// @param serviceIds Set of service Ids.
    /// @param amounts Correspondent set of ETH amounts provided by services.
    /// @param donationETH Overall service donation amount in ETH.
    /// #if_succeeds {:msg "totalDonationsETH can only increase"} old(mapEpochTokenomics[epochCounter].epochPoint.totalDonationsETH) + donationETH <= type(uint96).max
    /// ==> mapEpochTokenomics[epochCounter].epochPoint.totalDonationsETH == old(mapEpochTokenomics[epochCounter].epochPoint.totalDonationsETH) + donationETH;
    /// #if_succeeds {:msg "sumUnitTopUpsOLAS for components can only increase"} mapEpochTokenomics[epochCounter].unitPoints[0].sumUnitTopUpsOLAS >= old(mapEpochTokenomics[epochCounter].unitPoints[0].sumUnitTopUpsOLAS);
    /// #if_succeeds {:msg "sumUnitTopUpsOLAS for agents can only increase"} mapEpochTokenomics[epochCounter].unitPoints[1].sumUnitTopUpsOLAS >= old(mapEpochTokenomics[epochCounter].unitPoints[1].sumUnitTopUpsOLAS);
    /// #if_succeeds {:msg "numNewOwners can only increase"} mapEpochTokenomics[epochCounter].epochPoint.numNewOwners >= old(mapEpochTokenomics[epochCounter].epochPoint.numNewOwners);
    function trackServiceDonations(
        address donator,
        uint256[] memory serviceIds,
        uint256[] memory amounts,
        uint256 donationETH
    ) external {
        // Check for the treasury access
        if (treasury != msg.sender) {
            revert ManagerOnly(msg.sender, treasury);
        }

        // Check if the donator blacklist is enabled, and the status of the donator address
        address bList = donatorBlacklist;
        if (bList != address(0) && IDonatorBlacklist(bList).isDonatorBlacklisted(donator)) {
            revert DonatorBlacklisted(donator);
        }

        // Get the number of services
        uint256 numServices = serviceIds.length;
        // Loop over service Ids, accumulate donation value and check for the service existence
        for (uint256 i = 0; i < numServices; ++i) {
            // Check for the service Id existence
            if (!IServiceRegistry(serviceRegistry).exists(serviceIds[i])) {
                revert ServiceDoesNotExist(serviceIds[i]);
            }
        }
        // Get the current epoch
        uint256 curEpoch = epochCounter;
        // Increase the total service donation balance per epoch
        donationETH += mapEpochTokenomics[curEpoch].epochPoint.totalDonationsETH;
        mapEpochTokenomics[curEpoch].epochPoint.totalDonationsETH = uint96(donationETH);

        // Track service donations
        _trackServiceDonations(serviceIds, amounts, curEpoch);

        // Set the current block number
        lastDonationBlockNumber = uint32(block.number);
    }

    /// @dev Gets the inverse discount factor value.
    /// @param treasuryRewards Treasury rewards.
    /// @param numNewOwners Number of new owners of components / agents registered during the epoch.
    /// @return idf IDF value.
    function _calculateIDF(
        uint256 treasuryRewards,
        uint256 numNewOwners
    ) internal view returns (uint256 idf) {
        // Calculate the inverse discount factor based on the tokenomics parameters and values of units per epoch
        // df = 1 / (1 + iterest_rate), idf = (1 + iterest_rate) >= 1.0
        // Calculate IDF from epsilon rate and f(K,D)
        // f(K(e), D(e)) = d * k * K(e) + d * D(e),
        // where d corresponds to codePerDev and k corresponds to devPerCapital
        // codeUnits (codePerDev) is the estimated value of the code produced by a single developer for epoch
        UD60x18 codeUnits = UD60x18.wrap(codePerDev);
        // fKD = codeUnits * devsPerCapital * treasuryRewards + codeUnits * newOwners;
        // Convert all the necessary values to fixed-point numbers considering OLAS decimals (18 by default)
        UD60x18 fp = UD60x18.wrap(treasuryRewards);
        // Convert devsPerCapital
        UD60x18 fpDevsPerCapital = UD60x18.wrap(devsPerCapital);
        fp = fp.mul(fpDevsPerCapital);
        UD60x18 fpNumNewOwners = toUD60x18(numNewOwners);
        fp = fp.add(fpNumNewOwners);
        fp = fp.mul(codeUnits);
        // fp = fp / 100 - calculate the final value in fixed point
        fp = fp.div(UD60x18.wrap(100e18));
        // fKD in the state that is comparable with epsilon rate
        uint256 fKD = UD60x18.unwrap(fp);

        // Compare with epsilon rate and choose the smallest one
        if (fKD > epsilonRate) {
            fKD = epsilonRate;
        }
        // 1 + fKD in the system where 1e18 is equal to a whole unit (18 decimals)
        idf = 1e18 + fKD;
    }

    /// @dev Record global data with a new checkpoint.
    /// @notice Note that even though a specific epoch can last longer than the epochLen, it is practically
    ///         not valid not to call a checkpoint for longer than a year. Thus, the function will return false otherwise.
    /// @notice Checkpoint must not be called in the same block with the service donation.
    /// @return True if the function execution is successful.
    /// #if_succeeds {:msg "epochCounter can only increase"} $result == true ==> epochCounter == old(epochCounter) + 1;
    /// #if_succeeds {:msg "two events will never happen at the same time"} $result == true && (block.timestamp - timeLaunch) / ONE_YEAR > old(currentYear) ==> currentYear == old(currentYear) + 1;
    /// #if_succeeds {:msg "previous epoch endTime must never be zero"} mapEpochTokenomics[epochCounter - 1].epochPoint.endTime > 0;
    /// #if_succeeds {:msg "when the year is the same, the adjusted maxBond (incentives[4]) will never be lower than the epoch maxBond"}
    ///$result == true && (block.timestamp - timeLaunch) / ONE_YEAR == old(currentYear)
    /// ==> old((inflationPerSecond * (block.timestamp - mapEpochTokenomics[epochCounter - 1].epochPoint.endTime) * mapEpochTokenomics[epochCounter].epochPoint.maxBondFraction) / 100) >= old(maxBond);
    /// #if_succeeds {:msg "idf check"} $result == true ==> mapEpochTokenomics[epochCounter].epochPoint.idf >= 1e18 && mapEpochTokenomics[epochCounter].epochPoint.idf <= 18e18;
    /// #if_succeeds {:msg "devsPerCapital check"} $result == true ==> devsPerCapital > MIN_PARAM_VALUE;
    /// #if_succeeds {:msg "codePerDev check"} $result == true ==> codePerDev > MIN_PARAM_VALUE;
    /// #if_succeeds {:msg "sum of reward fractions must result in 100"} $result == true
    /// ==> mapEpochTokenomics[epochCounter].unitPoints[0].rewardUnitFraction + mapEpochTokenomics[epochCounter].unitPoints[1].rewardUnitFraction + mapEpochTokenomics[epochCounter].epochPoint.rewardTreasuryFraction == 100;
    function checkpoint() external returns (bool) {
        // Get the implementation address that was written to the proxy contract
        address implementation;
        assembly {
            implementation := sload(PROXY_TOKENOMICS)
        }
        // Check if there is any address in the PROXY_TOKENOMICS address slot
        if (implementation == address(0)) {
            revert DelegatecallOnly();
        }

        // Check the last donation block number to avoid the possibility of a flash loan attack
        if (lastDonationBlockNumber == block.number) {
            revert SameBlockNumberViolation();
        }

        // New point can be calculated only if we passed the number of blocks equal to the epoch length
        uint256 prevEpochTime = mapEpochTokenomics[epochCounter - 1].epochPoint.endTime;
        uint256 diffNumSeconds = block.timestamp - prevEpochTime;
        uint256 curEpochLen = epochLen;
        // Check if the time passed since the last epoch end time is bigger than the specified epoch length,
        // but not bigger than a year in seconds
        if (diffNumSeconds < curEpochLen || diffNumSeconds > ONE_YEAR) {
            return false;
        }

        uint256 eCounter = epochCounter;
        TokenomicsPoint storage tp = mapEpochTokenomics[eCounter];

        // 0: total incentives funded with donations in ETH, that are split between:
        // 1: treasuryRewards, 2: componentRewards, 3: agentRewards
        // OLAS inflation is split between:
        // 4: maxBond, 5: component ownerTopUps, 6: agent ownerTopUps
        uint256[] memory incentives = new uint256[](7);
        incentives[0] = tp.epochPoint.totalDonationsETH;
        incentives[1] = (incentives[0] * tp.epochPoint.rewardTreasuryFraction) / 100;
        // 0 stands for components and 1 for agents
        incentives[2] = (incentives[0] * tp.unitPoints[0].rewardUnitFraction) / 100;
        incentives[3] = (incentives[0] * tp.unitPoints[1].rewardUnitFraction) / 100;

        // The actual inflation per epoch considering that it is settled not in the exact epochLen time, but a bit later
        uint256 inflationPerEpoch;
        // Record the current inflation per second
        uint256 curInflationPerSecond = inflationPerSecond;
        // Current year
        uint256 numYears = (block.timestamp - timeLaunch) / ONE_YEAR;
        // Amounts for the yearly inflation change from year to year, so if the year changes in the middle
        // of the epoch, it is necessary to adjust epoch inflation numbers to account for the year change
        if (numYears > currentYear) {
            // Calculate remainder of inflation for the passing year
            // End of the year timestamp
            uint256 yearEndTime = timeLaunch + numYears * ONE_YEAR;
            // Initial inflation per epoch during the end of the year minus previous epoch timestamp
            inflationPerEpoch = (yearEndTime - prevEpochTime) * curInflationPerSecond;
            // Recalculate the inflation per second based on the new inflation for the current year
            curInflationPerSecond = getInflationForYear(numYears) / ONE_YEAR;
            // Add the remainder of inflation amount for this epoch based on a new inflation per second ratio
            inflationPerEpoch += (block.timestamp - yearEndTime) * curInflationPerSecond;
            // Updating state variables
            inflationPerSecond = uint96(curInflationPerSecond);
            currentYear = uint8(numYears);
            // Set the tokenomics parameters flag such that the maxBond is correctly updated below (3rd bit is set to one)
            tokenomicsParametersUpdated = tokenomicsParametersUpdated | 0x04;
        } else {
            // Inflation per epoch is equal to the inflation per second multiplied by the actual time of the epoch
            inflationPerEpoch = curInflationPerSecond * diffNumSeconds;
        }

        // Bonding and top-ups in OLAS are recalculated based on the inflation schedule per epoch
        // Actual maxBond of the epoch
        tp.epochPoint.totalTopUpsOLAS = uint96(inflationPerEpoch);
        incentives[4] = (inflationPerEpoch * tp.epochPoint.maxBondFraction) / 100;

        // Get the maxBond that was credited to effectiveBond during this settled epoch
        // If the year changes, the maxBond for the next epoch is updated in the condition below and will be used
        // later when the effectiveBond is updated for the next epoch
        uint256 curMaxBond = maxBond;

        // Effective bond accumulates bonding leftovers from previous epochs (with the last max bond value set)
        // It is given the value of the maxBond for the next epoch as a credit
        // The difference between recalculated max bond per epoch and maxBond value must be reflected in effectiveBond,
        // since the epoch checkpoint delay was not accounted for initially
        // This has to be always true, or incentives[4] == curMaxBond if the epoch is settled exactly at the epochLen time
        if (incentives[4] > curMaxBond) {
            // Adjust the effectiveBond
            incentives[4] = effectiveBond + incentives[4] - curMaxBond;
            effectiveBond = uint96(incentives[4]);
        }

        // Get the tokenomics point of the next epoch
        TokenomicsPoint storage nextEpochPoint = mapEpochTokenomics[eCounter + 1];
        // Update incentive fractions for the next epoch if they were requested by the changeIncentiveFractions() function
        // Check if the second bit is set to one
        if (tokenomicsParametersUpdated & 0x02 == 0x02) {
            // Confirm the change of incentive fractions
            emit IncentiveFractionsUpdated(eCounter + 1);
        } else {
            // Copy current tokenomics point into the next one such that it has necessary tokenomics parameters
            for (uint256 i = 0; i < 2; ++i) {
                nextEpochPoint.unitPoints[i].topUpUnitFraction = tp.unitPoints[i].topUpUnitFraction;
                nextEpochPoint.unitPoints[i].rewardUnitFraction = tp.unitPoints[i].rewardUnitFraction;
            }
            nextEpochPoint.epochPoint.rewardTreasuryFraction = tp.epochPoint.rewardTreasuryFraction;
            nextEpochPoint.epochPoint.maxBondFraction = tp.epochPoint.maxBondFraction;
        }
        // Update parameters for the next epoch, if changes were requested by the changeTokenomicsParameters() function
        // Check if the second bit is set to one
        if (tokenomicsParametersUpdated & 0x01 == 0x01) {
            // Update epoch length and set the next value back to zero
            if (nextEpochLen > 0) {
                curEpochLen = nextEpochLen;
                epochLen = uint32(curEpochLen);
                nextEpochLen = 0;
            }

            // Update veOLAS threshold and set the next value back to zero
            if (nextVeOLASThreshold > 0) {
                veOLASThreshold = nextVeOLASThreshold;
                nextVeOLASThreshold = 0;
            }

            // Confirm the change of tokenomics parameters
            emit TokenomicsParametersUpdated(eCounter + 1);
        }
        // Record settled epoch timestamp
        tp.epochPoint.endTime = uint32(block.timestamp);

        // Adjust max bond value if the next epoch is going to be the year change epoch
        // Note that this computation happens before the epoch that is triggered in the next epoch (the code above) when
        // the actual year changes
        numYears = (block.timestamp + curEpochLen - timeLaunch) / ONE_YEAR;
        // Account for the year change to adjust the max bond
        if (numYears > currentYear) {
            // Calculate the inflation remainder for the passing year
            // End of the year timestamp
            uint256 yearEndTime = timeLaunch + numYears * ONE_YEAR;
            // Calculate the inflation per epoch value until the end of the year
            inflationPerEpoch = (yearEndTime - block.timestamp) * curInflationPerSecond;
            // Recalculate the inflation per second based on the new inflation for the current year
            curInflationPerSecond = getInflationForYear(numYears) / ONE_YEAR;
            // Add the remainder of the inflation for the next epoch based on a new inflation per second ratio
            inflationPerEpoch += (block.timestamp + curEpochLen - yearEndTime) * curInflationPerSecond;
            // Calculate the max bond value
            curMaxBond = (inflationPerEpoch * nextEpochPoint.epochPoint.maxBondFraction) / 100;
            // Update state maxBond value
            maxBond = uint96(curMaxBond);
            // Reset the tokenomics parameters update flag
            tokenomicsParametersUpdated = 0;
        } else if (tokenomicsParametersUpdated > 0) {
            // Since tokenomics parameters have been updated, maxBond has to be recalculated
            curMaxBond = (curEpochLen * curInflationPerSecond * nextEpochPoint.epochPoint.maxBondFraction) / 100;
            // Update state maxBond value
            maxBond = uint96(curMaxBond);
            // Reset the tokenomics parameters update flag
            tokenomicsParametersUpdated = 0;
        }
        // Update effectiveBond with the current or updated maxBond value
        curMaxBond += effectiveBond;
        effectiveBond = uint96(curMaxBond);

        // Update the IDF value for the next epoch or assign a default one if there are no ETH donations
        if (incentives[0] > 0) {
            // Calculate IDF based on the incoming donations
            uint256 idf = _calculateIDF(incentives[1], tp.epochPoint.numNewOwners);
            nextEpochPoint.epochPoint.idf = uint64(idf);
            emit IDFUpdated(idf);
        } else {
            // Assign a default IDF value
            nextEpochPoint.epochPoint.idf = 1e18;
        }

        // Cumulative incentives
        uint256 accountRewards = incentives[2] + incentives[3];
        // Owner top-ups: epoch incentives for component owners funded with the inflation
        incentives[5] = (inflationPerEpoch * tp.unitPoints[0].topUpUnitFraction) / 100;
        // Owner top-ups: epoch incentives for agent owners funded with the inflation
        incentives[6] = (inflationPerEpoch * tp.unitPoints[1].topUpUnitFraction) / 100;
        // Even if there was no single donating service owner that had a sufficient veOLAS balance,
        // we still record the amount of OLAS allocated for component / agent owner top-ups from the inflation schedule.
        // This amount will appear in the EpochSettled event, and thus can be tracked historically
        uint256 accountTopUps = incentives[5] + incentives[6];

        // Treasury contract rebalances ETH funds depending on the treasury rewards
        if (incentives[1] == 0 || ITreasury(treasury).rebalanceTreasury(incentives[1])) {
            // Emit settled epoch written to the last economics point
            emit EpochSettled(eCounter, incentives[1], accountRewards, accountTopUps);
            // Start new epoch
            epochCounter = uint32(eCounter + 1);
        } else {
            // If the treasury rebalance was not executed correctly, the new epoch does not start
            revert TreasuryRebalanceFailed(eCounter);
        }

        return true;
    }

    /// @dev Gets component / agent owner incentives and clears the balances.
    /// @notice `account` must be the owner of components / agents Ids, otherwise the function will revert.
    /// @notice If not all `unitIds` belonging to `account` were provided, they will be untouched and keep accumulating.
    /// @notice Component and agent Ids must be provided in the ascending order and must not repeat.
    /// @param account Account address.
    /// @param unitTypes Set of unit types (component / agent).
    /// @param unitIds Set of corresponding unit Ids where account is the owner.
    /// @return reward Reward amount.
    /// @return topUp Top-up amount.
    function accountOwnerIncentives(address account, uint256[] memory unitTypes, uint256[] memory unitIds) external
        returns (uint256 reward, uint256 topUp)
    {
        // Check for the dispenser access
        if (dispenser != msg.sender) {
            revert ManagerOnly(msg.sender, dispenser);
        }

        // Check array lengths
        if (unitTypes.length != unitIds.length) {
            revert WrongArrayLength(unitTypes.length, unitIds.length);
        }

        // Component / agent registry addresses
        address[] memory registries = new address[](2);
        (registries[0], registries[1]) = (componentRegistry, agentRegistry);

        // Component / agent total supply
        uint256[] memory registriesSupply = new uint256[](2);
        for (uint256 i = 0; i < 2; ++i) {
            registriesSupply[i] = IToken(registries[i]).totalSupply();
        }

        // Check the input data
        uint256[] memory lastIds = new uint256[](2);
        for (uint256 i = 0; i < unitIds.length; ++i) {
            // Check for the unit type to be component / agent only
            if (unitTypes[i] > 1) {
                revert Overflow(unitTypes[i], 1);
            }

            // Check that the unit Ids are in ascending order, not repeating, and no bigger than registries total supply
            if (unitIds[i] <= lastIds[unitTypes[i]] || unitIds[i] > registriesSupply[unitTypes[i]]) {
                revert WrongUnitId(unitIds[i], unitTypes[i]);
            }
            lastIds[unitTypes[i]] = unitIds[i];

            // Check the component / agent Id ownership
            address unitOwner = IToken(registries[unitTypes[i]]).ownerOf(unitIds[i]);
            if (unitOwner != account) {
                revert OwnerOnly(unitOwner, account);
            }
        }

        // Get the current epoch counter
        uint256 curEpoch = epochCounter;

        for (uint256 i = 0; i < unitIds.length; ++i) {
            // Get the last epoch number the incentives were accumulated for
            uint256 lastEpoch = mapUnitIncentives[unitTypes[i]][unitIds[i]].lastEpoch;
            // Finalize unit rewards and top-ups if there were pending ones from the previous epoch
            // The finalization is needed when the trackServiceDonations() function did not take care of it
            // since between last epoch the donations were received and this current epoch there were no more donations
            if (lastEpoch > 0 && lastEpoch < curEpoch) {
                _finalizeIncentivesForUnitId(lastEpoch, unitTypes[i], unitIds[i]);
                // Change the last epoch number
                mapUnitIncentives[unitTypes[i]][unitIds[i]].lastEpoch = 0;
            }

            // Accumulate total rewards and clear their balances
            reward += mapUnitIncentives[unitTypes[i]][unitIds[i]].reward;
            mapUnitIncentives[unitTypes[i]][unitIds[i]].reward = 0;
            // Accumulate total top-ups and clear their balances
            topUp += mapUnitIncentives[unitTypes[i]][unitIds[i]].topUp;
            mapUnitIncentives[unitTypes[i]][unitIds[i]].topUp = 0;
        }
    }

    /// @dev Gets the component / agent owner incentives.
    /// @notice `account` must be the owner of components / agents they are passing, otherwise the function will revert.
    /// @param account Account address.
    /// @param unitTypes Set of unit types (component / agent).
    /// @param unitIds Set of corresponding unit Ids where account is the owner.
    /// @return reward Reward amount.
    /// @return topUp Top-up amount.
    function getOwnerIncentives(address account, uint256[] memory unitTypes, uint256[] memory unitIds) external view
        returns (uint256 reward, uint256 topUp)
    {
        // Check array lengths
        if (unitTypes.length != unitIds.length) {
            revert WrongArrayLength(unitTypes.length, unitIds.length);
        }

        // Component / agent registry addresses
        address[] memory registries = new address[](2);
        (registries[0], registries[1]) = (componentRegistry, agentRegistry);

        // Component / agent total supply
        uint256[] memory registriesSupply = new uint256[](2);
        for (uint256 i = 0; i < 2; ++i) {
            registriesSupply[i] = IToken(registries[i]).totalSupply();
        }

        // Check the input data
        uint256[] memory lastIds = new uint256[](2);
        for (uint256 i = 0; i < unitIds.length; ++i) {
            // Check for the unit type to be component / agent only
            if (unitTypes[i] > 1) {
                revert Overflow(unitTypes[i], 1);
            }

            // Check that the unit Ids are in ascending order, not repeating, and no bigger than registries total supply
            if (unitIds[i] <= lastIds[unitTypes[i]] || unitIds[i] > registriesSupply[unitTypes[i]]) {
                revert WrongUnitId(unitIds[i], unitTypes[i]);
            }
            lastIds[unitTypes[i]] = unitIds[i];

            // Check the component / agent Id ownership
            address unitOwner = IToken(registries[unitTypes[i]]).ownerOf(unitIds[i]);
            if (unitOwner != account) {
                revert OwnerOnly(unitOwner, account);
            }
        }

        // Get the current epoch counter
        uint256 curEpoch = epochCounter;

        for (uint256 i = 0; i < unitIds.length; ++i) {
            // Get the last epoch number the incentives were accumulated for
            uint256 lastEpoch = mapUnitIncentives[unitTypes[i]][unitIds[i]].lastEpoch;
            // Calculate rewards and top-ups if there were pending ones from the previous epoch
            if (lastEpoch > 0 && lastEpoch < curEpoch) {
                // Get the overall amount of unit rewards for the component's last epoch
                // reward = (pendingRelativeReward * rewardUnitFraction) / 100
                uint256 totalIncentives = mapUnitIncentives[unitTypes[i]][unitIds[i]].pendingRelativeReward;
                if (totalIncentives > 0) {
                    totalIncentives *= mapEpochTokenomics[lastEpoch].unitPoints[unitTypes[i]].rewardUnitFraction;
                    // Accumulate to the final reward for the last epoch
                    reward += totalIncentives / 100;
                }
                // Add the final top-up for the last epoch
                totalIncentives = mapUnitIncentives[unitTypes[i]][unitIds[i]].pendingRelativeTopUp;
                if (totalIncentives > 0) {
                    // Summation of all the unit top-ups and total amount of top-ups per epoch
                    // topUp = (pendingRelativeTopUp * totalTopUpsOLAS * topUpUnitFraction) / (100 * sumUnitTopUpsOLAS)
                    totalIncentives *= mapEpochTokenomics[lastEpoch].epochPoint.totalTopUpsOLAS;
                    totalIncentives *= mapEpochTokenomics[lastEpoch].unitPoints[unitTypes[i]].topUpUnitFraction;
                    uint256 sumUnitIncentives = uint256(mapEpochTokenomics[lastEpoch].unitPoints[unitTypes[i]].sumUnitTopUpsOLAS) * 100;
                    // Accumulate to the final top-up for the last epoch
                    topUp += totalIncentives / sumUnitIncentives;
                }
            }

            // Accumulate total rewards to finalized ones
            reward += mapUnitIncentives[unitTypes[i]][unitIds[i]].reward;
            // Accumulate total top-ups to finalized ones
            topUp += mapUnitIncentives[unitTypes[i]][unitIds[i]].topUp;
        }
    }

    /// @dev Gets inflation per last epoch.
    /// @return inflationPerEpoch Inflation value.
    function getInflationPerEpoch() external view returns (uint256 inflationPerEpoch) {
        inflationPerEpoch = inflationPerSecond * epochLen;
    }

    /// @dev Gets component / agent point of a specified epoch number and a unit type.
    /// @param epoch Epoch number.
    /// @param unitType Component (0) or agent (1).
    /// @return up Unit point.
    function getUnitPoint(uint256 epoch, uint256 unitType) external view returns (UnitPoint memory up) {
        up = mapEpochTokenomics[epoch].unitPoints[unitType];
    }

    /// @dev Gets inverse discount factor with the multiple of 1e18.
    /// @param epoch Epoch number.
    /// @return idf Discount factor with the multiple of 1e18.
    function getIDF(uint256 epoch) external view returns (uint256 idf)
    {
        idf = mapEpochTokenomics[epoch].epochPoint.idf;
        if (idf == 0) {
            idf = 1e18;
        }
    }

    /// @dev Gets inverse discount factor with the multiple of 1e18 of the last epoch.
    /// @return idf Discount factor with the multiple of 1e18.
    function getLastIDF() external view returns (uint256 idf)
    {
        idf = mapEpochTokenomics[epochCounter - 1].epochPoint.idf;
        if (idf == 0) {
            idf = 1e18;
        }
    }
}