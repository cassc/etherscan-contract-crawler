// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ERC721Holder} from "openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Holder.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {EnumerableSet} from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {IDelegationRegistry} from "delegation-registry/IDelegationRegistry.sol";
import "./Structs.sol";

/**
 * __/\\\\\\\\\\\\\\\__/\\\\\\\\\\\\\\\_______/\\\\\____________/\\\\\______
 *  _\///////\\\/////__\///////\\\/////______/\\\///\\\________/\\\///\\\____
 *   _______\/\\\_____________\/\\\_________/\\\/__\///\\\____/\\\/__\///\\\__
 *    _______\/\\\_____________\/\\\________/\\\______\//\\\__/\\\______\//\\\_
 *     _______\/\\\_____________\/\\\_______\/\\\_______\/\\\_\/\\\_______\/\\\_
 *      _______\/\\\_____________\/\\\_______\//\\\______/\\\__\//\\\______/\\\__
 *       _______\/\\\_____________\/\\\________\///\\\__/\\\_____\///\\\__/\\\____
 *        _______\/\\\_____________\/\\\__________\///\\\\\/________\///\\\\\/_____
 *         _______\///______________\///_____________\/////____________\/////_______
 */

/**
 * <<<       Join the Family       >>>
 * <<<     https://ttoonft.io/     >>>
 * <<< https://twitter.com/ttoonft >>>
 * @title   This Thing Of Ours Staking
 * @notice  Lock TTOO NFTs for a variable period of time
 * @dev     Grants delegate.cash delegation to users for their deposited token
 * @author  BowTiedPickle
 * @custom:contributor  Lumoswiz
 */
