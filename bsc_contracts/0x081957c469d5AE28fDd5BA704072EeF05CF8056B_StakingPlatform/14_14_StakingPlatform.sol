// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IStakingPlatform.sol";

contract StakingPlatform is Ownable, Pausable, ERC721Holder, IStakingPlatform {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    IERC20 public stkERC20Token;
    IERC721 public stkFirstERC721Token;
    IERC721 public stkSecondERC721Token;
    uint256 public thresholdSTKAmount;
    uint256 public stakerCnt;
    uint256 public stakedAmount;
    mapping(address => Stake) private stakeholderToStake;
    mapping(address => bool) private blacklistedUsers;
    uint16 public originAPY;    // 500 means 5%
    uint16 public boostAPY;     // 225 means 2.25%
    uint16 public platformFee;  // 315 means 3.15%

    modifier notBlacklisted() {
        require (blacklistedUsers[msg.sender] == false, "blacklisted user");
        _;
    }

    constructor (
        uint256 thresholdSTKAmount_,
        address stkToken_,
        address stkFirstERC721Token_,
        address stkSecondERC721Token_,
        uint16 originAPY_,
        uint16 boostAPY_,
        uint16 platformFee_
    ) {
        stkERC20Token = IERC20(stkToken_);
        stkFirstERC721Token = IERC721(stkFirstERC721Token_);
        stkSecondERC721Token = IERC721(stkSecondERC721Token_);
        thresholdSTKAmount = thresholdSTKAmount_;
        originAPY = originAPY_;
        boostAPY = boostAPY_;
        platformFee = platformFee_;
    }

    /// @notice Set platform fee with new fee.
    /// @dev Only owner can call this function and also contract should be paused.
    /// @param newFee_ New platform fee.
    function updatePlatformFee(
        uint16 newFee_
    ) external onlyOwner whenPaused {
        platformFee = newFee_;
    }

    /// @notice Set new ERC20 staking token address.
    /// @dev Only owner can call this function and also contract should be paused.
    /// @param newStkERC20_ The address of new StakingERC20.
    function updateStakingERC20Token(
        address newStkERC20_
    ) external onlyOwner whenPaused {
        require (newStkERC20_ != address(0), "invalid token address");
        stkERC20Token = IERC20(newStkERC20_);
    }

    /// @notice Set new ERC721 staking token address.
    /// @dev Only owner can call this function and also contract should be paused.
    /// @param newStkERC721_ The address of new first StakingERC721.
    function updateFirstStakingERC721Token(
        address newStkERC721_
    ) external onlyOwner whenPaused {
        require (newStkERC721_ != address(0), "invalid token address");
        stkFirstERC721Token = IERC721(newStkERC721_);
    }

    /// @notice Set new ERC721 staking token address.
    /// @dev Only owner can call this function and also contract should be paused.
    /// @param newStkERC721_ The address of new second StakingERC721.
    function updateSecondStakingERC721Token(
        address newStkERC721_
    ) external onlyOwner whenPaused {
        require (newStkERC721_ != address(0), "invalid token address");
        stkSecondERC721Token = IERC721(newStkERC721_);
    }

    /// @notice Set origin apy with new apy.
    /// @dev Only owner can call this function and also contract should be paused.
    /// @param newAPY_ New apy.
    function updateOriginAPY(
        uint16 newAPY_
    ) external onlyOwner whenPaused {
        require (newAPY_ > 0, "invalid apy");
        originAPY = newAPY_;
    }

    /// @notice Set plus apy with new apy.
    /// @dev Only owner can call this function and also contract should be paused.
    /// @param newAPY_ New apy.
    function updateboostAPY(
        uint16 newAPY_
    ) external onlyOwner whenPaused {
        require (newAPY_ > 0, "invalid apy");
        boostAPY = newAPY_;
    }

    /// @notice Set staking threshold amount with new amount.
    /// @dev Only owner can call this function.
    /// @param newAmount_ New threshold amount.
    function updateThresholdSTKAmount(
        uint256 newAmount_
    ) external onlyOwner {
        require (newAmount_ > 0, "invalid threshold amount");
        thresholdSTKAmount = newAmount_;
    }

    function pausePlatform() external onlyOwner {
        _pause();
    }

    function unpausePlatform() external onlyOwner {
        _unpause();
    }

    function setBlacklist(address user_) external onlyOwner {
        blacklistedUsers[user_] = true;
    }

    function removeBlacklist(address user_) external onlyOwner {
        blacklistedUsers[user_] = false;
    }

    /// @notice Get staker's staking pool.
    /// @param staker_ The address of a staker.
    /// @return Staking pools that staker staked.
    function getUserStakingPool(
        address staker_
    ) external view returns (Stake memory) {
        require(staker_ != address(0), "zero staker address");
        
        return stakeholderToStake[staker_];
    }

    /// @notice Stake ERC20.
    /// @param amount_ Token amount to stake.
    function stakeToken(
        uint256 amount_
    ) external whenNotPaused notBlacklisted {
        address sender = msg.sender;
        require (amount_ > 0 && amount_ <= thresholdSTKAmount, "invalid amount");
        require (stkERC20Token.balanceOf(sender) >= amount_, "not enough balance");
        require (stakeholderToStake[sender].staked == false, "you already staked");

        uint256 fee = amount_ * platformFee / 10000;
        uint256 stakeAmount = amount_ - fee;

        stakeholderToStake[sender] = Stake({
            staker: sender,
            stakedSTK: stakeAmount,
            stakeTime: block.timestamp,
            pendingRewards: 0,
            firstTokenId: -1,
            secondTokenId: -1,
            apy: originAPY,
            staked: true
        });

        ++ stakerCnt;
        stakedAmount += stakeAmount;

        stkERC20Token.safeTransferFrom(sender, address(this), amount_);
        if (fee > 0) {
            stkERC20Token.safeTransfer(owner(), fee);
        }

        emit StakeToken(sender, stakeAmount);
    }

    /// @notice Stake NFT to boost apy.
    /// @notice If you boosted apy to max, it reverts.
    /// @param nftToken_ The NFT token address.
    /// @param tokenId_ The NFT token ID.
    function stakeNFT(
        address nftToken_,
        uint256 tokenId_
    ) external whenNotPaused notBlacklisted {
        address sender = msg.sender;
        Stake storage pool = stakeholderToStake[sender];
        require (stakeholderToStake[sender].staked == true, "no staking pool");
        require (
            nftToken_ == address(stkFirstERC721Token) ||
            nftToken_ == address(stkSecondERC721Token),
            "not supported NFT"
        );
        require (pool.apy < originAPY + boostAPY * 2, "you already boosted all");

        // update pending rewards before boost apy.
        uint256 pendings = pendingRewards(sender);
        
        pool.pendingRewards = pendings;
        
        // boost apy
        pool.apy += boostAPY;

        if (nftToken_ == address(stkFirstERC721Token)) {
            pool.firstTokenId = int256(tokenId_);
            stkFirstERC721Token.safeTransferFrom(sender, address(this), uint256(pool.firstTokenId));
        } else {
            pool.secondTokenId = int256(tokenId_);
            stkSecondERC721Token.safeTransferFrom(sender, address(this), uint256(pool.secondTokenId));
        }

        emit StakeNFT(sender, pool.apy);
    }

    /// @notice Unstake and get rewards and staked token and NFTs.
    function unstake() external notBlacklisted {
        address sender = msg.sender;
        Stake storage pool = stakeholderToStake[sender];
        require (pool.staker == sender, "not staker");
        require (pool.staked == true, "no staking pool");

        uint256 rewards = pendingRewards(sender);
        uint256 totalAmount = pool.stakedSTK + rewards;
        require (stkERC20Token.balanceOf(address(this)) >= totalAmount, "not enough rewards pool");

        pool.staked = false;

        stkERC20Token.safeTransfer(sender, totalAmount);
        if (pool.firstTokenId >= 0) {
            stkFirstERC721Token.safeTransferFrom(address(this), sender, uint256(pool.firstTokenId));
        }
        if (pool.secondTokenId >= 0) {
            stkSecondERC721Token.safeTransferFrom(address(this), sender, uint256(pool.secondTokenId));
        }

        -- stakerCnt;
        stakedAmount -= pool.stakedSTK;

        emit UnStaked(sender, pool.stakedSTK, rewards);
    }

    function pendingRewards(address user_) public view returns (uint256) {
        if (stakeholderToStake[user_].staked == false) {
            return 0;
        }

        Stake memory pool = stakeholderToStake[user_];
        uint256 stakedDuration = block.timestamp - pool.stakeTime;
        uint16 apy = pool.apy;
        uint256 rewards = pool.stakedSTK * apy * stakedDuration / 360 days / 10000;
        return rewards + pool.pendingRewards;
    }

    function withdraw() external onlyOwner {
        uint256 balance = stkERC20Token.balanceOf(address(this));
        require (balance > 0, "no balance");
        if (balance > 0) {
            stkERC20Token.safeTransfer(owner(), balance);
        }
    }
}