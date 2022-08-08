// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface MFNFT {
    function ownerOf(uint256 tokenId) external view returns (address);

    function ownedTokenIds(address user)
        external
        view
        returns (uint256[] memory tokenIds);
}

interface MFToken {
    function mint(address account, uint256 amount) external;
}

contract MFReward is ReentrancyGuard, Pausable, Ownable {
    address public rewardToken;
    address public nft;
    uint256 public rewardPeriod = 6 hours;
    uint256 public rewardPerPeriod = 0.25 ether;
    uint256 public firstRewardStartTime; // rewards start accumulating at this ts;
    uint256 public secondRewardStartTime; // rewards start accumulating at this ts;
    mapping(uint256 => uint256) public tokenIdToLastClaimedTime; // tokenId to timestamp;

    constructor(
        address _owner,
        address _nft,
        address _rewardToken
    ) {
        transferOwnership(_owner);
        nft = _nft;
        rewardToken = _rewardToken;
    }

    function claimableForUser(address user) public view returns (uint256) {
        uint256[] memory tokenIds = MFNFT(nft).ownedTokenIds(user);
        return claimableForTokens(tokenIds);
    }

    function claimableForTokens(uint256[] memory tokenIds)
        public
        view
        returns (uint256)
    {
        uint256 claimable = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            claimable += getClaimableForTokenId(tokenIds[i]);
        }
        return claimable;
    }

    function claim(uint256[] calldata tokenIds) external whenNotPaused {
        claimFor(tokenIds, msg.sender);
    }

    function claimFor(uint256[] calldata tokenIds, address user)
        public
        nonReentrant
        whenNotPaused
    {
        uint256 claimable = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(
                MFNFT(nft).ownerOf(tokenId) == user,
                "not owner of this tokenId"
            );
            claimable += getClaimableForTokenId(tokenId);
            tokenIdToLastClaimedTime[tokenId] = block.timestamp;
        }
        MFToken(rewardToken).mint(user, claimable);
    }

    // INTERNAL FUNCTIONS
    function getClaimableForTokenId(uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        uint256 lastClaimedTime = tokenIdToLastClaimedTime[tokenId];
        uint256 actualLastClaimedTime = getActualLastClaimedTime(
            lastClaimedTime,
            tokenId
        );
        uint256 rewardCycles = (block.timestamp - actualLastClaimedTime) /
            rewardPeriod;
        return rewardCycles * rewardPerPeriod;
    }

    function getActualLastClaimedTime(uint256 lastClaimedTime, uint256 tokenId)
        internal
        view
        returns (uint256 actualLastClaimedTime)
    {
        if (lastClaimedTime == 0 && tokenId < 1800) {
            actualLastClaimedTime = firstRewardStartTime;
        } else if (lastClaimedTime == 0 && tokenId >= 1800) {
            require(
                secondRewardStartTime != 0,
                "secondRewardStartTime not set"
            );
            require(
                block.timestamp >= secondRewardStartTime,
                "not yet second reward start time"
            );
            actualLastClaimedTime = secondRewardStartTime;
        } else {
            actualLastClaimedTime = lastClaimedTime;
        }
    }

    // ADMIN FUNCTIONS
    function setup(
        uint256 _rewardPeriod,
        uint256 _rewardPerPeriod,
        uint256 _firstRewardStartTime,
        uint256 _secondRewardStartTime
    ) external onlyOwner {
        rewardPeriod = _rewardPeriod;
        rewardPerPeriod = _rewardPerPeriod;
        firstRewardStartTime = _firstRewardStartTime;
        secondRewardStartTime = _secondRewardStartTime;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}