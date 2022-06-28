// SPDX-License-Identifier: UNLICENSED

/*

its something...!                                                                                                        

*/

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract itsSomething is ERC721A, Ownable {
    bool public saleEnabled;
    uint256 public price;
    string public metadataBaseURL;
    bytes32 public MerkleRootHex;

    uint256 public MAX_TXN_GLOBAL = 6666;
    uint256 public MAX_TXN = 10;
    uint256 public MAX_WL_CLAIM = 3;
    uint256 public constant MAX_SUPPLY = 6666;
    mapping(address => bool) public freeClaims;
    mapping(address => uint256) public wlClaims;

    constructor() ERC721A("Its Something", "SMTHNG", MAX_TXN_GLOBAL) {
        saleEnabled = false;
        price = 0.01 ether;
    }

    function setBaseURI(string memory baseURL) external onlyOwner {
        metadataBaseURL = baseURL;
    }

    function toggleSaleStatus() external onlyOwner {
        saleEnabled = !(saleEnabled);
    }

    function setMaxTxn(uint256 _maxTxn) external onlyOwner {
        MAX_TXN = _maxTxn;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataBaseURL;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        MerkleRootHex = _merkleRoot;
    }

    function withdraw() external onlyOwner {
        uint256 _balance = address(this).balance;
        address payable _sender = payable(_msgSender());
        _sender.transfer(_balance);
    }

    function reserve(uint256 num) external onlyOwner {
        require((totalSupply() + num) <= MAX_SUPPLY, "Exceed max supply");
        _safeMint(msg.sender, num);
    }

    function freeClaimed() public view returns (bool) {
        return freeClaims[msg.sender];
    }

    function wlClaimed() public view returns (uint256) {
        return wlClaims[msg.sender];
    }

    function freeMint(uint256 numOfTokens) external payable {
        require(saleEnabled, "Sale must be active.");
        require(!freeClaims[msg.sender], "Already claimed free mint.");
        require(totalSupply() + numOfTokens <= MAX_SUPPLY, "Exceed max supply");
        require(numOfTokens == 1, "Can only mint 1");

        freeClaims[msg.sender] = true;
        _safeMint(msg.sender, numOfTokens);
    }

    function mint(uint256 numOfTokens) external payable {
        require(saleEnabled, "Sale must be active.");
        require(totalSupply() + numOfTokens <= MAX_SUPPLY, "Exceed max supply");
        require(numOfTokens <= MAX_TXN, "Cant mint more than 10");
        require(
            (price * numOfTokens) <= msg.value,
            "Insufficient funds to claim."
        );

        _safeMint(msg.sender, numOfTokens);
    }

    function wlMint(uint256 numOfTokens, bytes32[] calldata _merkleProof)
        external
        payable
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, MerkleRootHex, leaf),
            "Invalid proof"
        );

        require(
            wlClaims[msg.sender] + numOfTokens <= MAX_WL_CLAIM,
            "Exceed WL claims"
        );
        require(saleEnabled, "Sale must be active.");
        require(totalSupply() + numOfTokens <= MAX_SUPPLY, "Exceed max supply");

        wlClaims[msg.sender] += numOfTokens;
        _safeMint(msg.sender, numOfTokens);
    }
}