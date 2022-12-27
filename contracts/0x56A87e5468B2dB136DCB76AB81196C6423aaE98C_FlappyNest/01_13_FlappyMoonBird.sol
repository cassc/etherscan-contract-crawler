// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract FlappyNest is ERC721A, ReentrancyGuard, Ownable {

    using Address for address;
    using Strings for uint256;
    uint256 public constant MAX_SUPPLY = 100;
    uint256 public constant WHITELIST_MINT_LIMIT = 2;
    uint256 public constant WHITELIST_MINT_PRICE = 0.1 ether;
    uint256 public constant PUBLIC_MINT_PRICE = 0.2 ether;
    uint256 public constant WHITELIST_MINT_Time = 12 hours;
    uint256 public START_TIME;
    uint256 public PUBLICSALE_START_TIME;

    mapping (address => uint256) public WHITELIST_MINTED;
    string private _baseTokenURI;
    string private _defaultTokenURI;
    bytes32 private _root;

    constructor(uint256 startTime) ERC721A("Flappy Nest", "FN") {
        START_TIME = startTime;
        PUBLICSALE_START_TIME = startTime + WHITELIST_MINT_Time;
        _defaultTokenURI = "ipfs://QmQNVWwtacpZLARYNQVrQjfSwQRbeizRvrYD5ve2UiRiMb";
    }

    function _leaf(address account)
        internal 
        pure 
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal 
        view 
        returns (bool)
    {
        return MerkleProof.verify(proof, _root, leaf);
    }

    function tokenURI(uint256 tokenId) 
        public 
        override 
        view 
        returns 
        (string memory) 
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory _baseURI = baseURI();
        return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenId.toString())) : _defaultTokenURI;
    }

    function whitelistMint(
        uint256 quantity,
        bytes32[] calldata proof
    ) 
        external 
        payable 
    {
        require(block.timestamp >= START_TIME , "Not start");
        require(_verify(_leaf(msg.sender), proof), "Not the WL.");
        require(WHITELIST_MINTED[msg.sender] + quantity <= WHITELIST_MINT_LIMIT, "Over whitelist limit" );
        require(msg.value >= WHITELIST_MINT_PRICE * quantity, "Ether not match");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceed alloc");
        WHITELIST_MINTED[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function publicMint(
        uint256 quantity
    ) 
        external 
        payable 
    {
        require(block.timestamp >= PUBLICSALE_START_TIME, "Public sale not start");
        require(msg.value >= PUBLIC_MINT_PRICE * quantity, "Ether not match");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceed alloc");
        _safeMint(msg.sender, quantity);
    }


    function setRoot(bytes32 merkleroot)
        external
        onlyOwner
    {
        _root = merkleroot;
    }

    function setBaseURI(
        string calldata URI
    ) 
        external 
        onlyOwner 
    {
        _baseTokenURI = URI;
    }

    function setDefaultTokenURI(
        string calldata URI
    ) 
        external 
        onlyOwner 
    {
        _defaultTokenURI = URI;
    }

    function baseURI() 
        public 
        view 
        returns 
        (string memory) 
    {
        return _baseTokenURI;
    }

    function withdraw() 
        external 
        onlyOwner 
    {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}