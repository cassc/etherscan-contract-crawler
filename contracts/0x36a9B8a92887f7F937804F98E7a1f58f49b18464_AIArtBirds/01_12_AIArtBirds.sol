// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract AIBirds {
    function ownerOf(uint256 tokenId) external virtual returns(address);
}

abstract contract AIBirdFeed {
    function burn(address account, uint256 id, uint256 amount) external virtual;
}

contract AIArtBirds is ERC721, Ownable, ReentrancyGuard {

    mapping(uint256 => bool) public birdFeedTracker;
    event UsedBirdFeed(uint256 tokenId, uint256 action);

    constructor(address aiBirds_, address aiBirdFeed_) ERC721("AI Art Birds", "ARTBIRDS") {
        aiBirds = AIBirds(aiBirds_);
        aiBirdFeed = AIBirdFeed(aiBirdFeed_);
    }

    uint256 public totalSupply;

    uint256 public maxSupply = 100;
    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }
    
    bool public feedEnabled = false;
    function toggleFeedEnabled() external onlyOwner {
        feedEnabled = !feedEnabled;
    }

    bool public mintEnabled = false;
    function toggleMintEnabled() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    AIBirdFeed public aiBirdFeed;
    function setBirdFeed(address addr) external onlyOwner {
        aiBirdFeed = AIBirdFeed(addr);
    }

    AIBirds public aiBirds;
    function setAiBirds(address addr) external onlyOwner {
        aiBirds = AIBirds(addr);
    }

    string public baseURI = "";
    function setBaseUri(string memory uri_) external onlyOwner {
        baseURI = uri_;
    }

    function feedBird(uint256 tokenId, uint256 action) external nonReentrant {
        
        require(feedEnabled, "Your bird doesn't want to eat");
        require(birdFeedTracker[tokenId] == false, "Bird can't eat anymore");
        require(aiBirds.ownerOf(tokenId) == msg.sender, "You don't own this bird");
        require(msg.sender == tx.origin, "No smart contracts");

        aiBirdFeed.burn(msg.sender, 0, 1);
        birdFeedTracker[tokenId] = true;
        
        uint256 nextId = totalSupply + 1;
        require(nextId < maxSupply, "Exceeds supply");
        _safeMint(msg.sender, nextId);
        totalSupply = nextId;

        emit UsedBirdFeed(tokenId, action);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
                baseURI,
                Strings.toString(_tokenId),
                ".json"
            )
        ) : "";
    }
}