// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IRiskToken.sol";

contract RiskToken is ERC721, IRiskToken, Ownable, ReentrancyGuard {

    // ======== Metadata =========
    string public baseTokenURI;

    // ======== Provenance =========
    string public provenanceHash = "";

    // ======== Minter =========
    address public minter;
    bool public isMinterLocked = false;

    using Counters for Counters.Counter;
    Counters.Counter private tokenCounter;

    modifier onlyMinter() {
        require(msg.sender == minter, "Only minter");
        _;
    }
    
    // ======== Constructor =========
    constructor(string memory baseURI) ERC721("RiskRockNFT", "RRN") {
        setBaseURI(baseURI);
    }

    // ======== Minting =========
    function mint(uint256 _count, address _recipient) public override onlyMinter nonReentrant {
        for (uint i = 0; i < _count; i++) {
            uint256 mintIndex = tokenCounter.current() + 1; 
            _safeMint(_recipient, mintIndex);           
            tokenCounter.increment();
        }
    }

    // ======== Minter =========
    function updateMinter(address _minter) external override onlyOwner {
        require(!isMinterLocked, "Minter ownership renounced");
        minter = _minter;
    }

    function lockMinter() external override onlyOwner {
        isMinterLocked = true;
    }

    // ======== Metadata =========
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public override onlyOwner {
        baseTokenURI = baseURI;
    }

    // ======== Provenance =========
    function setProvenanceHash(string memory _provenanceHash) public override onlyOwner {
        provenanceHash = _provenanceHash;
    }

    function tokenCount() public view override returns  (uint256) {
        return tokenCounter.current();
    }

    // ======== Withdraw =========
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}