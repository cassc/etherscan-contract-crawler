// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./WhiteRabbitSteak.sol";

/**
 * This contract allows users with steak NFTs to stake and earn $WRAB on a bonding curve
 * where the longer they steak, the more rewards they get.
 */
contract CookShop is Ownable, ERC721Holder {
    // The Steak NFT contract which can be staked
    WhiteRabbitSteak public steakContract;
    // The $WRAB token contract which is used for rewards
    IERC20 public wrabTokenContract;

    // Mapping owner address to staked token count
    mapping(address => uint256) private _stakedCount;
    // Mapping from owner to list of staked token IDs
    mapping(address => mapping(uint256 => uint256)) private _stakedTokens;
    // Mapping from token ID to index of the staked tokens list
    mapping(uint256 => uint256) private _stakedTokensIndex;

    // Mapping token ID to when it was last staked, used to determine $WRAB rewards
    mapping(uint256 => uint256) public tokenIdToLastStakedTimestamp;
    // Timestamp for when staking rewards expire
    uint256 public stakingEndTimestamp;
    // Timestamp for when staking rewards start
    uint256 public stakingStartTimestamp;

    // Mapping from owner to token IDs which are staked
    mapping(address => mapping(uint256 => bool))
        private _userAddressToStakedSteaksTokenIdMap;

    // Total allocation of $WRAB tokens that can be issued as rewards
    uint256 private _wrabTokenForRewardsAllocation;
    // Minimum reward per Steak NFT
    uint256 private _baseWrabMaxRewardPerSteak;
    // Merkle root to verify rarity multipliers for each Steak NFT
    bytes32 private _merkleRoot;

    constructor(address steakContract_, address wrabTokenContract_) {
        steakContract = WhiteRabbitSteak(steakContract_);
        wrabTokenContract = IERC20(wrabTokenContract_);
    }

    /**
     * @dev The number of Steak NFTs that have been staked by the given address
     * @param staker address representing the staker
     */
    function numStakedSteaks(address staker) public view returns (uint256) {
        return _stakedCount[staker];
    }

    /**
     * @dev Used to access each token that has been staked by the given address.
     * For example, we can get the `numStakedSteaks` for the given address, and then
     * iterate through each index (e.g. 0, 1, 2) to get the IDs of each staked token.
     * @param staker address representing the staker
     * @param index index of the token (e.g. first staked token will have index of 0)
     */
    function tokenOfStakerByIndex(address staker, uint256 index)
        public
        view
        returns (uint256)
    {
        return _stakedTokens[staker][index];
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param staker address representing the staker of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToStakedEnumeration(address staker, uint256 tokenId)
        private
    {
        uint256 length = _stakedCount[staker];

        _stakedTokens[staker][length] = tokenId;
        _stakedTokensIndex[tokenId] = length;
        _userAddressToStakedSteaksTokenIdMap[staker][tokenId] = true;
        _stakedCount[staker] += 1;
        tokenIdToLastStakedTimestamp[tokenId] = block.timestamp;
    }

    /**
     * @dev Private function to remove a token from this contract's staked-tracking data structures.
     * This has O(1) time complexity, but alters the order of the _stakedTokens array.
     * See https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721Enumerable.sol#L134
     * @param staker address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromStakedEnumeration(address staker, uint256 tokenId)
        private
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).
        uint256 lastTokenIndex = _stakedCount[staker] - 1;
        uint256 tokenIndex = _stakedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _stakedTokens[staker][lastTokenIndex];

            _stakedTokens[staker][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _stakedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _stakedTokensIndex[tokenId];
        delete _stakedTokens[staker][lastTokenIndex];

        _userAddressToStakedSteaksTokenIdMap[staker][tokenId] = false;
        _stakedCount[staker] -= 1;
        tokenIdToLastStakedTimestamp[tokenId] = 0;
    }

    /**
     * @dev Sets the merkle root used to verify rarity multipliers
     * @param merkleRoot_ the merkle root hash
     */
    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        _merkleRoot = merkleRoot_;
    }

    /**
     * @dev Sets the parameters used to determine $WRAB rewards for staking
     * @param wrabTokenForRewardsAllocation_ allocation of $WRAB tokens that can be issued as rewards
     * @param stakingStartTime_ when staking starts
     * @param stakingEndTime_ when staking ends
     */
    function setSteakingRewardsParams(
        uint256 wrabTokenForRewardsAllocation_,
        uint256 stakingStartTime_,
        uint256 stakingEndTime_
    ) external onlyOwner {
        require(
            stakingEndTime_ > stakingStartTime_,
            "staking end time must be before start time"
        );
        // NB: we multiply by 10^18 to handle fractional values, since
        // Solidity doesn't support division with floating point numbers.
        // This means we need to handle the division by 10^18 on the client.
        _wrabTokenForRewardsAllocation =
            wrabTokenForRewardsAllocation_ *
            10**18;
        _baseWrabMaxRewardPerSteak =
            _wrabTokenForRewardsAllocation /
            steakContract.totalSupply();
        stakingStartTimestamp = stakingStartTime_;
        stakingEndTimestamp = stakingEndTime_;
    }

    /**
     * @dev Calculates the bonding curve.
     * Note that the rarity multiplier is formatted like `100` for `1x`,
     * `120` for 1.2x, etc. which is why we have to divide by 100 below.
     * @param rarityMultiplier the multiplier determined by rarity
     * Math: calculating the a in y=ax where y is the reward per second, x is time, a is the curve variable
     * the area under the curve then is the total reward
     */
    function steakingRewardsBondingCurve(uint256 rarityMultiplier)
        public
        view
        returns (uint256)
    {
        uint256 maxTokenAvailable = (_baseWrabMaxRewardPerSteak *
            rarityMultiplier) / 100;
        uint256 _totalSteakingPeriodInSeconds = stakingEndTimestamp -
            stakingStartTimestamp;
        uint256 maxRewardPerSecond = (2 * maxTokenAvailable) /
            _totalSteakingPeriodInSeconds;

        return maxRewardPerSecond / _totalSteakingPeriodInSeconds;
    }

    /**
     * @dev Calculates the rewards for a given rarity after a given time staked.
     * This function can be used on to estimate future or hypothetical rewards.
     * This function is a pure math function that disregards valid start/end time
     * @param rarityMultiplier the multiplier determined by rarity
     * @param timeSteaked the amount of time staked in seconds
     */
    function steakingRewardsForRarity(
        uint256 rarityMultiplier,
        uint256 timeSteaked
    ) public view returns (uint256) {
        uint256 currentRewardPerSecond = timeSteaked *
            steakingRewardsBondingCurve(rarityMultiplier);
        return (timeSteaked * currentRewardPerSecond) / 2;
    }

    /**
     * @dev Calculates the rewards for a tokenId with given rarity based on how long its been staked.
     * This function is used to calculate how much rewards user can claim
     * @param tokenId the tokenId
     * @param rarityMultiplier the rarity multiplier according to the steak
     */
    function steakingRewardsForTokenId(
        uint256 tokenId,
        uint256 rarityMultiplier
    ) public view returns (uint256) {
        uint256 stakeStartTimeForToken = tokenIdToLastStakedTimestamp[tokenId];
        require(stakeStartTimeForToken != 0, "steak has not been staked");
        uint256 validStakedDuration = _min(
            block.timestamp,
            stakingEndTimestamp
        ) - stakeStartTimeForToken;

        return steakingRewardsForRarity(rarityMultiplier, validStakedDuration);
    }

    function _min(uint256 a, uint256 b) private pure returns (uint256) {
        return a <= b ? a : b;
    }

    /**
     * @dev Calculates the rewards for a tokenId with given rarity based on how long its been staked.
     * This function is used to calculate how much rewards user can claim
     * @param tokenId the tokenId
     * @param rarityMultiplier the rarity multiplier according to the steak
     */
    function _merkleLeafForTokenIdAndRarityMultiplier(
        uint256 tokenId,
        uint256 rarityMultiplier
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenId, rarityMultiplier));
    }

    /**
     * @dev Stake steaks users have in their wallet
     * @param tokenIds array of the Steak tokenIds users have in their wallet
     * notes: staking allows users with steaks to earn $WRAB rewards over time
     * users can stake multiple steaks at once in their wallet
     * users can unstake steaks at any time
     */
    function stake(uint256[] calldata tokenIds) public {
        require(
            block.timestamp >= stakingStartTimestamp,
            "staking not available"
        );
        require(block.timestamp < stakingEndTimestamp, "staking ended");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            require(
                steakContract.ownerOf(tokenId) == msg.sender,
                "can't stake steak you don't own"
            );

            _addTokenToStakedEnumeration(msg.sender, tokenId);
            steakContract.safeTransferFrom(
                msg.sender,
                address(this),
                tokenId,
                ""
            );
        }
    }

    /**
     * @dev Unstakes the given token IDs and claim $WRAB rewards.
     * Merkle proofs are used to validate rarityMultipliers and prevent users
     * from claiming more rewards than they are supposed to from the contract
     * directly by inputting a false rarity multiplier.
     */

    function _unstake(
        uint256[] calldata tokenIds,
        uint256[] calldata rarityMultipliers,
        bytes32[][] calldata merkleProofs,
        bool revertIfNotEnoughWRAB
    ) public {
        require(
            _stakedCount[msg.sender] >= tokenIds.length,
            "invalid tokenIds length"
        );

        uint256 rewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            require(
                _userAddressToStakedSteaksTokenIdMap[msg.sender][tokenId],
                "no steak to unstake"
            );

            uint256 rarityMultiplier = rarityMultipliers[i];
            bytes32[] memory merkleProof = merkleProofs[i];

            require(
                MerkleProof.verify(
                    merkleProof,
                    _merkleRoot,
                    _merkleLeafForTokenIdAndRarityMultiplier(
                        tokenId,
                        rarityMultiplier
                    )
                ),
                "invalid rarity multiplier"
            );

            steakContract.transferFrom(address(this), msg.sender, tokenId);
            rewards += steakingRewardsForTokenId(tokenId, rarityMultiplier);
            _removeTokenFromStakedEnumeration(msg.sender, tokenId);
        }
        if (revertIfNotEnoughWRAB) {
            require(
                wrabTokenContract.balanceOf(address(this)) >= rewards,
                "not enough tokens in contract, contact team"
            );
            wrabTokenContract.transfer(msg.sender, rewards);
        }
        // else unstake even if there isn't enough wrab in the contract
    }

    /**
     * @dev Unstakes the given token IDs and claim $WRAB rewards.
     * Merkle proofs are used to validate rarityMultipliers and prevent users
     * from claiming more rewards than they are supposed to from the contract
     * directly by inputting a false rarity multiplier.
     * This function is used to unstake steaks and claim rewards
     */
    function unstake(
        uint256[] calldata tokenIds,
        uint256[] calldata rarityMultipliers,
        bytes32[][] calldata merkleProofs
    ) public {
        _unstake(tokenIds, rarityMultipliers, merkleProofs, true);
    }

    /**
     * @dev Unstakes the given token IDs and claim $WRAB rewards.
     * Same as above functiuon but allows unstaking without rewards so steaks won't be stuck just in case we run out of WRAB
     * If there is enough WRAB, this will behave same as above function, user get steak back into their wallets with rewards
     * If there is not enough WRAB, user will still get steak back but no WRAB rewards, and won't be able to claim again.
     * DO NOT CALL UNLESS INSTRUCTED BY TEAM, YOU WILL LOSE YOUR ACCUMULATED REWARDS
     */
    function unstakeEscapeHatch_DONOTCALLL(
        uint256[] calldata tokenIds,
        uint256[] calldata rarityMultipliers,
        bytes32[][] calldata merkleProofs
    ) public {
        _unstake(tokenIds, rarityMultipliers, merkleProofs, false);
    }

    /**
     * @dev Withraw excess tokens left in the contract
     */
    function withdraw(address add, uint256 amount) external onlyOwner {
        wrabTokenContract.transfer(add, amount);
    }
}