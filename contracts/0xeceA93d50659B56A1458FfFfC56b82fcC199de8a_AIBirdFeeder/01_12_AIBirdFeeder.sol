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

abstract contract DROOL {
    function balanceOf(address account) public view virtual returns (uint256);
    function burnFrom(address _from, uint256 _amount) external virtual;
}

contract AIBirdFeeder is Ownable, ReentrancyGuard {

    mapping(uint256 => int) public birdFeedTracker;
    event UsedBirdFeed(uint256 tokenId, uint256 action);

    constructor(address aiBirds_, address aiBirdFeed_, address drool_) {
        aiBirds = AIBirdsInterface(aiBirds_);
        aiBirdFeed = AIBirdFeedInterface(aiBirdFeed_);
        drool = DROOL(drool_);
    }

    uint256 public totalBigFeed = 0;
    uint256 public totalSmallFeed = 0;
    uint256 public totalEthFeed = 0;

    uint256 public ethFeedPrice = 0.005 ether;
    function setEthFeedPrice(uint256 ethFeedPrice_) external onlyOwner {
        ethFeedPrice = ethFeedPrice_;
    }

    uint256 public droolFeedPrice = 300 ether;
    function setDroolFeedPrice(uint256 droolFeedPrice_) external onlyOwner {
        droolFeedPrice = droolFeedPrice_;
    }

    uint256 public maxEthFeed = 100;
    function setMaxEthFeed(uint256 maxEthFeed_) external onlyOwner {
        maxEthFeed = maxEthFeed_;
    }

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

    DROOL private drool;
    function setDrool(address addr) external onlyOwner {
        drool = DROOL(addr);
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
        require(birdFeedTracker[tokenId] == 0, "Bird can't eat anymore");
        require(aiBirds.ownerOf(tokenId) == msg.sender, "You don't own this bird");
        require(msg.sender == tx.origin, "No smart contracts");
        require(totalSmallFeed + 1 <= maxSmallFeed, "Small feed limit reached");
        totalSmallFeed++;
        aiBirdFeed.burn(msg.sender, 0, 1);
        birdFeedTracker[tokenId] = 1;
    }

    function bigFeed(uint256 tokenId) external nonReentrant {
        require(feedEnabled, "Your bird doesn't want to eat");
        require(birdFeedTracker[tokenId] == 0, "Bird can't eat anymore");
        require(aiBirds.ownerOf(tokenId) == msg.sender, "You don't own this bird");
        require(msg.sender == tx.origin, "No smart contracts");
        require(totalBigFeed + 1 <= maxBigFeed, "Big feed limit reached");
        totalBigFeed++;
        aiBirdFeed.burn(msg.sender, 0, 3);
        birdFeedTracker[tokenId] = 2;
    }

    function ethFeed(uint256 tokenId) external payable nonReentrant {
        require(feedEnabled, "Your bird doesn't want to eat");
        require(birdFeedTracker[tokenId] == 0, "Bird can't eat anymore");
        require(aiBirds.ownerOf(tokenId) == msg.sender, "You don't own this bird");
        require(msg.sender == tx.origin, "No smart contracts");
        require(totalEthFeed + 1 <= maxEthFeed, "Eth feed limit reached");
        require(msg.value == ethFeedPrice, "Invalid ETH amount");
        totalEthFeed++;
        birdFeedTracker[tokenId] = 3;
    }

    function droolFeed(uint256 tokenId) external payable nonReentrant {
        require(feedEnabled, "Your bird doesn't want to eat");
        require(birdFeedTracker[tokenId] == 0, "Bird can't eat anymore");
        require(aiBirds.ownerOf(tokenId) == msg.sender, "You don't own this bird");
        require(msg.sender == tx.origin, "No smart contracts");
        require(totalEthFeed + 1 <= maxEthFeed, "Feed limit reached");
        drool.burnFrom(msg.sender, droolFeedPrice);
        totalEthFeed++;
        birdFeedTracker[tokenId] = 3;
    }
}