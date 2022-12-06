// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface ISantaClubStaking {
    function getStakerTotalStakedNFTs(address account)
        external
        view
        returns (uint256);

    function nftIDsOfOwner(address account)
        external
        view
        returns (uint256[] memory);
}

/**
 * @title Santa Club Staking Smart Contract
 * @dev Earn Santa tokens by staking your Santa Club NFT
 * @author Kris Kringle
 */

contract SantaClubStaking is Ownable, IERC721Receiver, ReentrancyGuard {
    struct NFTStake {
        address owner;
        uint256 stakedAt;
    }

    struct Staker {
        uint256 totalStakedNFTs;
        uint256 totalClaimedRewards;
    }

    string public name = "Santa Club Staking";

    uint256 private constant WEEK = 7 days;
    uint256 private constant MONTH = 30 days;

    uint256 private constant DEFAULT_DAILY_REWARD = 2;
    uint256 public dailyReward;

    IERC20 public immutable rewardToken;
    IERC721Enumerable public immutable nftCollection;

    uint256 public totalDistributedRewards;
    uint256 public totalStakedNFTs;

    // Mapping from NFT ids to an NFT stake struct
    mapping(uint256 => NFTStake) public nftStake;

    // Mapping from address to staker struct
    mapping(address => Staker) public staker;

    event NFTStaked(address owner, uint256 tokenID, uint256 time);
    event NFTUnstaked(address owner, uint256 tokenID, uint256 time);
    event Claimed(address owner, uint256 amount);
    event UpdateDailyReward(uint256 amount);

    receive() external payable {}

    constructor() {
        rewardToken = IERC20(0x50C5C8e6b2B2e86135A1B909176436723866356D);
        nftCollection = IERC721Enumerable(
            0x27C6B5Bae206252DDc1E20d9b1931bC70f0EfD6a
        );
        dailyReward = 20;
    }

    function getClaimableRewards(uint256 _tokenID)
        public
        view
        returns (uint256)
    {
        if (rewardToken.balanceOf(address(this)) == 0) {
            return 0;
        }
        NFTStake memory stake = nftStake[_tokenID];
        uint256 stakedAt = stake.stakedAt;
        uint256 calculatedReward;
        if (stakedAt != 0) {
            uint256 stakingPeriod = block.timestamp - stakedAt;
            uint256 dailyRewardRate = calculateDailyRewardRate(stakingPeriod);
            calculatedReward =
                (100 ether * dailyRewardRate * stakingPeriod) /
                1 days;
        }
        return calculatedReward / 100;
    }

    function nftIDsOfOwner(address account)
        external
        view
        returns (uint256[] memory)
    {
        return _nftIDsOfOwner(account);
    }

    function getStakerTotalStakedNFTs(address account)
        external
        view
        returns (uint256)
    {
        return staker[account].totalStakedNFTs;
    }

    function getStakedAt(uint256 tokenID) external view returns (uint256) {
        return nftStake[tokenID].stakedAt;
    }

    function getStakerTotalClaimedRewards(address account)
        external
        view
        returns (uint256)
    {
        return staker[account].totalClaimedRewards;
    }

    function getTotalUnclaimedRewards() external view returns (uint256) {
        uint256 unclaimedRewards;
        uint256 mintedSupply = nftCollection.totalSupply();
        uint256[] memory mintedNFTs = new uint256[](mintedSupply);

        for (uint256 tokenID = 1; tokenID < mintedNFTs.length + 1; tokenID++) {
            unclaimedRewards += getClaimableRewards(tokenID);
        }
        return unclaimedRewards;
    }

    function getTotalClaimableRewards(address account)
        external
        view
        returns (uint256)
    {
        uint256 tokenID;
        uint256 claimableRewards;
        uint256[] memory tokenIDs = _nftIDsOfOwner(account);

        for (uint256 i = 0; i < tokenIDs.length; i++) {
            tokenID = tokenIDs[i];
            claimableRewards += getClaimableRewards(tokenID);
        }
        return claimableRewards;
    }

    function getClaimableRewardsByIDs(uint256[] calldata tokenIDs)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenID;
        uint256 claimableRewards;
        uint256[] memory claimableRewardsArray = new uint256[](tokenIDs.length);
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            tokenID = tokenIDs[i];
            claimableRewards = getClaimableRewards(tokenID);
            claimableRewardsArray[i] = claimableRewards;
        }
        return claimableRewardsArray;
    }

    function getStakedAtByIDs(uint256[] calldata tokenIDs)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenID;
        uint256 stakedAt;
        uint256[] memory stakedAtArray = new uint256[](tokenIDs.length);
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            tokenID = tokenIDs[i];
            stakedAt = nftStake[tokenID].stakedAt;
            stakedAtArray[i] = stakedAt;
        }
        return stakedAtArray;
    }

    function updateDailyReward(uint256 amount) external onlyOwner {
        require(
            amount > 5,
            "Update Daily Reward: reward should be greater than 5 per day"
        );
        require(
            amount <= 35,
            "Update Daily Reward: reward should not be more than 35 per day"
        );
        dailyReward = amount;
        emit UpdateDailyReward(amount);
    }

    function stakeNFTs(uint256[] calldata tokenIDs) external nonReentrant {
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 tokenID;
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            // If the amount of gas used by the previous NFT transfer is more than the remaining gas,
            // we stop staking NFTs for the remaining NFTs to avoid an out-of-gas error.
            require(
                gasUsed < gasleft(),
                "Stake NFT: Not enough gas. Try again."
            );

            tokenID = tokenIDs[i];
            require(
                nftStake[tokenID].owner == address(0),
                "Stake NFT: The NFT is already staked."
            );
            require(
                nftCollection.ownerOf(tokenID) == msg.sender,
                "Stake NFT: You do not own this NFT."
            );

            nftCollection.transferFrom(msg.sender, address(this), tokenID);

            nftStake[tokenID] = NFTStake({
                owner: msg.sender,
                stakedAt: block.timestamp
            });

            totalStakedNFTs += 1;
            staker[msg.sender].totalStakedNFTs += 1;

            emit NFTStaked(msg.sender, tokenID, block.timestamp);

            gasUsed = gasLeft - gasleft();
            gasLeft = gasleft();
        }
    }

    function claimRewards(uint256[] calldata tokenIDs) external nonReentrant {
        _claimRewards(msg.sender, tokenIDs, false);
    }

    function unstakeNFTs(uint256[] calldata tokenIDs) external nonReentrant {
        _claimRewards(msg.sender, tokenIDs, true);
    }

    function getDailyRewardRate(uint256 stakingPeriod)
        external
        view
        returns (uint256)
    {
        return calculateDailyRewardRate(stakingPeriod);
    }

    function _nftIDsOfOwner(address account)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 supply = nftCollection.totalSupply();
        uint256[] memory temp = new uint256[](supply);

        uint256 index = 0;
        for (uint256 nftID = 1; nftID <= supply; nftID++) {
            if (nftStake[nftID].owner == account) {
                temp[index] = nftID;
                index += 1;
            }
        }

        uint256[] memory nftIDs = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            nftIDs[i] = temp[i];
        }

        return nftIDs;
    }

    function _unstake(address account, uint256[] calldata tokenIDs) internal {
        uint256 tokenID;
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            tokenID = tokenIDs[i];
            require(
                nftStake[tokenID].owner == account,
                "Unstake: not an owner"
            );

            nftCollection.transferFrom(address(this), account, tokenID);

            delete nftStake[tokenID];

            staker[account].totalStakedNFTs -= 1;
            totalStakedNFTs -= 1;

            emit NFTUnstaked(account, tokenID, block.timestamp);
        }
    }

    function calculateDailyRewardRate(uint256 stakingPeriod)
        internal
        view
        returns (uint256 dailyRewardRate)
    {
        if (stakingPeriod < WEEK) {
            dailyRewardRate = DEFAULT_DAILY_REWARD;
        } else if (stakingPeriod < MONTH) {
            dailyRewardRate = dailyReward;
        } else if (stakingPeriod < 2 * MONTH) {
            dailyRewardRate = dailyReward * 2;
        } else if (stakingPeriod < 3 * MONTH) {
            dailyRewardRate = dailyReward * 3;
        } else if (stakingPeriod >= 4 * MONTH) {
            dailyRewardRate = dailyReward * 4;
        }
    }

    function _claimRewards(
        address account,
        uint256[] calldata tokenIDs,
        bool unstake
    ) internal {
        uint256 tokenID;
        uint256 rewardEarned;

        for (uint256 i = 0; i < tokenIDs.length; i++) {
            tokenID = tokenIDs[i];
            NFTStake memory stake = nftStake[tokenID];
            require(stake.owner == account, "Claim: not an NFT owner");
            rewardEarned += getClaimableRewards(tokenID);
            nftStake[tokenID].stakedAt = block.timestamp;
        }
        if (rewardEarned > 0) {
            uint256 balanceOfStakingVault = rewardToken.balanceOf(
                address(this)
            );
            if (rewardEarned > balanceOfStakingVault) {
                rewardEarned = balanceOfStakingVault;
            }
            rewardToken.transfer(msg.sender, rewardEarned);
            staker[account].totalClaimedRewards += rewardEarned;
            totalDistributedRewards += rewardEarned;
            emit Claimed(account, rewardEarned);
        }
        if (unstake) {
            _unstake(account, tokenIDs);
        }
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(
            from == address(0x0),
            "onERC721Received: Cannot transfer an NFT directly to the staking smart contract."
        );
        return IERC721Receiver.onERC721Received.selector;
    }
}