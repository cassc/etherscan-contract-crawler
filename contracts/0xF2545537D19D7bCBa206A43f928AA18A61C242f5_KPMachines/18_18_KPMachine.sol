// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

//  _   __                    _ _  ______ _           _     _           
// | | / /                   (_|_) | ___ \ |         | |   (_)          
// | |/ /  __ ___      ____ _ _ _  | |_/ / |_   _ ___| |__  _  ___  ___ 
// |    \ / _` \ \ /\ / / _` | | | |  __/| | | | / __| '_ \| |/ _ \/ __|
// | |\  \ (_| |\ V  V / (_| | | | | |   | | |_| \__ \ | | | |  __/\__ \
// \_| \_/\__,_| \_/\_/ \__,_|_|_| \_|   |_|\__,_|___/_| |_|_|\___||___/
// 

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract KPMachines is ERC721, ERC721Enumerable, ERC721URIStorage, AccessControl {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    bytes32 public merkleRoot;
    string baseURI = "";

    uint public startTimestamp;
    uint public maxSupply;
    uint public mintsPerAddress = 2;
    mapping(address => uint) public mints;

    constructor(bytes32 _merkleRoot, uint _maxSupply, uint _startTimestamp) ERC721("KP Machines", "KPM") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        merkleRoot = _merkleRoot;
        maxSupply = _maxSupply;
        startTimestamp = _startTimestamp;
    }

    function safeMint(bytes32[] calldata _merkleProof) public {
        require(block.timestamp >= startTimestamp, "not started yet");
        require(totalSupply() < maxSupply, "sold out");
        require(isWhitelisted(msg.sender, _merkleProof), "not whitelisted");
        require(mints[msg.sender] < mintsPerAddress, "whitelist already used");
        require(tx.origin == msg.sender, "no contract allowed");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);

        mints[msg.sender]++;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _base) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _base;
    }

    function isWhitelisted(address addr, bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
        merkleRoot = _merkleRoot;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return _baseURI();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}