// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//  ==========  EXTERNAL IMPORTS    ==========

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";

//  ==========  INTERNAL IMPORTS    ==========

import "../interfaces/IOasisToken.sol";

/*///////////////////////////////////////
/////////╭━━━━┳╮╱╱╱╱╱╭━━━╮///////////////
/////////┃╭╮╭╮┃┃╱╱╱╱╱┃╭━╮┃///////////////
/////////╰╯┃┃╰┫╰━┳━━╮┃┃╱┃┣━━┳━━┳┳━━╮/////
/////////╱╱┃┃╱┃╭╮┃┃━┫┃┃╱┃┃╭╮┃━━╋┫━━┫/////
/////////╱╱┃┃╱┃┃┃┃┃━┫┃╰━╯┃╭╮┣━━┃┣━━┃/////
/////////╱╱╰╯╱╰╯╰┻━━╯╰━━━┻╯╰┻━━┻┻━━╯/////
///////////////////////////////////////*/

/**
 * @author  0xFirekeeper
 * @title   OasisStaking - Stake Evolved Camels for Oasis Tokens.
 * @notice  Stake your Evolved Camels, get a holder ERC20 token (Oasis Staking Token) to preserve Discord roles, earn $OST!
 */

contract OasisStake is ReentrancyGuard {
    /*///////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice  Staker data struct.
     * @param   amountStaked  Amount of tokens staked.
     * @param   timeOfLastUpdate Time since the last user contract interaction.
     * @param   unclaimedRewards Rewards since the last user contract interaction.
     */
    struct Staker {
        uint256 amountStaked;
        uint256 timeOfLastUpdate;
        uint256 unclaimedRewards;
    }

    /*///////////////////////////////////////////////////////////////
                                STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice OasisToken contract address.
    address public immutable oasisToken;
    /// @notice EvolvedCamels contract address.
    address public immutable evolvedCamels;
    /// @notice OasisStakingToken contract address.
    address public immutable oasisStakingToken;
    /// @notice Rewards per hour per token deposited in wei.
    uint256 public constant rewardsPerHour = 10 * 1e18;
    /// @notice User Address to Staker info.
    mapping(address => Staker) public stakers;
    /// @notice Token IDs to their staker address.
    mapping(uint256 => address) public idToStaker;

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice  OasisStake constructor.
     * @param   _evolvedCamels  EvolvedCamels contract address.
     * @param   _oasisToken OasisToken contract address.
     * @param   _oasisStakingToken OasisStakingToken contract address.
     */
    constructor(address _evolvedCamels, address _oasisToken, address _oasisStakingToken) {
        evolvedCamels = _evolvedCamels;
        oasisToken = _oasisToken;
        oasisStakingToken = _oasisStakingToken;
    }

    /*///////////////////////////////////////////////////////////////
                                USER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice  Stakes specific token IDs and initializes mappings, also sends an ERC20 representing the stake.
     * @param   _tokenIds  Token IDs to stake.
     */
    function stake(uint256[] calldata _tokenIds) external nonReentrant {
        Staker storage currentStaker = stakers[msg.sender];
        uint256 tokenAmount = _tokenIds.length;

        if (0 == tokenAmount) revert("Invalid Arguments");

        if (currentStaker.amountStaked > 0) currentStaker.unclaimedRewards += _calculateRewards(msg.sender);
        currentStaker.timeOfLastUpdate = block.timestamp;

        currentStaker.amountStaked += tokenAmount;

        for (uint256 i = 0; i < tokenAmount; i++) {
            idToStaker[_tokenIds[i]] = msg.sender;
            IERC721(evolvedCamels).transferFrom(msg.sender, address(this), _tokenIds[i]);
        }

        IERC20(oasisStakingToken).transfer(msg.sender, tokenAmount * 1e18);
    }

    /**
     * @notice  Unstakes specific token IDs and updates mappings,
     * @param   _tokenIds  Token IDs to stake.
     */
    function unstake(uint256[] calldata _tokenIds) external nonReentrant {
        Staker storage currentStaker = stakers[msg.sender];
        uint256 tokenAmount = _tokenIds.length;

        if (currentStaker.amountStaked == 0) revert("No Tokens Staked");

        currentStaker.unclaimedRewards += _calculateRewards(msg.sender);
        currentStaker.timeOfLastUpdate = block.timestamp;

        currentStaker.amountStaked -= tokenAmount;

        for (uint256 i = 0; i < tokenAmount; i++) {
            if (idToStaker[_tokenIds[i]] == msg.sender) {
                IERC721(evolvedCamels).transferFrom(address(this), msg.sender, _tokenIds[i]);
                delete idToStaker[_tokenIds[i]];
            } else revert("Not Owner");
        }

        IERC20(oasisStakingToken).transferFrom(msg.sender, address(this), tokenAmount * 1e18);
    }

    /**
     * @notice  Claims unclaimed and new rewards as OST new mints.
     */
    function claimRewards() external nonReentrant {
        Staker storage currentStaker = stakers[msg.sender];
        uint256 rewards = availableRewards(msg.sender);

        if (rewards == 0) revert("No Rewards To Claim");

        currentStaker.timeOfLastUpdate = block.timestamp;
        currentStaker.unclaimedRewards = 0;

        IOasisToken(oasisToken).mint(msg.sender, rewards);
    }

    /*///////////////////////////////////////////////////////////////
                                VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice  Returns the sum of unclaimed and new rewards.
     * @param   _staker  Address of staker.
     * @return  availableRewards_  Available OST rewards for '_staker'.
     */
    function availableRewards(address _staker) public view returns (uint256 availableRewards_) {
        return _calculateRewards(_staker) + stakers[_staker].unclaimedRewards;
    }

    /**
     * @notice  Returns the currently staked token IDs of a staker.
     * @dev     This can get very expensive. I did not include token tracking in the struct to have less user gas costs, this is the tradeoff.
     * @param   _staker  Address of staker.
     * @return  stakedTokens_  Array of staked token ID of '_staker'.
     */
    function getStakedTokens(address _staker) public view returns (uint256[] memory stakedTokens_) {
        uint256 contractStaked = IERC721(evolvedCamels).balanceOf(address(this));
        uint256 userStaked = stakers[_staker].amountStaked;
        uint256[] memory userTokenIds = new uint256[](userStaked);

        uint256 currentTokenId;
        uint256 currentIndex;
        for (uint256 i = 0; i < contractStaked; i++) {
            currentTokenId = IERC721Enumerable(evolvedCamels).tokenOfOwnerByIndex(address(this), i);
            if (_staker == idToStaker[currentTokenId]) {
                userTokenIds[currentIndex] = currentTokenId;
                currentIndex = currentIndex + 1;
                if (currentIndex == userStaked) break;
            }
        }

        return userTokenIds;
    }

    /*///////////////////////////////////////////////////////////////
                                PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice  Calculates and returns the total rewards since the last update.
     * @param   _staker  Address of staker.
     * @return  _rewards  Total OST rewards accumulated since last update.
     */
    function _calculateRewards(address _staker) private view returns (uint256 _rewards) {
        uint256 secondsSinceLastUpdate = (block.timestamp - stakers[_staker].timeOfLastUpdate);
        return (secondsSinceLastUpdate * stakers[_staker].amountStaked * rewardsPerHour) / 3600;
    }
}