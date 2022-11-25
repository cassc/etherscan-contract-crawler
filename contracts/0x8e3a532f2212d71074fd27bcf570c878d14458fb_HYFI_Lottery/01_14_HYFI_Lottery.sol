// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@hyfi-corp/vault/contracts/interfaces/IHYFI_Vault.sol";
import "./interfaces/IHYFI_RewardsManager.sol";

// solhint-disable-next-line contract-name-camelcase
contract HYFI_Lottery is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    struct RewardsData {
        uint256 totalAmount;
        uint256 freeAmount;
        IHYFI_RewardsManager rewardManager;
    }

    struct RewardsSetData {
        uint256 rangeMin;
        uint256 rangeMax;
        uint256[] rewards;
    }

    struct GuaranteedRewardsSetData {
        uint256 rangeMin;
        uint256 rangeMax;
        uint256[] rewards;
    }

    /// @dev PAUSER_ROLE role identifier, PAUSER_ROLE is responsible to pause/unpause Lottery
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @dev max number from all ranges in rewards set, starts from 0
    uint256 internal _rangeMax;

    /// @dev max number from all ranges in guaranteed rewards set, starts from 0
    uint256 internal _guaranteedRangeMax;

    /// @dev the number of Vaults which should be opened at once to have Guaranteed rewards sets
    uint256 internal _guaranteedThreshold;

    /// @dev Vault smart contract (lottery tickets nfts)
    IHYFI_Vault internal _vault;

    /**
     * @dev the array with information about each reward using struct RewardsData
     *
     *      totalAmount - total amount of specific reward
     *      freeAmount - the remaining available amount of rewards
     *      rewardManager is smart contract responsible for revealing specific reward, follow interface IHYFI_RewardsManager
     */
    RewardsData[] internal _rewards;

    /**
     * @dev the array with information about each rewards set using struct RewardsSetData
     *
     *      rangeMin-rangeMax - is a range that the random number should fall into.
     *      rewards - array of rewards ids if the current set is in play
     *      so the structure in hyfi will be:
     *      0 => {0, 1, 20_000, 20_000, [1, 0, 1, 0, 0, 0, 0]}
     *          0,1 - range (20% probability),
     *          amount 20_000,
     *          rewards: [1, 0, 1, 0, 0, 0, 0] mean 1*Athena + 1*Pro + 0 other rewards
     *      1 => {2, 3, 20_000, 20_000, [1, 0, 1, 0, 0, 0, 0]}
     *          2,3 - range (20% probability),
     *          amount 20_000,
     *          rewards: [0, 1, 0, 1, 0, 0, 0] mean 1*AthenaAccess + 1*Ultimate + 0 other rewards
     *      2 => {4, 6, 30_000, 20_000, [1, 0, 1, 0, 0, 0, 0]}
     *          4,6 - range (30% probability),
     *          amount 30_000,
     *          rewards: [0, 1, 1, 0, 1, 0, 1] mean 1*AthenaAccess + 1*Pro + 1*HYFI50 + Voucher
     *      3 => {4, 6, 30_000, 20_000, [1, 0, 1, 0, 0, 0, 0]}
     *          7,9 - range (30% probability),
     *          amount 30_000,
     *          rewards: [0, 1, 1, 0, 0, 1, 1] mean 1*AthenaAccess + 1*Pro + 1*HYFI100 + Voucher
     */
    RewardsSetData[] internal _rewardsSets;

    /**
     * @dev the array with information about each guaranteed rewards set using struct GuaranteedRewardsSetData
     *
     *      rangeMin-rangeMax (reflection of Probability to win this set)- is a range that the random number should fall into.
     *      example HYFI guaranteed rewards are A + UM + 4*AA + 3*(HYFI50 | HYFI100) + 3*V
     *      it means that we have two guaranteed sets:
     *      0 | A + UM + 4*AA + 3*HYFI50 + 3*V | 50%
     *      1 | A + UM + 4*AA + 3*HYFI100 + 3*V| 50%
     *      if we have two guaranteed sets of rewards with probability 50/50,
     *      it should be range 0-0 for the first guaranteed set and 1-1 for the second one
     *      if the generated number from 0 to _guaranteedRangeMax is in the set range - we generate for user this set of rewards
     *      rewards - array of rewards where key is rewardId and value is amount of Rewards
     *      so in hyfi the structure will be:
     *      0 => {0,0,[1,4,0,1,3,0,3]} -
     *          0,0 means 50% probability,
     *          [1,4,0,1,3,0,3] - mean A + UM + 4*AA + 3*HYFI50 + 3*V
     *      0 => {1,1,[1,4,0,1,0,3,3]} -
     *          1,1 means 50% probability,
     *          [1,4,0,1,0,3,3] - mean A + UM + 4*AA + 3*HYFI100 + 3*V
     */
    GuaranteedRewardsSetData[] internal _guaranteedRewardsSets;

    /**
     * @dev event on successful vaults revealing
     * @param user the user address
     * @param vaultIds the vault ids user revealed
     * @param rewards the array with rewards where key is reward ID and value is amount of rewards which should be transfered to user
     */
    event VaultsRevealed(address user, uint256[] vaultIds, uint256[] rewards);

    /**
     * @dev check if rewards array length is correct
     * @param rewards the array with rewards
     */
    modifier checkRewardsLength(uint256[] memory rewards) {
        require(
            rewards.length == _rewards.length,
            "Rewards array length is incorrect"
        );
        _;
    }

    /**
     * @dev check if user owns more(or equal) vaults than amount
     * @param revealAmount the amount of vaults
     */
    modifier checkUserOwnsVaultsAmount(uint256 revealAmount) {
        require(
            revealAmount <= _vault.balanceOf(msg.sender),
            "User owns less vaults"
        );
        _;
    }

    /**
     * @dev check if user owns all vaults among array vaultIds
     * @param vaultIds the ids of the vaults
     */
    modifier checkUserOwnsVaultsIds(uint256[] memory vaultIds) {
        bool userIsOwner = true;
        for (uint256 i = 0; i < vaultIds.length; i++) {
            if (_vault.ownerOf(vaultIds[i]) != msg.sender) {
                userIsOwner = false;
                break;
            }
        }
        require(userIsOwner, "User is not owner of some vault");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev initializer
     */
    function initialize() external virtual initializer {
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    /**
     * @dev pause Lottery, tickets can not be revealed when paused
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev unpause Lottery, tickets can be revealed
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev set the new Vault NFT smart contract address
     * @param newVault the new Vault address
     */
    function setVaultAddress(
        address newVault
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _vault = IHYFI_Vault(newVault);
    }

    /**
     * @dev set the new guaranteed threshold value, the number of vaults should be revealed at once
     * @param newThreshold the new guaranteed threshold value. If user reveals this amount of tickets at once - he will have guaranteed set of rewards
     */
    function setGuaranteedThreshold(
        uint256 newThreshold
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _guaranteedThreshold = newThreshold;
    }

    /**
     * @dev set the new maximum range value, it will be used in random generator
     * @param newRangeMax the new max value in the normalized range of rewards sets
     */
    function setRangeMax(
        uint256 newRangeMax
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _rangeMax = newRangeMax;
    }

    /**
     * @dev set the new maximum guaranteed range value, it will be used in random generator
     * @param newRangeMax the new max value in the normalized range in guaranteed rewards sets
     */
    function setGuaranteedRangeMax(
        uint256 newRangeMax
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _guaranteedRangeMax = newRangeMax;
    }

    /**
     * @dev add new reward information
     * @param rewardManager the address of reward manager responsible for rewards revealing logic
     * @param totalAmount the total available amount of such type of rewards
     */
    function addReward(
        address rewardManager,
        uint256 totalAmount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        RewardsData memory reward;
        reward.rewardManager = IHYFI_RewardsManager(rewardManager);
        reward.totalAmount = totalAmount;
        reward.freeAmount = totalAmount;
        _rewards.push(reward);
    }

    /**
     * @dev update reward information
     * @param rewardManager the address of reward manager responsible for rewards revealing logic
     * @param totalAmount the total available amount of such type of rewards
     * @param resetFreeAmount true if the freeAmount value for this reward should be reset
     */
    function updateReward(
        uint256 rewardId,
        address rewardManager,
        uint256 totalAmount,
        bool resetFreeAmount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        RewardsData storage reward = _rewards[rewardId];
        reward.rewardManager = IHYFI_RewardsManager(rewardManager);
        reward.totalAmount = totalAmount;
        if (resetFreeAmount) {
            reward.freeAmount = totalAmount;
        }
    }

    /**
     * @dev delete the last reward from array
     */
    function deleteRewardTop() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _rewards.pop();
    }

    /**
     * @dev add new reward set data. Each reward set has probability (reslected in range), total amount and rewards
     * @param range array with min and max in range, for probability reflection, if the normalized range is 0-9, so the range 0-1 reflects probability 20%
     * @param rewards array of rewards, where key is rewardId and value is reward amount
     */
    function addRewardsSet(
        uint256[2] memory range,
        uint256[] memory rewards
    ) external onlyRole(DEFAULT_ADMIN_ROLE) checkRewardsLength(rewards) {
        RewardsSetData memory rewardsSet;
        rewardsSet.rangeMin = range[0];
        rewardsSet.rangeMax = range[1];
        rewardsSet.rewards = rewards;
        _rewardsSets.push(rewardsSet);
    }

    /**
     * @dev update rewardsSet data
     * @param range array with min and max in range, for probability reflection, if the normalized range is 0-9, so the range 0-1 reflects probability 20%
     * @param rewards array of rewards, where key is rewardId and value is reward amount
     */
    function updateRewardsSet(
        uint256 rewardsSetId,
        uint256[2] memory range,
        uint256[] memory rewards
    ) external onlyRole(DEFAULT_ADMIN_ROLE) checkRewardsLength(rewards) {
        RewardsSetData storage rewardsSet = _rewardsSets[rewardsSetId];
        rewardsSet.rangeMin = range[0];
        rewardsSet.rangeMax = range[1];
        rewardsSet.rewards = rewards;
    }

    /**
     * @dev delete the last reward set from array
     */
    function deleteRewardsSetTop() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _rewardsSets.pop();
    }

    /**
     * @dev add new guaranteed reward set data
     * @param range array with min and max in range, for probability reflection, if the normalized range is 0-9, so the range 0-1 reflects probability 20%
     * @param rewards array of rewards, where key is rewardId and value is reward amount
     */
    function addGuaranteedRewardsSet(
        uint256[2] memory range,
        uint256[] memory rewards
    ) external onlyRole(DEFAULT_ADMIN_ROLE) checkRewardsLength(rewards) {
        GuaranteedRewardsSetData memory guaranteedRewardsSet;
        guaranteedRewardsSet.rangeMin = range[0];
        guaranteedRewardsSet.rangeMax = range[1];
        guaranteedRewardsSet.rewards = rewards;
        _guaranteedRewardsSets.push(guaranteedRewardsSet);
    }

    /**
     * @dev update guaranteed reward set data
     * @param range array with min and max in range, for probability reflection, if the normalized range is 0-9, so the range 0-1 reflects probability 20%
     * @param rewards array of rewards, where key is rewardId and value is reward amount
     */
    function updateGuaranteedRewardsSet(
        uint256 guaranteedRewardsSetId,
        uint256[2] memory range,
        uint256[] memory rewards
    ) external onlyRole(DEFAULT_ADMIN_ROLE) checkRewardsLength(rewards) {
        GuaranteedRewardsSetData
            storage guaranteedRewardsSet = _guaranteedRewardsSets[
                guaranteedRewardsSetId
            ];
        guaranteedRewardsSet.rangeMin = range[0];
        guaranteedRewardsSet.rangeMax = range[1];
        guaranteedRewardsSet.rewards = rewards;
    }

    /**
     * @dev delete the last guaranteed reward set from array
     */
    function deleteGuaranteedRewardsSetTop()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _guaranteedRewardsSets.pop();
    }

    /**
     * @dev reveal specific amount of vaults, user is able to reveal such amount only if he has enough vaults
     * @param revealAmount the number of vauls user is going to reveal
     */
    function revealVaults(
        uint256 revealAmount
    ) external whenNotPaused checkUserOwnsVaultsAmount(revealAmount) {
        require(revealAmount > 0, "Zero amount is going to reveal");

        uint256[] memory userVaultsIds = new uint256[](revealAmount);

        for (uint256 i = 0; i < revealAmount; i++) {
            userVaultsIds[i] = _vault.tokenOfOwnerByIndex(msg.sender, i);
        }
        _revealSpecificVaults(userVaultsIds);
    }

    /**
     * @dev reveal specific vaults by ids, user is able to reveal only if he owns all selected vault ids
     * @param vaultIds the array with vault numbers(ids) user is going to reveal
     */
    function revealSpecificVaults(
        uint256[] memory vaultIds
    ) external whenNotPaused checkUserOwnsVaultsIds(vaultIds) {
        _revealSpecificVaults(vaultIds);
    }

    /**
     * @dev get the information about specific reward
     * @param rewardId the id of reward
     * @return return totalAmount
     * @return return freeAmount
     * @return return reward manager address
     */
    function getReward(
        uint256 rewardId
    ) external view returns (uint256, uint256, address) {
        return (
            _rewards[rewardId].totalAmount,
            _rewards[rewardId].freeAmount,
            address(_rewards[rewardId].rewardManager)
        );
    }

    /**
     * @dev get the information about specific rewardsSet
     * @param rewardSetId the id of rewardSet
     * @return return rangeMin
     * @return return rangeMax
     * @return return rewards array
     */
    function getRewardsSet(
        uint256 rewardSetId
    ) external view returns (uint256, uint256, uint256[] memory) {
        return (
            _rewardsSets[rewardSetId].rangeMin,
            _rewardsSets[rewardSetId].rangeMax,
            _rewardsSets[rewardSetId].rewards
        );
    }

    /**
     * @dev get the information about specific guaranteed rewards Set
     * @param guaranteedRewardsSetId the id of guaranteed rewards Set
     * @return return rangeMin
     * @return return rangeMax
     * @return return rewards array
     */
    function getGuaranteedRewardsSet(
        uint256 guaranteedRewardsSetId
    ) external view returns (uint256, uint256, uint256[] memory) {
        return (
            _guaranteedRewardsSets[guaranteedRewardsSetId].rangeMin,
            _guaranteedRewardsSets[guaranteedRewardsSetId].rangeMax,
            _guaranteedRewardsSets[guaranteedRewardsSetId].rewards
        );
    }

    /**
     * @dev get the maximum range value, it is used in random generator
     * @return return max value in the normalized range of rewards sets
     */
    function getRangeMax() external view returns (uint256) {
        return _rangeMax;
    }

    /**
     * @dev get the maximum guaranteed range value, it is used in random generator
     * @return return max value in the normalized range of guaranteed rewards sets
     */
    function getGuaranteedRangeMax() external view returns (uint256) {
        return _guaranteedRangeMax;
    }

    /**
     * @dev get the guaranteed threshold - the number of tickets should be open all at once to have guaranteed rewards
     * @return return guaranteed threshold
     */
    function getGuaranteedThreshold() external view returns (uint256) {
        return _guaranteedThreshold;
    }

    /**
     * @dev get the Vault NFT smart contracts address
     * @return return vault address
     */
    function getVaultAddress() external view returns (address) {
        return address(_vault);
    }

    /**
     * @dev get array of user Vault ids (lottery ticket numbers)
     * @return return user address
     */
    function getUserVaultIds(
        address user
    ) external view returns (uint256[] memory) {
        uint256 tokensAmount = _vault.balanceOf(user);
        uint256[] memory tokenIds = new uint256[](tokensAmount);
        for (uint256 i = 0; i < tokensAmount; i++) {
            tokenIds[i] = _vault.tokenOfOwnerByIndex(user, i);
        }
        return tokenIds;
    }

    /**
     * @dev calculate the rewards set id with available rewards during revealing the ticket #vaultId
     * @param vaultId vault ID is going to be revealed. used as salt for random generation
     * @return return winning rewardsSet Id
     */
    function getWinningRewardsSetId(
        uint256 vaultId
    ) public view returns (uint256) {
        uint256 randomValue = getRandomValueN(vaultId, (_rangeMax + 1)); // 0 - 9
        uint256 j;
        uint256 rewardSetId;
        for (uint256 i = 0; i < _rewardsSets.length; i++) {
            if (
                randomValue >= _rewardsSets[i].rangeMin &&
                randomValue <= _rewardsSets[i].rangeMax
            ) {
                // do the loop in order to find available rewards set (all rewards within the set should have free amount > 0) strating from id = i
                // if some rewards are occupied in selected set - find next reward set which have all rewards available, move to the left
                // if we have 4 rewards sets - 0,1,2,3 and the random value is in the range from the reward set #2
                // it will check check availability in rewards sets in such order: 2,3,0,1
                for (j = 0; j < _rewardsSets.length; j++) {
                    rewardSetId = (i + j) % _rewardsSets.length;
                    if (isRewardsSetAvailable(rewardSetId)) {
                        return rewardSetId;
                    }
                }
            }
        }
        revert("No available rewards sets");
    }

    /**
     * @dev calculate the winning guaranteed set with sufficient available rewards and return rewards of guaranteed set
     * @param packNumber the order number of guaranteed pack is going to be revealed, used as salt for random generator
     * @return return array where key is rewardsSet id and value is amount of won rewardsSets
     */
    function getWinningGuaranteedRewards(
        uint256 packNumber
    ) public view returns (uint256[] memory) {
        uint256[] memory emptyRewards;
        // if the length is 1 it means that all guaranteed rewards have 100% probability
        if (_guaranteedRewardsSets.length == 1) {
            if (
                areSpecificRewardsAvailable(_guaranteedRewardsSets[0].rewards)
            ) {
                return _guaranteedRewardsSets[0].rewards;
            } else {
                return emptyRewards;
            }
        }

        // the logic for guaranteed rewards if they have probabilities
        uint256 randomValue = getRandomValueN(
            packNumber,
            _guaranteedRangeMax + 1
        );
        uint256 j;
        uint256 guaranteedSetId;
        for (uint256 i = 0; i < _guaranteedRewardsSets.length; i++) {
            if (
                randomValue >= _guaranteedRewardsSets[i].rangeMin &&
                randomValue <= _guaranteedRewardsSets[i].rangeMax
            ) {
                // do the loop in order to find available guaranteed rewards set (all rewards within set shoud have needed free amount)
                // strating from id = i
                // if no free amount in selected range - find next reward set which has free available rewards, move to the left
                // if we have 2 guaranteed rewards sets - 0,1 and the random value is in the range from the reward set #1
                // it will check availability in rewards sets in such order: 1,0
                for (j = 0; j < _guaranteedRewardsSets.length; j++) {
                    guaranteedSetId = (i + j) % _guaranteedRewardsSets.length;
                    if (
                        areSpecificRewardsAvailable(
                            _guaranteedRewardsSets[guaranteedSetId].rewards
                        )
                    ) {
                        return _guaranteedRewardsSets[guaranteedSetId].rewards;
                    }
                }
            }
        }
        return emptyRewards;
    }

    /**
     * @dev check if there is enough amount of rewards
     * @param id the id of the reward  (starts from 0)
     * @param amount the amount of rewards is needed to check for availability
     * @return return true if rewards are available and there are still free items >= the needed amount
     */
    function isRewardAvailable(
        uint256 id,
        uint256 amount
    ) public view returns (bool) {
        return _rewards[id].freeAmount >= amount;
    }

    /**
     * @dev check if there is enough amount of rewards in specific rewardsSet
     * @param id the id of the rewards set  (starts from 0)
     * @return return true if rewards set is available and there are all rewards needed available
     */
    function isRewardsSetAvailable(uint256 id) public view returns (bool) {
        return areSpecificRewardsAvailable(_rewardsSets[id].rewards);
    }

    /**
     * @dev check if there are enough amount of rewards
     * @param rewards the array of rewards needed to be checked, key is reward Id and value is amount of needed rewards
     * @return return true if all rewards in the array are available
     */
    function areSpecificRewardsAvailable(
        uint256[] memory rewards
    ) public view returns (bool) {
        bool isAvailable = true;
        for (uint256 i = 0; i < rewards.length; i++) {
            isAvailable = isAvailable && isRewardAvailable(i, rewards[i]);
        }
        return isAvailable;
    }

    /**
     * @dev get random value using seed, can be used for rewards sets and guaranteed rewards probabilities
     * @param seed the salt for randomness
     * @param normalized the value for normalization
     * @return return random value, normalized
     */
    function getRandomValueN(
        uint256 seed,
        uint256 normalized
    ) public view returns (uint256) {
        /* solhint-disable not-rely-on-time */
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender,
                        seed
                    )
                )
            ) % normalized;
        /* solhint-enable not-rely-on-time */
    }

    /**
     * @dev calculate the max possible amount of guaranteed packs, if amount=21, the max possible amount of guaranteed packs will be 4 (4*5=20)
     * @param amount the amount of vaults are going to be revealed
     * @return return max amount of guaranteed packs
     */
    function getGuaranteedPacksAmount(
        uint256 amount
    ) public view returns (uint256) {
        return amount / _guaranteedThreshold;
    }

    /**
     * @dev calculate the number of vaults are needed to be revealed one-by-one, if vaults amount is 23, 3 tickets should be revealed one-by-one (23%5) or (23 - 4*5)
     * @param amount the amount of vaults are going to be revealed
     * @return return amount of vaults needed to be revealed one-by-one
     */
    function getOneByOneAmount(uint256 amount) public view returns (uint256) {
        return amount % _guaranteedThreshold;
    }

    /**
     * @dev common logic for revealing vaults by their ids and generating rewards (reward manager is responsible for rewards generation logic)
     * @param vaultIds the array with vault numbers(ids) need to be revealed
     * @return return array of user rewards where key is rewardId and value is won rewards amount
     */
    function _revealSpecificVaults(
        uint256[] memory vaultIds
    ) internal returns (uint256[] memory) {
        uint256 revealAmount = vaultIds.length;
        // calculate number of guaranteed sets (how many times we open tickets by 5(_guaranteedThreshold) at once)
        // if user opens 23 tickets at once, guaranteedSetsAmount should be 4 (4 times by 5 tickets = 20)
        // and oneByOneAmount will be 3 (3 tickets should be opened one by one)
        uint256 guaranteedPacksAmount = getGuaranteedPacksAmount(revealAmount);

        // get amount of each reward's set, won by user during revealing guaranteed amount
        (
            uint256[] memory userGuaranteedRewards,
            uint256 processedGuaranteedPacksAmount
        ) = _processGuaranteedPacks(guaranteedPacksAmount);

        // if guaranteed packs were not be processed completely (not enough guaranteed rewards), the rest should be processed one by one
        // if user opens 23 tickets at once, guaranteedPacksAmount should be 4 (4 times by 5 tickets = 20)
        // but only two guaranteed packs were processed - it means that oneByOneAmount will be 3 + (4-2)*5 = 13
        uint256 oneByOneAmount = getOneByOneAmount(revealAmount) +
            (guaranteedPacksAmount - processedGuaranteedPacksAmount) *
            _guaranteedThreshold;

        uint256[] memory userVaultsIdsOneByOne = new uint256[](oneByOneAmount);
        // get the array of vault ids which should be reveald one by one (for simplicity the first ones in the array are used)
        for (uint256 i = 0; i < oneByOneAmount; i++) {
            userVaultsIdsOneByOne[i] = vaultIds[i];
        }
        // get amount of each reward's set, won by user during revealing one by one tickets
        uint256[] memory userRewardsSetsOneByOne = _processVaultsOneByOne(
            userVaultsIdsOneByOne
        );

        uint256[] memory userRewards = new uint256[](_rewards.length);
        uint256 rewardSetId;

        for (uint256 rewardId = 0; rewardId < userRewards.length; rewardId++) {
            for (
                rewardSetId = 0;
                rewardSetId < userRewardsSetsOneByOne.length;
                rewardSetId++
            ) {
                if (userRewardsSetsOneByOne[rewardSetId] > 0) {
                    userRewards[rewardId] +=
                        _rewardsSets[rewardSetId].rewards[rewardId] *
                        userRewardsSetsOneByOne[rewardSetId];
                }
            }
            userRewards[rewardId] += userGuaranteedRewards[rewardId];
            if (userRewards[rewardId] > 0) {
                _rewards[rewardId].rewardManager.revealRewards(
                    msg.sender,
                    userRewards[rewardId],
                    rewardId
                );
            }
        }

        emit VaultsRevealed(msg.sender, vaultIds, userRewards);

        _burnVaults(vaultIds);
        return userRewards;
    }

    /**
     * @dev logic for revealing tickets one by one (define winning reward set ID per each vault and mark rewards from this set as occupied)
     * @param vaultIds array of vault IDs are going to be revealed
     * @return return array where key is rewardsSet id and value is amount of won rewardsSets
     */
    function _processVaultsOneByOne(
        uint256[] memory vaultIds
    ) internal returns (uint256[] memory) {
        uint256[] memory userRewardsSets = new uint256[](_rewardsSets.length);
        for (uint256 i = 0; i < vaultIds.length; i++) {
            uint256 winningRewardsSetId = getWinningRewardsSetId(vaultIds[i]);
            _holdSpecificRewards(_rewardsSets[winningRewardsSetId].rewards);
            userRewardsSets[winningRewardsSetId]++;
        }
        return userRewardsSets;
    }

    /**
     * @dev processing logic for revealing vaults as guaranteed (packs of _guaranteedThreshold), defining rewards per each pack and mark them as occupied
     * @param guaranteedPacksAmount the amount of guaranteed packs are going to be revealed
     * @return return memory array where key is rewardsSet id and value is amount of won rewardsSets
     * @return return amount of processed packs. it is possible that some packs can not be processed as guaranteed, because of insufficiency of some rewards
     */
    function _processGuaranteedPacks(
        uint256 guaranteedPacksAmount
    ) internal returns (uint256[] memory, uint256) {
        // is used on each iteration, stores won amount of each reward
        uint256[] memory rewardsAmounstById = new uint256[](_rewards.length);
        // is used to calculate total won amounts of each reward
        uint256[] memory totalRewardsAmounstById = new uint256[](
            _rewards.length
        );
        uint256 j;
        uint256 i;
        for (i = 0; i < guaranteedPacksAmount; i++) {
            rewardsAmounstById = getWinningGuaranteedRewards(i);

            if (rewardsAmounstById.length == 0) {
                //the last pack was not able to be proccessed, go out from loop
                break;
            }
            _holdSpecificRewards(rewardsAmounstById);

            for (j = 0; j < rewardsAmounstById.length; j++) {
                totalRewardsAmounstById[j] += rewardsAmounstById[j];
            }
        }
        return (totalRewardsAmounstById, i);
    }

    /**
     * @dev mark rewards as occipied (decrease free amount)
     * @param rewards the array of rewards needed to me marked as occipied, key is reward Id and value is amount of rewards
     */
    function _holdSpecificRewards(uint256[] memory rewards) internal {
        for (uint256 i = 0; i < rewards.length; i++) {
            _rewards[i].freeAmount -= rewards[i];
        }
    }

    /**
     * @dev internal logic for burning several vaults
     */
    function _burnVaults(uint256[] memory vaultIds) internal {
        for (uint256 i = 0; i < vaultIds.length; i++) {
            _vault.burn(vaultIds[i]);
        }
    }
}