// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import '../structs.sol';
import '../../interfaces/ILevelManager.sol';

library LevelsLibrary {
    function getAutoBaseAllocation(
        LevelsState storage self,
        uint256 totalPlannedRaise,
        uint256 whitelistAllocation
    ) internal view returns (uint256) {
        uint256 weights = self.totalWeights > 0 ? self.totalWeights : 1;
        uint256 levelsAlloc = totalPlannedRaise - whitelistAllocation;
        return levelsAlloc / weights;
    }

    function reachedMinBaseAllocation(
        LevelsState storage self,
        uint256 totalPlannedRaise,
        uint256 whitelistAllocation
    ) public view returns (bool) {
        if (self.minBaseAllocation == 0) {
            return false;
        }
        uint256 allocation = self.baseAllocation > 0
            ? self.baseAllocation
            : getAutoBaseAllocation(self, totalPlannedRaise, whitelistAllocation);

        return allocation < self.minBaseAllocation;
    }

    /**
     * Return: id, multiplier, allocation, isWinner.
     *
     * User is a winner when:
     * - winners were picked for the level
     * - user has non-zero weight (i.e. registered and not excluded as loser)
     * - the level is a lottery level
     */
    function getUserLevelState(
        LevelsState storage self,
        address account,
        bool levelsOpen,
        uint16 fcfsMultiplier
    )
        public
        view
        returns (
            string memory,
            uint256,
            uint256,
            bool
        )
    {
        bytes memory levelBytes = bytes(self.userLevel[account]);
        ILevelManager.Tier memory tier = levelsOpen
            ? self.levelManager.getUserTier(account)
            : self.levelManager.getTierById(levelBytes.length == 0 ? 'none' : self.userLevel[account]);

        // For non-registered in non-FCFS = 0
        uint256 weight = levelsOpen ? tier.multiplier : self.userWeight[account];
        uint256 allocation = weight * self.baseAllocation;

        allocation += (allocation * fcfsMultiplier) / 100;

        bool isWinner = levelBytes.length == 0
            ? false
            : tier.random && self.levelWinners[tier.id].length > 0 && self.userWeight[account] > 0;

        return (tier.id, weight, allocation, isWinner);
    }

    /**
     * Register a user with his current level multiplier.
     * Level multiplier is added to total weights, which later is used to calculate the base allocation.
     * Address is stored, so we can see all registered people.
     *
     * Later, when picking winners, loser weight is removed from total weights for correct base allocation calculation.
     */
    function register(
        LevelsState storage self,
        uint256 startTime,
        uint256 totalPlannedRaise,
        uint256 whitelistAllocation
    ) external returns (ILevelManager.Tier memory) {
        require(self.levelsEnabled, 'Sale: Cannot register, levels disabled');
        require(address(self.levelManager) != address(0), 'Sale: Levels staking address is not specified');

        address account = msg.sender;
        ILevelManager.Tier memory tier = self.levelManager.getUserTier(account);
        require(tier.multiplier > 0, 'Sale: Your level is too low to register');

        require(
            self.userWeight[account] == 0 ||
                (tier.multiplier >= self.userWeight[account] && !stringsEqual(tier.id, self.userLevel[account])),
            'Sale: Already registered with lower level'
        );
        // If user re-registers with higher level...
        if (self.userWeight[account] > 0) {
            self.totalWeights -= self.userWeight[account];
        }

        // Lock the staked tokens based on the current user level.
        if (self.lockOnRegister && self.userWeight[account] == 0) {
            self.levelManager.lock(account, tier.pool, startTime);
        }

        self.userLevel[account] = tier.id;
        self.userWeight[account] = tier.multiplier;
        self.totalWeights += tier.multiplier;
        self.levelAddresses[tier.id].push(account);

        // Allow the allocatino to drop below the level
        //        require(
        //            !reachedMinBaseAllocation(
        //                self,
        //                totalPlannedRaise,
        //                whitelistAllocation
        //            ),
        //            "Sale: Min base allocation reached, registration closed"
        //        );

        return tier;
    }

    function setWinners(
        LevelsState storage self,
        string calldata id,
        address[] calldata winners
    ) external {
        uint256 weight = self.levelManager.getTierById(id).multiplier;

        for (uint256 i = 0; i < self.levelAddresses[id].length; i++) {
            address addr = self.levelAddresses[id][i];
            // Skip users who re-registered
            if (!stringsEqual(self.userLevel[addr], id)) {
                continue;
            }
            self.totalWeights -= self.userWeight[addr];
            self.userWeight[addr] = 0;
        }

        for (uint256 i = 0; i < winners.length; i++) {
            address addr = winners[i];
            // Skip users who re-registered
            if (!stringsEqual(self.userLevel[addr], id)) {
                continue;
            }
            self.totalWeights += weight;
            self.userWeight[addr] = weight;
            self.userLevel[addr] = id;
        }
        self.levelWinners[id] = winners;
    }

    function batchRegisterLevel(
        LevelsState storage self,
        string memory tierId,
        uint256 weight,
        address[] calldata addresses
    ) external {
        for (uint256 i = 0; i < addresses.length; i++) {
            address account = addresses[i];

            if (self.userWeight[account] > 0) {
                self.totalWeights -= self.userWeight[account];
            }

            self.userLevel[account] = tierId;
            self.userWeight[account] = uint8(weight);
            self.totalWeights += weight;
            self.levelAddresses[tierId].push(account);
        }
    }

    function validateAllowanceGetAllocation(
        LevelsState storage self,
        address account,
        uint256 levelAllocation,
        bool levelsOpenAll,
        uint16 fcfsMultiplier
    ) public view returns (uint256) {
        if (!self.levelsEnabled) {
            return 0;
        }

        require(self.baseAllocation > 0, 'Sale: levels are enabled but baseAllocation is not set');

        // If opened for all levels, just return the level allocation without checking user weight
        if (levelsOpenAll) {
            (, , uint256 fcfsAllocation, ) = getUserLevelState(self, account, levelsOpenAll, fcfsMultiplier);
            require(fcfsAllocation > 0, 'Sale: user does not have FCFS allocation');

            return fcfsAllocation;
        }

        bytes memory levelBytes = bytes(self.userLevel[account]);
        require(levelBytes.length > 0, 'Sale: user level is not registered');
        require(
            levelAllocation > 0,
            'Sale: user has no level allocation, not registered, lost lottery or level is too low'
        );

        return levelAllocation;
    }

    function stringsEqual(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}