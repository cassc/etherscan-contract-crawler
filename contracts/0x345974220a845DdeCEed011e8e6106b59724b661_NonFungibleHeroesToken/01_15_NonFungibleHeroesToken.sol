// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./INonFungibleHeroesToken.sol";

contract NonFungibleHeroesToken is INonFungibleHeroesToken, Ownable, ReentrancyGuard {

    // ======== Metadata =========
    string public baseTokenURI;

    // ======== Provenance =========
    string public provenanceHash = "";

    // ======== Minter =========
    address public minter;
    bool public isMinterLocked = false;

    modifier onlyMinter() {
        require(msg.sender == minter, "Only minter");
        _;
    }
    
    // ======== Constructor =========
    constructor(string memory baseURI) ERC721("NonFungibleHeroes", "NFH") {
        setBaseURI(baseURI);
    }

    // ======== Minting =========
    function mint(uint256 _count, address _recipient) public override onlyMinter nonReentrant {
        uint256 supply = totalSupply();
        for (uint i = 0; i < _count; i++) {
            _safeMint(_recipient, supply + i);
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

    // ======== Withdraw =========
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}