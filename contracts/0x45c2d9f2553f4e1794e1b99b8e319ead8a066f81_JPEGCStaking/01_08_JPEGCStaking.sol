// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title JPEG Cards staking contract
/// @notice Users can stake their JPEG Cards and get JPEG rewards. 
contract JPEGCStaking is Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;

    event Deposit(address indexed user, uint256 indexed nft);
    event Withdraw(address indexed user, uint256 indexed nft);
    event Claim(address indexed user, uint256 indexed nft, uint256 amount);

    struct PoolState {
        /// @dev last block where rewards were emitted
        uint256 lastRewardBlock;
        /// @dev number of JPEG distributed per block
        uint256 rewardsPerBlock;
        /// @dev number of rewards distributed per NFT
        uint256 accRewardPerNft;
        /// @dev last reward-emitting block
        uint256 endBlock;
    }

    /// @notice JPEG Cards contract address
    IERC721 public immutable jpegc;
    /// @notice JPEG contract address
    IERC20 public immutable jpeg;

    uint256 public totalNftsStaked;

    /// @dev The current reward pool's state
    PoolState internal poolState;

    /// @dev Staked NFTs per address
    mapping(address => EnumerableSet.UintSet) internal stakedNfts;
    /// @dev last `accRewardPerNft` the NFT at index claimed rewards
    mapping(uint256 => uint256) internal lastAccRewardPerNFT;

    constructor(IERC721 _jpegc, IERC20 _jpeg) {
        jpegc = _jpegc;
        jpeg = _jpeg;
    }


    /// @notice Allows the owner to allocate jpeg rewards to this contract.
    /// @param startBlock The first reward-emitting block
    /// @param rewardsPerBlock Number of JPEG emitted per block
    /// @param endBlock The last reward-emitting block
    function allocateRewards(uint256 startBlock, uint256 rewardsPerBlock, uint256 endBlock) external onlyOwner {
        require(poolState.lastRewardBlock == 0, "ALREADY_ALLOCATED");
        require(startBlock > block.number, "INVALID_START_BLOCK");
        require(rewardsPerBlock > 0, "INVALID_REWARDS_PER_BLOCK");
        require(endBlock > startBlock, "INVALID_END_BLOCK");

        poolState.lastRewardBlock = startBlock;
        poolState.rewardsPerBlock = rewardsPerBlock;
        poolState.endBlock = endBlock;

        jpeg.transferFrom(msg.sender, address(this), (endBlock - startBlock) * rewardsPerBlock);
    }

    /// @notice Allows users to stake multiple NFTs at once
    /// @param nfts The NFTs to stake
    function deposit(uint256[] memory nfts) external nonReentrant {
        require(nfts.length > 0, "INVALID_NFTS");
        require(poolState.lastRewardBlock > 0, "NOT_STARTED");
        _update();

        totalNftsStaked += nfts.length;
        uint256 accRewardPerNFT = poolState.accRewardPerNft;
        for (uint256 i = 0; i < nfts.length; i++) {
            stakedNfts[msg.sender].add(nfts[i]);
            lastAccRewardPerNFT[nfts[i]] = accRewardPerNFT;

            jpegc.transferFrom(msg.sender, address(this), nfts[i]);

            emit Deposit(msg.sender, nfts[i]);
        }
    }

    /// @notice Allows users to withdraw multiple NFTs at once. Claims rewards automatically from the withdrawn NFTs
    /// @param nfts The NFTs to withdraw
    function withdraw(uint256[] memory nfts) public nonReentrant {
        require(nfts.length > 0, "INVALID_NFTS");
        _update();

        totalNftsStaked -= nfts.length;

        uint256 accRewardPerNft = poolState.accRewardPerNft;
        uint256 toClaim;
        for (uint256 i = 0; i < nfts.length; i++) {
            require(stakedNfts[msg.sender].contains(nfts[i]), "NOT_AUTHORIZED");
            toClaim += (accRewardPerNft - lastAccRewardPerNFT[nfts[i]]) /
                1e36;
            stakedNfts[msg.sender].remove(nfts[i]);
            jpegc.safeTransferFrom(address(this), msg.sender, nfts[i]);

            emit Withdraw(msg.sender, nfts[i]);
        }

        if(toClaim > 0)
            jpeg.transfer(msg.sender, toClaim);

    }

    /// @notice Allows users to claim JPEG rewards from multiple staked NFTs
    /// @param nfts The NFTs to claim JPEG rewards from
    function claim(uint256[] memory nfts) public nonReentrant {
        require(nfts.length > 0, "INVALID_NFTS");
        _update();

        uint256 accRewardPerNft = poolState.accRewardPerNft;
        uint256 claimable;
        for (uint256 i = 0; i < nfts.length; i++) {
            require(stakedNfts[msg.sender].contains(nfts[i]), "NOT_AUTHORIZED");
            uint256 toClaim = (accRewardPerNft - lastAccRewardPerNFT[nfts[i]]) /
                1e36;
            lastAccRewardPerNFT[nfts[i]] = accRewardPerNft;

            claimable += toClaim;

            emit Claim(msg.sender, nfts[i], toClaim);
        }

        require(claimable > 0, "NO_REWARDS");

        jpeg.transfer(msg.sender, claimable);
    }


    /// @notice Allows users to claim JPEG rewards from all their staked NFTs
    function claimAll() external {
        claim(stakedNfts[msg.sender].values());
    }

    /// @notice Allows users to withdraw all their staked NFTs. Also claims rewards.
    function withdrawAll() external {
        withdraw(stakedNfts[msg.sender].values());
    }


    /// @notice Returns the indexes of all `account`'s staked NFTs
    /// @param account The user's address
    function userStakedNfts(address account)
        external
        view
        returns (uint256[] memory)
    {
        return stakedNfts[account].values();
    }
    
    /// @notice Returns the amount of JPEG claimable from an NFT
    /// @param nft The NFT to check
    function pendingReward(uint256 nft) public view returns (uint256) {
        uint256 accRewardPerNft = poolState.accRewardPerNft;
        
        uint256 blockNumber = block.number;

        if (blockNumber > poolState.endBlock)
            blockNumber = poolState.endBlock;

        if (blockNumber > poolState.lastRewardBlock && totalNftsStaked > 0) {
            uint256 reward = ((blockNumber - poolState.lastRewardBlock)) *
                poolState.rewardsPerBlock *
                1e36;
            accRewardPerNft += reward / totalNftsStaked;
        }

        return (accRewardPerNft - lastAccRewardPerNFT[nft]) / 1e36;
    }

    /// @notice Returns the amount of JPEG an user can claim from all their NFTs
    /// @param account The user's address
    function pendingUserReward(address account)
        external
        view
        returns (uint256 totalReward)
    {
        for (uint256 i = 0; i < stakedNfts[account].length(); i++) {
            totalReward += pendingReward(stakedNfts[account].at(i));
        }
    }

    /// @dev Updates the pool's state
    function _update() internal {
        PoolState memory pool = poolState;

        uint256 blockNumber = block.number;

        if (blockNumber > pool.endBlock)
            blockNumber = pool.endBlock;

        if (blockNumber <= pool.lastRewardBlock) return;

        if (totalNftsStaked == 0) {
            poolState.lastRewardBlock = blockNumber;
            return;
        }

        uint256 reward = ((blockNumber - pool.lastRewardBlock)) *
            pool.rewardsPerBlock *
            1e36;
        poolState.accRewardPerNft =
            pool.accRewardPerNft +
            reward /
            totalNftsStaked;
        poolState.lastRewardBlock = blockNumber;
    }
}