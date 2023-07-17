// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Isoroom is ERC721, ERC721Enumerable, Ownable {
    // @dev refer to setProvenance and randomSeedIndex function
    event Provenance(uint256 indexed proveType, bytes32 proveData);

    string private _baseURIextended;

    string private constant ERR_ONLY_EOA = "Only EOA";
    string private constant ERR_MINT_END = "Minting ended";
    string private constant ERR_MINT_NOT_START = "Not started yet";
    string private constant ERR_LIMIT_EXCEED = "Limit exceeded";
    string private constant ERR_WRONG_VALUE = "Value not correct";
    string private constant ERR_NOT_WHITELIST = "Not whitelisted";

    uint256 public constant MAX_GENESIS_SUPPLY = 3000;
    uint256 public constant GLOBAL_MINTING_LIMIT = 2;
    uint256 public constant GENESIS_PRICE = 0.0888 ether;
    uint16 public constant MAX_RESERVE = 20;

    bytes32 public merkleRootForOneTicket = 0x0;
    bytes32 public merkleRootForTwoTicket = 0x0;

    mapping(address => uint8) public ticketRecord;

    uint8 public activeStage = 0;

    constructor() ERC721("isoroom", "ISOROOM") {}

    function setMerkleRoot(uint _ticketType, bytes32 _merkleRoot) 
        external
        onlyOwner 
    {
        if (_ticketType == 1) {
            merkleRootForOneTicket = _merkleRoot;
        } else {
            merkleRootForTwoTicket = _merkleRoot;
        }
    }

    function setActiveStage(uint8 _stage)
        external
        onlyOwner
    {
        activeStage = _stage;
    }

    function getIdAndMint(address receiver)
        internal
    {
        uint256 totalSupply = totalSupply();
        uint256 nextId = totalSupply + 1;
        _mint(receiver, nextId);
    }

    /**
     * Minting script start
     */
    function preSales(uint8 _ticket, uint8 _numberOfTokens, bytes32[] calldata _merkleProof)
        external
        payable
    {
        require(msg.sender == tx.origin, ERR_ONLY_EOA);
        require(activeStage >= 1, ERR_MINT_NOT_START);
        require(_ticket == 1 || _ticket == 2, ERR_NOT_WHITELIST);

        uint256 totalSupply = totalSupply();
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        bool proofed = (_ticket == 1 && MerkleProof.verify(_merkleProof, merkleRootForOneTicket, leaf))
                    || (_ticket == 2 && MerkleProof.verify(_merkleProof, merkleRootForTwoTicket, leaf));
        require(proofed, ERR_NOT_WHITELIST);
        require(totalSupply + _numberOfTokens <= MAX_GENESIS_SUPPLY, ERR_LIMIT_EXCEED);

        bool hasLimit = ticketRecord[msg.sender] + _numberOfTokens <= _ticket;
        require(hasLimit, ERR_LIMIT_EXCEED);
        require(GENESIS_PRICE * _numberOfTokens <= msg.value, ERR_WRONG_VALUE);

        ticketRecord[msg.sender] += _numberOfTokens;

        for (uint256 i = 0; i < _numberOfTokens; i++) {
            getIdAndMint(msg.sender);
        }
    }

    function genesisMint(uint _numberOfTokens) public payable {
        require(msg.sender == tx.origin, ERR_ONLY_EOA);

        uint256 totalSupply = totalSupply();
        require(totalSupply < MAX_GENESIS_SUPPLY,
            ERR_MINT_END);
        require(activeStage >= 2,
            ERR_MINT_NOT_START);
        require(_numberOfTokens <= GLOBAL_MINTING_LIMIT, 
            ERR_LIMIT_EXCEED);
        require(totalSupply + _numberOfTokens <= MAX_GENESIS_SUPPLY, 
            ERR_LIMIT_EXCEED);
        require(GENESIS_PRICE * _numberOfTokens <= msg.value, 
            ERR_WRONG_VALUE);

        for (uint256 i = 0; i < _numberOfTokens; i++) {
            getIdAndMint(msg.sender);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) 
        internal 
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) 
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    /**
     * @dev owner can reserve token for auction and giftaway
     * only before start
     */
    function reserve(uint256 n) public onlyOwner {
        require(totalSupply() == 0, ERR_LIMIT_EXCEED);
        require(n <= MAX_RESERVE, ERR_LIMIT_EXCEED);

        for (uint i = 0; i < n; i++) {
            getIdAndMint(msg.sender);
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * @dev to prove the date metadata integrity, isoteam will
     * publish metadata hash on Provenance event
     * _proveType 1: Genesis Room Metadata Hash
     */
    function setProvenance(bytes32 _proveData) public onlyOwner {
        emit Provenance(1, _proveData);
    }

    /**
     * @dev to prove the date metadata integrity, isoteam will
     * publish a random seed index on Provenance event
     * proveType 2: Genesis Room Seed Index
     */
    function randomSeedIndex() external onlyOwner {
        uint256 number = uint(keccak256(
            abi.encodePacked(block.difficulty, block.timestamp)));
        
        bytes32 n = bytes32(number % MAX_GENESIS_SUPPLY);
            emit Provenance(2, n);
    }
}