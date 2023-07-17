// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract RengokuJadeCranes is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private tokenTrack;

    // Contract Variables
    uint256 public constant MAX_SUPPLY = 637;

    // Storage Variables
    string private _baseTokenURI = 'https://rengoku-public.s3.amazonaws.com/jade-crane/metadata/json/';

    // Control Variables
    mapping(address => uint256) public retrievedByAddress;
    bytes32 public merkleRoot;
    bool public retrievalEnabled;

    constructor(bytes32 _merkleRoot) ERC721("Rengoku Jade Cranes", "RENJC") {
        merkleRoot = _merkleRoot;
        enableRetrieval();
    }

    function enableRetrieval() public onlyOwner {
        retrievalEnabled = true;
    }

    function disableRetrieval() public onlyOwner {
        retrievalEnabled = false;
    }

    function retrieve(bytes32[] calldata _merkleProof, uint _qty) public {
        retrieveFor(msg.sender, _merkleProof, _qty);
    }

    function retrieveFor(address _address, bytes32[] calldata _merkleProof, uint _qty) public {
        uint256 qty = _qty - retrievedByAddress[_address];
        require(retrievalEnabled, "Retrieval not enabled");
        require(qty > 0, "Nothing to retrieve");
        require(MerkleProof.verify(_merkleProof, merkleRoot, keccak256(abi.encodePacked(_address, _qty))), "Invalid Proof! Check the wallet address and/or the quantity sent.");
        require(tokenTrack.current().add(qty) < MAX_SUPPLY + 1, "More than max supply");
        retrievedByAddress[_address] += qty;
        for (uint256 i; i < qty; i++) {
            tokenTrack.increment();
            _safeMint(_address, tokenTrack.current());
        }
    }

    function totalSupply() public view returns (uint256) {
        return tokenTrack.current();
    }

    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: burn caller is not owner nor approved");
        _burn(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }
}