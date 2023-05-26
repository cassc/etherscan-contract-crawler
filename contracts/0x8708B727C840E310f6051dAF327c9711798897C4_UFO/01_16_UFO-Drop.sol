// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract UFO is ERC721Enumerable, Ownable, ReentrancyGuard {
    constructor() ERC721("AF UFOS", "UFO") {}

    uint256 public maxAF = 1;
    uint256 public maxSC = 1;
    uint256 public maxPublicTx; //max per tx public mint

    uint256 public amountForTeam;
    string private _baseTokenURI;

    bool public _isActive = false;

    mapping(address => uint8) public _AFListCounter;
    mapping(address => uint8) public _SCListCounter;

    // trait counters (tokenID => trait num) -- zero indexed
    mapping(uint256 => uint8) public trait1;
    mapping(uint256 => uint8) public trait2;
    mapping(uint256 => uint8) public trait3;
    mapping(uint256 => uint8) public trait4;

    // max number for trait, (so users can't mint a trait that doesn't exist)
    uint8 trait1max = 8;
    uint8 trait2max = 26;
    uint8 trait3max = 22;
    uint8 trait4max = 27;

    // merkle root
    bytes32 public AFRoot;
    bytes32 public SCRoot;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    //set variables
    function setActive(bool isActive) external onlyOwner {
        _isActive = isActive;
    }

    function setAFmax(uint256 quantity) external onlyOwner {
        maxAF = quantity;
    }

    function setSCmax(uint256 quantity) external onlyOwner {
        maxSC = quantity;
    }

    function setAFSaleRoot(bytes32 _root) external onlyOwner {
        AFRoot = _root;
    }

    function setSCSaleRoot(bytes32 _root) external onlyOwner {
        SCRoot = _root;
    }

    function setTrait1Max(uint8 _num) external onlyOwner {
        trait1max = _num;
    }

    function setTrait2Max(uint8 _num) external onlyOwner {
        trait2max = _num;
    }

    function setTrait3Max(uint8 _num) external onlyOwner {
        trait3max = _num;
    }

    function setTrait4Max(uint8 _num) external onlyOwner {
        trait4max = _num;
    }

    // metadata URI
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");
        return
            string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId)));
    }

    function getTraits(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return
            string(
                abi.encodePacked(
                    "{'0':",
                    Strings.toString(trait1[tokenId]),
                    ",'1':",
                    Strings.toString(trait2[tokenId]),
                    ",'2':",
                    Strings.toString(trait3[tokenId]),
                    ",'3':",
                    Strings.toString(trait4[tokenId]),
                    "}"
                )
            );
    }

    //withdraw to owner wallet
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // public mint
    function AFMint(
        uint8 _trait1,
        uint8 _trait2,
        uint8 _trait3,
        uint8 _trait4,
        bytes32[] calldata _merkleProof
    ) external payable nonReentrant callerIsUser {
        require(_trait1 < trait1max, "invalid trait number");
        require(_trait2 < trait2max, "invalid trait number");
        require(_trait3 < trait3max, "invalid trait number");
        require(_trait4 < trait4max, "invalid trait number");
        require(_isActive, "public sale has not begun yet");
        require(
            _AFListCounter[msg.sender] + 1 <= maxAF,
            "Exceeded max available to purchase"
        );

        // check proof & mint
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, AFRoot, leaf),
            "Invalid MerkleProof"
        );

        _AFListCounter[msg.sender] = _AFListCounter[msg.sender] + 1;
        
        uint256 tokenId = totalSupply();

        trait1[tokenId] = _trait1;
        trait2[tokenId] = _trait2;
        trait3[tokenId] = _trait3;
        trait4[tokenId] = _trait4;

        _safeMint(msg.sender, tokenId);
    }

    // public mint
    function SCMint(
        uint8 _trait1,
        uint8 _trait2,
        uint8 _trait3,
        uint8 _trait4,
        bytes32[] calldata _merkleProof
    ) external payable nonReentrant callerIsUser {
        require(_trait1 < trait1max, "invalid trait number");
        require(_trait2 < trait2max, "invalid trait number");
        require(_trait3 < trait3max, "invalid trait number");
        require(_trait4 < trait4max, "invalid trait number");
        require(_isActive, "public sale has not begun yet");
        require(
            _SCListCounter[msg.sender] + 1 <= maxSC,
            "Exceeded max available to purchase"
        );

        // check proof & mint
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, SCRoot, leaf),
            "Invalid MerkleProof"
        );

        _SCListCounter[msg.sender] = _SCListCounter[msg.sender] + 1;

        uint256 tokenId = totalSupply();

        trait1[tokenId] = _trait1;
        trait2[tokenId] = _trait2;
        trait3[tokenId] = _trait3;
        trait4[tokenId] = _trait4;

        _safeMint(msg.sender, tokenId);
    }
}