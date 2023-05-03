// SPDX-License-Identifier: MIT
// solhint-disable not-rely-on-time
pragma solidity 0.8.14;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title XFLStaker
 * @author nneverlander. Twitter @nneverlander
 * @notice This allows people to stake tokens for reward boosts
 */
contract XFLStaker is Ownable, Pausable {
    enum StakeLevel {
        NONE,
        BRONZE,
        SILVER,
        GOLD,
        PLATINUM
    }

    ///@dev Storage variable to keep track of the staker's amounts
    mapping(address => uint256) public userStakedAmounts;

    ///@dev XFL token address
    // solhint-disable var-name-mixedcase
    address public immutable XFL_TOKEN;

    uint256 public unlockBlock = 17778462;

    /**@dev Stake levels. Users can reach these levels by staking the specified number of tokens.
     */
    uint256 public bronzeStakeThreshold = 10_000 * 1e18;
    uint256 public silverStakeThreshold = 50_000 * 1e18;
    uint256 public goldStakeThreshold = 100_000 * 1e18;
    uint256 public platinumStakeThreshold = 200_000 * 1e18;

    event Staked(address indexed user, uint256 amount);
    event UnStaked(address indexed user, uint256 amount);
    event StakeLevelThresholdUpdated(StakeLevel stakeLevel, uint256 threshold);
    event UnlockBlockUpdated(uint256 oldValue, uint256 newValue);

    /**
    @param _tokenAddress The address of the XFL token
    @param _unlockBlock The block number after which users can unstake
   */
    constructor(address _tokenAddress, uint256 _unlockBlock) {
        XFL_TOKEN = _tokenAddress;
        unlockBlock = _unlockBlock;
    }

    // =================================================== USER FUNCTIONS =======================================================

    /**
     * @notice Stake tokens for a specified duration
     * @dev Tokens are transferred from the user to this contract
     * @param amount Amount of tokens to stake
     */
    function stake(uint256 amount) external whenNotPaused {
        require(amount != 0, "stake amount cant be 0");
        // update storage
        userStakedAmounts[msg.sender] += amount;
        // perform transfer; no need for safeTransferFrom since we know the implementation of the token contract
        IERC20(XFL_TOKEN).transferFrom(msg.sender, address(this), amount);
        // emit event
        emit Staked(msg.sender, amount);
    }

    /**
     * @notice Unstake tokens
     * @param amount Amount of tokens to unstake
     */
    function unstake(uint256 amount) external whenNotPaused {
        require(amount != 0, "unstake amount cant be 0");
        require(
            userStakedAmounts[msg.sender] >= amount,
            "insufficient balance to unstake"
        );
        require(block.number >= unlockBlock, "too early");

        // update storage
        userStakedAmounts[msg.sender] -= amount;
        // perform transfer
        IERC20(XFL_TOKEN).transfer(msg.sender, amount);
        // emit event
        emit UnStaked(msg.sender, amount);
    }

    // ====================================================== VIEW FUNCTIONS ======================================================

    /**
     * @notice Gets a user's stake level
     * @param user address of the user
     * @return StakeLevel
     */
    function getUserStakeLevel(
        address user
    ) external view returns (StakeLevel) {
        uint256 totalStaked = userStakedAmounts[user];

        if (totalStaked < bronzeStakeThreshold) {
            return StakeLevel.NONE;
        } else if (totalStaked < silverStakeThreshold) {
            return StakeLevel.BRONZE;
        } else if (totalStaked < goldStakeThreshold) {
            return StakeLevel.SILVER;
        } else if (totalStaked < platinumStakeThreshold) {
            return StakeLevel.GOLD;
        } else {
            return StakeLevel.PLATINUM;
        }
    }

    // ====================================================== ADMIN FUNCTIONS ================================================

    /// @dev Admin function to update unlock block
    function updateUnlockBlock(uint256 _unlockBlock) external onlyOwner {
        uint256 oldVal = unlockBlock;
        unlockBlock = _unlockBlock;
        emit UnlockBlockUpdated(oldVal, unlockBlock);
    }

    /// @dev Admin function to update stake level thresholds
    function updateStakeLevelThreshold(
        StakeLevel stakeLevel,
        uint256 threshold
    ) external onlyOwner {
        if (stakeLevel == StakeLevel.BRONZE) {
            bronzeStakeThreshold = threshold;
        } else if (stakeLevel == StakeLevel.SILVER) {
            silverStakeThreshold = threshold;
        } else if (stakeLevel == StakeLevel.GOLD) {
            goldStakeThreshold = threshold;
        } else if (stakeLevel == StakeLevel.PLATINUM) {
            platinumStakeThreshold = threshold;
        }
        emit StakeLevelThresholdUpdated(stakeLevel, threshold);
    }

    /// @dev Admin function to pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev Admin function to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }
}