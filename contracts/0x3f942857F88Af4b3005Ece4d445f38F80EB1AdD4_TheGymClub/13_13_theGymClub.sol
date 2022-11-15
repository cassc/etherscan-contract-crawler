// SPDX-License-Identifier: UNLICENSED

/*

The Gym Club                                                                                                          

*/

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract TheGymClub is ERC721A, Ownable {
    bool public saleEnabled;
    bool public wlSaleEnabled;
    uint256 public price;
    string public metadataBaseURL;

    uint256 public WL_TS = 0;
    uint256 public MAX_TXN = 1;
    uint256 public constant MAX_SUPPLY = 444;
    mapping(address => bool) public claims;
    mapping(address => bool) public wlClaims;

    bytes32 public MerkleRootHex;

    constructor() ERC721A("The Gym Club", "TGC", MAX_SUPPLY) {
        saleEnabled = false;
        wlSaleEnabled = false;
        price = 0.08 ether;
        MerkleRootHex = 0x0;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        MerkleRootHex = _merkleRoot;
    }

    function setBaseURI(string memory baseURL) external onlyOwner {
        metadataBaseURL = baseURL;
    }

    function toggleSaleStatus() external onlyOwner {
        saleEnabled = !(saleEnabled);
    }

    function toggleWLSaleStatus() external onlyOwner {
        wlSaleEnabled = !(wlSaleEnabled);
        WL_TS = block.timestamp + (24 * 60 * 60);
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

    function withdraw() external onlyOwner {
        uint256 _balance = address(this).balance;
        address payable _sender = payable(_msgSender());
        _sender.transfer(_balance);
    }

    function reserve(uint256 num) external onlyOwner {
        require((totalSupply() + num) <= MAX_SUPPLY, "Exceed max supply");
        _safeMint(msg.sender, num);
    }

    function mint(uint256 numOfTokens) external payable {
        require(saleEnabled, "Sale must be active.");
        require(!claims[msg.sender], "Already claimed.");
        require(totalSupply() + numOfTokens <= MAX_SUPPLY, "Exceed max supply");
        require(
            (price * numOfTokens) <= msg.value,
            "Insufficient funds to claim."
        );

        claims[msg.sender] = true;
        _safeMint(msg.sender, numOfTokens);
    }

    function mintWL(uint256 numOfTokens, bytes32[] calldata _merkleProof)
        external
        payable
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, MerkleRootHex, leaf),
            "Invalid proof"
        );
        require(wlSaleEnabled, "WL Sale must be active.");
        require(totalSupply() + numOfTokens <= MAX_SUPPLY, "Exceed max supply");
        require(!wlClaims[msg.sender], "Already claimed.");

        wlClaims[msg.sender] = true;
        _safeMint(msg.sender, numOfTokens);
    }
}