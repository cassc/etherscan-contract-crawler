// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import '../Adminable.sol';
import '../sale/Timed.sol';
import './WithWhitelist.sol';
import '../interfaces/ILevelManager.sol';
import './WithInventory.sol';
import './structs.sol';
import './libraries/LevelsLibrary.sol';

abstract contract WithLevelsSale is Adminable, Timed, WithInventory, WithWhitelist {
    using LevelsLibrary for LevelsState;

    LevelsState internal levelsState;

    event BaseAllocationCalculated(uint256 baseAllocation);
    event WinnersPicked(string tierId, uint256 totalN, uint256 winnersN, address[] winners);
    event Registered(address indexed account, string levelId, uint256 weight, bool tokensLocked);
    event MinAllowedLevelMultiplierChanged(uint256 multiplier);

    constructor(ILevelManager _levelManager, uint256 _minAllowedLevelMultiplier) {
        levelsState.levelsEnabled = true;
        levelsState.lockOnRegister = true;
        setLevelManager(_levelManager);
        setMinAllowedLevelMultiplier(_minAllowedLevelMultiplier);
    }

    function levelsOpenAll() public view returns (bool) {
        return levelsState.forceLevelsOpenAll || isFcfsTime();
    }

    function levelsEnabled() public view returns (bool) {
        return levelsState.levelsEnabled;
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
        return levelsState.reachedMinBaseAllocation(totalPlannedRaise(), whitelistAllocation());
    }

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
        return levelsState.getUserLevelState(account, levelsOpenAll(), getFcfsAllocationMultiplier());
    }

    /**
     * Returns multiplier for FCFS allocation, with 2 decimals. 1x = 100
     * The result allocation will be = baseAllocation + baseAllocation * fcfsMultiplier
     * When forceLevelsOpenAll is enabled, registered users get 2x allocation, non-registered 1x.
     */
    function getFcfsAllocationMultiplier() public view returns (uint16) {
        if (levelsState.forceLevelsOpenAll) {
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
            return 35;
        }
        // 15-30 minutes
        if (block.timestamp < fcfsStartTime + quarterTime * 2) {
            return 80;
        }
        // 30-45 minutes
        if (block.timestamp < fcfsStartTime + quarterTime * 3) {
            return 200;
        }
        // last 15 minutes - 100x
        return 10000;
    }

    function autoBaseAllocation() external view returns (uint256) {
        return levelsState.getAutoBaseAllocation(totalPlannedRaise(), whitelistAllocation());
    }

    function baseAllocation() external view returns (uint256) {
        return levelsState.baseAllocation;
    }

    function minBaseAllocation() external view returns (uint256) {
        return levelsState.minBaseAllocation;
    }

    function totalWeights() external view returns (uint256) {
        return levelsState.totalWeights;
    }

    function getUserLevelAllocation(address account) public view returns (uint256) {
        return levelsState.userWeight[account] * levelsState.baseAllocation;
    }

    function getLevelAddresses(string calldata id) external view returns (address[] memory) {
        return levelsState.levelAddresses[id];
    }

    function getLevelWinners(string calldata id) external view returns (address[] memory) {
        return levelsState.levelWinners[id];
    }

    function getLevelNumbers() external view returns (string[] memory, uint256[] memory) {
        string[] memory ids = levelsState.levelManager.getTierIds();
        uint256[] memory counts = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            counts[i] = levelsState.levelAddresses[ids[i]].length;
        }
        return (ids, counts);
    }

    function getLevelNumber(string calldata id) external view returns (uint256) {
        return levelsState.levelAddresses[id].length;
    }

    function toggleLevels(bool status) external onlyOwnerOrAdmin {
        levelsState.levelsEnabled = status;
    }

    function openForAllLevels(bool status) external onlyOwnerOrAdmin {
        levelsState.forceLevelsOpenAll = status;
    }

    function toggleLockOnRegister(bool status) external onlyOwnerOrAdmin {
        levelsState.lockOnRegister = status;
    }

    function setBaseAllocation(uint256 _baseAllocation) external onlyOwnerOrAdmin {
        levelsState.baseAllocation = _baseAllocation;
    }

    function setMinBaseAllocation(uint256 value) external onlyOwnerOrAdmin {
        levelsState.minBaseAllocation = value;
    }

    function setLevelManager(ILevelManager _levelManager) public onlyOwnerOrAdmin {
        levelsState.levelManager = _levelManager;
    }

    function setMinAllowedLevelMultiplier(uint256 multiplier) public onlyOwnerOrAdmin {
        levelsState.minAllowedLevelMultiplier = multiplier;
    }

    /**
     * Find the new base allocation based on total weights of all levels, # of whitelisted accounts and their max buy.
     * Should be called after winners are picked.
     */
    function updateBaseAllocation() external onlyOwnerOrAdmin {
        levelsState.baseAllocation = levelsState.getAutoBaseAllocation(totalPlannedRaise(), whitelistAllocation());

        emit BaseAllocationCalculated(levelsState.baseAllocation);
    }

    /**
     * Register a user with his current level multiplier.
     * Level multiplier is added to total weights, which later is used to calculate the base allocation.
     * Address is stored, so we can see all registered people.
     *
     * Later, when picking winners, loser weight is removed from total weights for correct base allocation calculation.
     */
    function register() external ongoingRegister {
        ILevelManager.Tier memory tier = levelsState.register(startTime, totalPlannedRaise(), whitelistAllocation());

        emit Registered(msg.sender, tier.id, tier.multiplier, levelsState.lockOnRegister);
    }

    function setWinners(string calldata id, address[] calldata winners) external onlyOwnerOrAdmin {
        levelsState.setWinners(id, winners);

        emit WinnersPicked(id, levelsState.levelAddresses[id].length, winners.length, winners);
    }

    function batchRegisterLevel(
        string memory tierId,
        uint256 weight,
        address[] calldata addresses
    ) external onlyOwnerOrAdmin {
        levelsState.batchRegisterLevel(tierId, weight, addresses);
    }
}