contract TTOOStaking is Ownable, ERC721Holder {
    // ----- Libraries -----

    using EnumerableSet for EnumerableSet.UintSet;

    // ----- Immutables -----

    /// @notice This Thing Of Ours NFT token
    IERC721 public immutable nft;

    /// @notice Delegation Registry
    IDelegationRegistry public immutable delegationRegistry;

    // ----- Storage variables -----

    /// @notice Owner specified staking lock periods.
    EnumerableSet.UintSet internal lockTimes;

    /// @notice Records staker info (number staked & set of tokenIds)
    mapping(address => EnumerableSet.UintSet) internal stakedTokenIds;

    /// @notice Records owner and unlock time for a tokenId
    /// @dev mapping tokenId => locked token info
    mapping(uint256 => LockInfo) public lockInfos;

    // ----- Constructor -----

    /**
     * @param   _NFTAddress             Address for This Thing Of Ours ERC-721 token
     * @param   _times                  An array of initial staking lock times to set
     * @param   _delegationRegistry     Address for the Delegation Registry
     */
    constructor(
        address _NFTAddress,
        uint256[] memory _times,
        address _delegationRegistry
    ) {
        if (_times.length == 0) revert TTOOStaking__RequireAtLeastOneLockTime();
        nft = IERC721(_NFTAddress);
        delegationRegistry = IDelegationRegistry(_delegationRegistry);

        for (uint256 i; i < _times.length; ) {
            lockTimes.add(_times[i]);

            unchecked {
                ++i;
            }
        }
    }

    // ----- User actions -----

    /**
     * @notice  Stake an NFT
     * @param   tokenId     The tokenId to stake
     * @param   lockTime    The period of time to lock the NFT for, in seconds
     */
    function stake(uint256 tokenId, uint256 lockTime) external {
        _stake(tokenId, lockTime);
    }

    /**
     * @notice  Unstake an NFT
     * @dev     NFT locking period must have elapsed in order to unstake
     * @param   tokenId     The tokenId to unstake
     */
    function unstake(uint256 tokenId) external {
        _unstake(tokenId);
    }

    /**
     * @notice  Stake multiple NFTS
     * @param   inputs      Array of StakeMultipleInputs structs containing (tokenId, lockTime) pairs.
     */
    function stakeMultiple(StakeMultipleInputs[] calldata inputs) external {
        for (uint256 i; i < inputs.length; ) {
            _stake(inputs[i].tokenId, inputs[i].lockTime);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice  Unstake multiple NFTs
     * @dev     All NFT locking periods must have elapsed in order to unstake
     * @param   tokenIds     Array of tokenIds to unstake
     */
    function unstakeMultiple(uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length; ) {
            _unstake(tokenIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    // ----- Owner functions -----

    /**
     * @notice  Add a lock duration to the list of valid times
     * @param   time     New lockup duration in seconds
     */
    function addLockTime(uint256 time) external onlyOwner {
        lockTimes.add(time);

        emit UpdateLockTime(msg.sender, time, true);
    }

    /**
     * @notice  Add multiple lock durations to the list of valid times
     * @param   times   An array of new lockup durations in seconds
     */
    function addMultipleLockTimes(uint256[] calldata times) external onlyOwner {
        for (uint256 i; i < times.length; ) {
            lockTimes.add(times[i]);

            emit UpdateLockTime(msg.sender, times[i], true);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice  Remove a lock duration from the list of valid times
     * @param   time    Lockup duration in seconds to remove
     */
    function removeLockTime(uint256 time) external onlyOwner {
        if (lockTimes.length() <= 1)
            revert TTOOStaking__RequireAtLeastOneLockTime();

        lockTimes.remove(time);

        emit UpdateLockTime(msg.sender, time, false);
    }

    /**
     * @notice  Remove multiple lock durations from the list of valid times
     * @param   times   Array of lockup durations in seconds to remove
     */
    function removeMultipleLockTimes(
        uint256[] calldata times
    ) external onlyOwner {
        if (lockTimes.length() <= times.length)
            revert TTOOStaking__RequireAtLeastOneLockTime();

        for (uint256 i; i < times.length; ) {
            lockTimes.remove(times[i]);

            emit UpdateLockTime(msg.sender, times[i], false);

            unchecked {
                ++i;
            }
        }
    }

    // ----- Internal utilities -----

    /**
     * @dev     Stakes the NFT `tokenId` for a period `lockTime`.
     * @param   tokenId     The tokenId to be staked
     * @param   lockTime    The period of time to lock the tokenId for (in seconds)
     */
    function _stake(uint256 tokenId, uint256 lockTime) internal {
        // Check caller is owner
        if (nft.ownerOf(tokenId) != msg.sender)
            revert TTOOStaking__NotNFTOwner();

        // Check lockTime is in lockTimes set
        if (!lockTimes.contains(lockTime))
            revert TTOOStaking__NonexistentLockTime();

        // Update lock info state
        uint256 _unlockAt = block.timestamp + lockTime;
        lockInfos[tokenId].owner = msg.sender;
        lockInfos[tokenId].unlockAt = uint48(_unlockAt);

        // Update staker staked tokenIds
        stakedTokenIds[msg.sender].add(tokenId);

        // Add delegate for token
        delegationRegistry.delegateForToken(
            msg.sender,
            address(nft),
            tokenId,
            true
        );

        // Transfers NFT from staker to this address
        nft.safeTransferFrom(msg.sender, address(this), tokenId);

        emit Stake(msg.sender, tokenId, _unlockAt);
    }

    /**
     * @notice  Unstakes the NFT 'tokenId' from this staking contract.
     * @param   tokenId     The tokenId to unstake
     */
    function _unstake(uint256 tokenId) internal {
        // Check the NFT is currently being staked and is owned by caller
        if (lockInfos[tokenId].owner != msg.sender)
            revert TTOOStaking__NotStakedOrOwner();

        // Check that the NFT lock period is over
        if (lockInfos[tokenId].unlockAt > block.timestamp)
            revert TTOOStaking__LockPeriodNotOver();

        // Update lock info state
        delete lockInfos[tokenId];

        // Update staker staked tokenIds
        stakedTokenIds[msg.sender].remove(tokenId);

        // Remove delegate for token
        delegationRegistry.delegateForToken(
            msg.sender,
            address(nft),
            tokenId,
            false
        );

        // Transfer NFT to the recipient
        nft.safeTransferFrom(address(this), msg.sender, tokenId);

        emit Unstake(msg.sender, tokenId);
    }

    // ----- View functions -----

    /**
     * @notice  Returns true if `time` is in the lockTimes set
     * @param   time     The time to check
     */
    function isValidLockTime(uint256 time) external view returns (bool) {
        return lockTimes.contains(time);
    }

    /**
     * @notice  Returns the array of lockTimes in the set
     */
    function getLockTimes() external view returns (uint256[] memory) {
        return lockTimes.values();
    }

    /**
     * @notice  Returns the unlock timestamp (Unix epoch seconds) of a staked token, or 0 if it is not staked
     */
    function getUnlockTime(uint256 tokenId) external view returns (uint256) {
        return lockInfos[tokenId].unlockAt;
    }

    /**
     * @notice  Returns the numer of NFTs a user has staked
     * @param   staker     Address of the staker to return info for
     */
    function getUserStakedCount(
        address staker
    ) external view returns (uint256) {
        return stakedTokenIds[staker].length();
    }

    /**
     * @notice  Returns the staked tokenIds and unlock times for a user
     * @param   staker     Address of the staker to return info for
     */
    function getUserStakingInfo(
        address staker
    ) external view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory stakedTokens = stakedTokenIds[staker].values();
        uint256[] memory unlockTimes = new uint256[](stakedTokens.length);

        for (uint256 i; i < stakedTokens.length; ) {
            unlockTimes[i] = lockInfos[stakedTokens[i]].unlockAt;

            unchecked {
                ++i;
            }
        }

        return (stakedTokens, unlockTimes);
    }

    // ----- Events -----

    event Stake(
        address indexed staker,
        uint256 indexed tokenId,
        uint256 indexed unlockAt
    );

    event Unstake(address indexed staker, uint256 indexed tokenId);

    event UpdateLockTime(
        address indexed owner,
        uint256 indexed lockTime,
        bool indexed isAdd
    );

    // ----- Errors -----

    /// @notice Emitted when user tries to stake a tokenId where they aren't the owner
    error TTOOStaking__NotNFTOwner();

    /// @notice Emitted when user tries to stake for a lock time that wasn't specified by the owner
    error TTOOStaking__NonexistentLockTime();

    /// @notice Emitted when user tries to unstake and either: tokenId not staked or they aren't the staker
    error TTOOStaking__NotStakedOrOwner();

    /// @notice Emitted when user tries to unstake before lock period is over.
    error TTOOStaking__LockPeriodNotOver();

    /// @notice Emitted when there would be zero lockTimes in the set
    error TTOOStaking__RequireAtLeastOneLockTime();
}