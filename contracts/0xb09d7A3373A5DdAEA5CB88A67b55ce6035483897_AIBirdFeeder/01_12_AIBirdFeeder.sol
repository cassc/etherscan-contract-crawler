// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract AIBirdsInterface {
    function ownerOf(uint256 tokenId) external virtual returns(address);
}

abstract contract AIBirdFeedInterface {
    function burn(address account, uint256 id, uint256 amount) external virtual;
}

contract AIBirdFeeder is Ownable, ReentrancyGuard {

    mapping(uint256 => bool) public birdFeedTracker;
    event UsedBirdFeed(uint256 tokenId, uint256 action);

    constructor(address aiBirds_, address aiBirdFeed_) {
        aiBirds = AIBirdsInterface(aiBirds_);
        aiBirdFeed = AIBirdFeedInterface(aiBirdFeed_);
    }

    uint256 public totalBigFeed = 0;
    uint256 public totalSmallFeed = 0;

    uint256 public maxBigFeed = 20;
    function setMaxBigFeed(uint256 maxBigFeed_) external onlyOwner {
        maxBigFeed = maxBigFeed_;
    }

    uint256 public maxSmallFeed = 100;
    function setMaxSmallFeed(uint256 maxSmallFeed_) external onlyOwner {
        maxSmallFeed = maxSmallFeed_;
    }
    
    bool public feedEnabled = false;
    function toggleFeedEnabled() external onlyOwner {
        feedEnabled = !feedEnabled;
    }

    AIBirdFeedInterface public aiBirdFeed;
    function setBirdFeed(address addr) external onlyOwner {
        aiBirdFeed = AIBirdFeedInterface(addr);
    }

    AIBirdsInterface public aiBirds;
    function setAiBirds(address addr) external onlyOwner {
        aiBirds = AIBirdsInterface(addr);
    }

    function smallFeed(uint256 tokenId) external nonReentrant {
        require(feedEnabled, "Your bird doesn't want to eat");
        require(birdFeedTracker[tokenId] == false, "Bird can't eat anymore");
        require(aiBirds.ownerOf(tokenId) == msg.sender, "You don't own this bird");
        require(msg.sender == tx.origin, "No smart contracts");
        require(totalSmallFeed + 1 <= maxSmallFeed, "Small feed limit reached");
        totalSmallFeed++;
        aiBirdFeed.burn(msg.sender, 0, 1);
        birdFeedTracker[tokenId] = true;
        emit UsedBirdFeed(tokenId, 1);
    }

    function bigFeed(uint256 tokenId) external nonReentrant {
        require(feedEnabled, "Your bird doesn't want to eat");
        require(birdFeedTracker[tokenId] == false, "Bird can't eat anymore");
        require(aiBirds.ownerOf(tokenId) == msg.sender, "You don't own this bird");
        require(msg.sender == tx.origin, "No smart contracts");
        require(totalBigFeed + 1 <= maxBigFeed, "Big feed limit reached");
        totalBigFeed++;
        aiBirdFeed.burn(msg.sender, 0, 3);
        birdFeedTracker[tokenId] = true;
        emit UsedBirdFeed(tokenId, 2);
    }
}