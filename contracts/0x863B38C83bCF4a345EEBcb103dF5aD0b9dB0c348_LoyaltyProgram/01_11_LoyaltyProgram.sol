// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract LoyaltyProgram is Ownable, ERC721AQueryable, ReentrancyGuard {
    string private metadataUri;

    uint256 public mintLimit;
    uint256 public mintStartTime;
    uint256 public mintEndTime;

    modifier isNotContract() {
        require(msg.sender == tx.origin, "Sender is not EOA");
        _;
    }

    modifier checkMintTimes() {
        require(block.timestamp >= mintStartTime, "The event has not started yet.");
        require(block.timestamp <= mintEndTime, "The event has ended.");
        _;
    }


    constructor(
        uint256 _mintStartTime,
        uint256 _mintEndTime,
        uint256 _mintLimit,
        string memory _metadataUri
    ) ERC721A("Loyalty Program", "Loyalty Program") {
        require(_mintStartTime < _mintEndTime, "Invalid StartTimes");
        require(_mintLimit > 0, "Invalid MintLimit");
        mintStartTime = _mintStartTime;
        mintEndTime = _mintEndTime;
        mintLimit = _mintLimit;
        metadataUri = _metadataUri;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return metadataUri;
    }

    function mint() external nonReentrant isNotContract checkMintTimes {
        require(_numberMinted(msg.sender) + 1 <= mintLimit, "You have reached the claim limit(5)");
        _safeMint(msg.sender, 1);
    }

    function getMintSurplus(address userAddress) view external returns (uint256) {
        return mintLimit - _numberMinted(userAddress);
    }

    function setMintTimes(uint256 _mintStartTime, uint256 _mintEndTime) external onlyOwner {
        require(_mintStartTime < _mintEndTime, "Invalid StartTimes");
        mintStartTime = _mintStartTime;
        mintEndTime = _mintEndTime;
    }
}