// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import '../Adminable.sol';
import '../sale/Timed.sol';
import './GeneralIDO.sol';
import './WithWhitelist.sol';
import './WithLimits.sol';
import '../interfaces/ILevelManager.sol';

// TODO: adjust the code for decimal multipliers
abstract contract WithLevelsSale is Adminable, Timed, GeneralIDO, WithLimits, WithWhitelist {
    uint16 public constant FCFS_1 = 50;
    uint16 public constant FCFS_2 = 100;
    uint16 public constant FCFS_3 = 200;
    uint16 public constant FCFS_4 = 10000;

    uint16 public constant WEIGHT_DECIMALS = 1000;

    ILevelManager public levelManager;
    bool public levelsEnabled = true;
    bool public forceLevelsOpenAll = false;
    bool public lockOnRegister = true;

    // Sum of weights (lottery losers are subtracted when picking winners) for base allocation calculation.
    // Contains 4 decimals (based on level manager), so divide by 1000.
    uint256 public totalWeights;
    // Base allocation is 1x in TOKENS
    uint256 public baseAllocation;
    // 0 - all levels, 6 - starting from "associate", etc
    uint256 public minAllowedLevelMultiplier;
    // Min allocation in TOKENS after registration closes. If 0, then ignored
    uint256 public minBaseAllocation;

    mapping(string => address[]) public levelAddresses;
    // Whether (and how many) winners were picked for a lottery level
    mapping(string => address[]) public levelWinners;
    // Needed for user allocation calculation = baseAllocation * userWeight
    // If user lost lottery, his weight resets to 0 - means user can't participate in sale
    // Contains 4 decimals (based on level manager), so divide by 1000.
    mapping(address => uint256) public userWeight;
    mapping(address => string) public userLevel;

    event BaseAllocationCalculated(uint256 baseAllocation);
    event WinnersPicked(string tierId, uint256 totalN, uint256 winnersN, address[] winners);
    event Registered(address indexed account, string levelId, uint256 weight, bool tokensLocked);

    constructor(ILevelManager _levelManager, uint256 _minAllowedLevelMultiplier) {
        setLevelManager(_levelManager);
        setMinAllowedLevelMultiplier(_minAllowedLevelMultiplier);
    }

    function levelsOpenAll() public view returns (bool) {
        return forceLevelsOpenAll || isFcfsTime();
    }

    modifier ongoingRegister() {
        require(!isLive(), 'Sale: Cannot register, sale is live');

        require(!reachedMinBaseAllocation(), 'Sale: Min base allocation reached, registration closed');
        require(isRegistering(), 'Sale: Not open for registration');
        _;
    }

    function isRegisterTime() internal view returns (bool) {
        return block.timestamp > registerTime && block.timestamp < registerTime + registerDuration;
    }

    function isRegistering() public view returns (bool) {
        return isRegisterTime() && !reachedMinBaseAllocation();
    }

    function reachedMinBaseAllocation() public view returns (bool) {
        if (minBaseAllocation == 0) {
            return false;
        }
        uint256 allocation = baseAllocation > 0 ? baseAllocation : getAutoBaseAllocation();

        return allocation < minBaseAllocation;
    }

    /**
     * Return: id, multiplier, allocation, isWinner.
     *
     * User is a winner when:
     * - winners were picked for the level
     * - user has non-zero weight (i.e. registered and not excluded as loser)
     * - the level is a lottery level
     */
    function getUserLevelState(address account)
        public
        view
        returns (
            string memory,
            uint256,
            uint256,
            bool
        )
    {
        bool levelsOpen = levelsOpenAll();

        bytes memory levelBytes = bytes(userLevel[account]);
        ILevelManager.Tier memory tier = levelsOpen
            ? levelManager.getUserTier(account)
            : levelManager.getTierById(levelBytes.length == 0 ? 'none' : userLevel[account]);

        // For non-registered in non-FCFS = 0
        uint256 weight = levelsOpen ? tier.multiplier : userWeight[account];
        uint256 allocation = (weight * baseAllocation) / WEIGHT_DECIMALS;

        uint16 fcfsMultiplier = getFcfsAllocationMultiplier();
        if (fcfsMultiplier > 0) {
            uint256 fcfsAlloc = (allocation * fcfsMultiplier) / 100;

            if (userWeight[account] > 0 || !stringsEqual(userLevel[account], 'none')) {
                // Registered (and lost lottery) user gets lvlX + 35%/80%/...
                allocation = allocation + fcfsAlloc;
            } else if (fcfsMultiplier >= FCFS_3) {
                // OTHERWISE user didn't register at all - they can participate only starting from the FCFS round 3
                allocation = fcfsAlloc;
            } else {
                allocation = 0;
            }
        }

        bool isWinner = levelBytes.length == 0
            ? false
            : tier.random && levelWinners[tier.id].length > 0 && userWeight[account] > 0;

        return (tier.id, weight, allocation, isWinner);
    }

    /**
     * Returns multiplier for FCFS allocation, with 2 decimals. 1x = 100
     * The result allocation will be = baseAllocation + baseAllocation * fcfsMultiplier
     * When forceLevelsOpenAll is enabled, registered users get 2x allocation, non-registered 1x.
     */
    function getFcfsAllocationMultiplier() public view returns (uint16) {
        if (forceLevelsOpenAll) {
            return 100;
        }
        if (!isFcfsTime()) {
            return 0;
        }

        // Let's imagine the fcfs duration is 60 minutes, then...
        uint256 fcfsStartTime = getEndTime() - fcfsDuration;
        uint256 quarterTime = fcfsDuration / 4;
        // first 15 minutes
        if (block.timestamp < fcfsStartTime + quarterTime) {
            return FCFS_1;
        }
        // 15-30 minutes
        if (block.timestamp < fcfsStartTime + quarterTime * 2) {
            return FCFS_2;
        }
        // 30-45 minutes
        if (block.timestamp < fcfsStartTime + quarterTime * 3) {
            return FCFS_3;
        }
        // last 15 minutes - 100x
        return FCFS_4;
    }

    function getUserLevelAllocation(address account) public view returns (uint256) {
        return (userWeight[account] * baseAllocation) / WEIGHT_DECIMALS;
    }

    function getLevelAddresses(string calldata id) external view returns (address[] memory) {
        return levelAddresses[id];
    }

    function getLevelWinners(string calldata id) external view returns (address[] memory) {
        return levelWinners[id];
    }

    function getLevelNumbers() external view returns (string[] memory, uint256[] memory) {
        string[] memory ids = levelManager.getTierIds();
        uint256[] memory counts = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            counts[i] = levelAddresses[ids[i]].length;
        }
        return (ids, counts);
    }

    function getLevelNumber(string calldata id) external view returns (uint256) {
        return levelAddresses[id].length;
    }

    function toggleLevels(bool status) external onlyOwnerOrAdmin {
        levelsEnabled = status;
    }

    function openForAllLevels(bool status) external onlyOwnerOrAdmin {
        forceLevelsOpenAll = status;
    }

    function toggleLockOnRegister(bool status) external onlyOwnerOrAdmin {
        lockOnRegister = status;
    }

    function setBaseAllocation(uint256 _baseAllocation) external onlyOwnerOrAdmin {
        baseAllocation = _baseAllocation;
    }

    function setMinBaseAllocation(uint256 value) external onlyOwnerOrAdmin {
        minBaseAllocation = value;
    }

    function setLevelManager(ILevelManager _levelManager) public onlyOwnerOrAdmin {
        levelManager = _levelManager;
    }

    function setMinAllowedLevelMultiplier(uint256 multiplier) public onlyOwnerOrAdmin {
        minAllowedLevelMultiplier = multiplier;
    }

    function getAutoBaseAllocation() public view returns (uint256) {
        uint256 weights = totalWeights > 0 ? totalWeights : 1;
        uint256 levelsAlloc = tokensForSale - whitelistAllocation();
        return (levelsAlloc * WEIGHT_DECIMALS) / weights;
    }

    /**
     * Find the new base allocation based on total weights of all levels, # of whitelisted accounts and their max buy.
     * Should be called after winners are picked.
     */
    function updateBaseAllocation() external onlyOwnerOrAdmin {
        baseAllocation = getAutoBaseAllocation();

        emit BaseAllocationCalculated(baseAllocation);
    }

    /**
     * Register a user with his current level multiplier.
     * Level multiplier is added to total weights, which later is used to calculate the base allocation.
     * Address is stored, so we can see all registered people.
     *
     * Later, when picking winners, loser weight is removed from total weights for correct base allocation calculation.
     */
    function register() external ongoingRegister {
        require(levelsEnabled, 'Sale: Cannot register, levels disabled');
        require(address(levelManager) != address(0), 'Sale: Levels staking address is not specified');

        address account = _msgSender();
        ILevelManager.Tier memory tier = levelManager.getUserTier(account);
        require(tier.multiplier > 0, 'Sale: Your level is too low to register');
        require(
            minAllowedLevelMultiplier == 0 || tier.multiplier >= minAllowedLevelMultiplier,
            'Sale: Your level is too low to register'
        );

        require(
            userWeight[account] == 0 ||
                (tier.multiplier >= userWeight[account] && !stringsEqual(tier.id, userLevel[account])),
            'Sale: Already registered'
        );
        // If user re-registers with higher level...
        if (userWeight[account] > 0) {
            totalWeights -= userWeight[account];
        }

        // Lock the staked tokens based on the current user level.
        if (lockOnRegister && userWeight[account] == 0) {
            levelManager.lock(account, tier.pool, startTime);
        }

        userLevel[account] = tier.id;
        userWeight[account] = tier.multiplier;
        totalWeights += tier.multiplier;
        levelAddresses[tier.id].push(account);

        emit Registered(account, tier.id, tier.multiplier, lockOnRegister);
    }

    function setWinners(string calldata id, address[] calldata winners) external onlyOwnerOrAdmin {
        uint256 weight = levelManager.getTierById(id).multiplier;

        for (uint256 i = 0; i < levelAddresses[id].length; i++) {
            address addr = levelAddresses[id][i];
            // Skip users who re-registered
            if (!stringsEqual(userLevel[addr], id)) {
                continue;
            }
            totalWeights -= userWeight[addr];
            userWeight[addr] = 0;
        }

        for (uint256 i = 0; i < winners.length; i++) {
            address addr = winners[i];
            // Skip users who re-registered
            if (!stringsEqual(userLevel[addr], id)) {
                continue;
            }
            totalWeights += weight;
            userWeight[addr] = weight;
            userLevel[addr] = id;
        }
        levelWinners[id] = winners;

        emit WinnersPicked(id, levelAddresses[id].length, winners.length, winners);
    }

    function batchRegisterLevel(
        string memory tierId,
        address[] calldata addresses,
        uint256[] calldata weights
    ) external onlyOwnerOrAdmin {
        ILevelManager.Tier memory tier;

        for (uint256 i = 0; i < addresses.length; i++) {
            address account = addresses[i];
            totalWeights -= userWeight[account];
            userLevel[account] = tierId;
            userWeight[account] = weights[i];
            totalWeights += userWeight[account];
            levelAddresses[tierId].push(account);
        }
    }
}