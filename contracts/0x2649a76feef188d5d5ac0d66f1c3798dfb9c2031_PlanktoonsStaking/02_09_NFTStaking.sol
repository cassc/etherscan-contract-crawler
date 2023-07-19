//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

struct AccountStake {
    // buffered rewards... tokens earned by an account but not yet distributed.
    // 96 bit int -> 79 billion max earned token accumulator
    uint96 earned;
    // the last time a claim occured
    uint96 lastClaimTime;
    // the total count of NFTs staked
    uint32 stakedCount;
    // token ID -> isStaked flag
    mapping(uint256 => bool) stakedTokens;
}

/// @notice A simple NFT staking contract to emit deposited reserves to stakers
/// as claimable tokens.
contract NFTStaking is Ownable {
    /// @notice The amount of tokens that are emitted per day per NFT.
    uint256 public constant DAILY_RATE = 1 * 10**18;

    // ---
    // Storage
    // ---

    /// @notice The NFT that can be staked in this contract.
    IERC721 public nft;

    /// @notice The token that is rewarded for staking.
    IERC20 public token;

    //// @notice Generate rewards up until this timestamp
    uint256 public rewardUntilTimestamp = block.timestamp + 365 days;

    // all staking data by owner address
    mapping(address => AccountStake) private _stakes;

    // ---
    // Events
    // ---

    /// @notice An NFT was staked into the contract.
    event NFTStaked(address owner, uint256 tokenId);

    /// @notice An NFT was unstaked from the contract.
    event NFTUnstaked(address owner, uint256 tokenId);

    /// @notice Tokens were claimed.
    event TokensClaimed(address owner, uint256 amount);

    // ---
    // Errors
    // ---

    /// @notice Setup was attempted more than once.
    error AlreadySetup();

    /// @notice A token was attempted to be staked that wasn't owned by the staker.
    error NotTokenOwner();

    /// @notice An invalid NFT was attempted to be unstaked (eg, not owned or staked)
    error InvalidUnstake();

    /// @notice Reward end timestamp was set to an earlier date
    error InvalidRewardUntilTimestamp();

    // ---
    // Admin functionality
    // ---

    /// @notice Set the NFT and token contracts.
    function setup(
        IERC721 nft_,
        IERC20 token_,
        uint256 deposit_
    ) external onlyOwner {
        if (nft != IERC721(address(0))) revert AlreadySetup();

        nft = nft_;
        token = token_;

        // reverts if contract not approved to spend msg.sender tokens
        // reverts if insufficient balance in msg.sender
        // reverts if invalid token reference
        // reverts if deposit = 0
        token_.transferFrom(msg.sender, address(this), deposit_);
    }

    /// @notice Deposit more reward tokens (if amount > 0) and update the
    /// rewards cutoff date (if cutoff > 0))
    function depositRewards(uint256 amount, uint256 cutoff) external onlyOwner {
        if (amount > 0) {
            // reverts if contract not approved to spend msg.sender tokens
            // reverts if insufficient balance in msg.sender
            // reverts if staking not set up
            token.transferFrom(msg.sender, address(this), amount);
        }

        if (cutoff > 0) {
            if (cutoff < rewardUntilTimestamp)
                revert InvalidRewardUntilTimestamp();
            rewardUntilTimestamp = cutoff;
        }
    }

    // ---
    // Holder functionality
    // ---

    /// @notice Stake multiple NFTs
    function stakeNFTs(uint256[] memory tokenIds) external {
        // flush rewards to accumulator, basically buffers the current claim
        // since we are about the change the "rate" of rewards when we stake
        // more NFTs
        _stakes[msg.sender].earned = uint96(getClaimable(msg.sender));
        _stakes[msg.sender].lastClaimTime = uint96(block.timestamp);
        _stakes[msg.sender].stakedCount += uint32(tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            // reverts if nft isnt owned by caller
            // reverts if already staked (eg, a duplicate token ID)
            if (nft.ownerOf(tokenId) != msg.sender) revert NotTokenOwner();

            _stakes[msg.sender].stakedTokens[tokenId] = true;
            emit NFTStaked(msg.sender, tokenId);

            // reverts if contract not approved to move nft tokens
            // reverts if contract is not set up
            nft.transferFrom(msg.sender, address(this), tokenId);
        }
    }

    /// @notice Claim all earned tokens for msg.sender
    function claim() external {
        _claimFor(msg.sender);
    }

    /// @notice Permissionlessly claim tokens on behalf of another account.
    function claimFor(address account) external {
        _claimFor(account);
    }

    /// @notice Claim all unearned tokens and unstake a subset of staked NFTs
    function claimAndUnstakeNFTs(uint256[] memory tokenIds) external {
        _claimFor(msg.sender);
        _stakes[msg.sender].stakedCount -= uint32(tokenIds.length); // reverts on overflow

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _unstake(msg.sender, tokenIds[i]);
        }
    }

    /// @notice Unstake without claiming -- do not call unless NFTs are stuck
    /// due to insufficient rewards reserve balance.
    function emergencyUnstake(uint256[] memory tokenIds) external {
        // flush rewards to accumulator
        _stakes[msg.sender].earned = uint96(getClaimable(msg.sender));
        _stakes[msg.sender].lastClaimTime = uint96(block.timestamp);
        _stakes[msg.sender].stakedCount -= uint32(tokenIds.length); // reverts on overflow

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _unstake(msg.sender, tokenIds[i]);
        }
    }

    function _unstake(address account, uint256 tokenId) internal {
        if (!_stakes[account].stakedTokens[tokenId]) revert InvalidUnstake();
        delete _stakes[account].stakedTokens[tokenId];
        emit NFTUnstaked(account, tokenId);

        nft.transferFrom(address(this), account, tokenId);
    }

    function _claimFor(address account) internal {
        uint256 claimable = getClaimable(account);
        if (claimable == 0) return; // allow silent nop
        _stakes[account].earned = 0;
        _stakes[account].lastClaimTime = uint96(block.timestamp);
        emit TokensClaimed(account, claimable);

        // reverts if insufficient rewards reserves
        token.transfer(account, claimable);
    }

    // ---
    // Views
    // ---

    /// @notice Returns the total claimable tokens for a given account.
    function getClaimable(address account) public view returns (uint256) {
        // either claim up until now, or the rewards cutoff time if we've
        // already passed that date
        uint256 claimUntil = block.timestamp < rewardUntilTimestamp
            ? block.timestamp
            : rewardUntilTimestamp;

        uint256 delta = claimUntil - _stakes[account].lastClaimTime;
        uint256 emitted = (_stakes[account].stakedCount * DAILY_RATE * delta) /
            1 days;

        return emitted + _stakes[account].earned;
    }

    /// @notice Returns the total NFTs that have been staked by an account
    function getStakedBalance(address account) public view returns (uint256) {
        return _stakes[account].stakedCount;
    }

    /// @notice Returns true of a specific token ID has been staked by a specific address
    function isStakedForAccount(address account, uint256 tokenId)
        public
        view
        returns (bool)
    {
        return _stakes[account].stakedTokens[tokenId];
    }
}