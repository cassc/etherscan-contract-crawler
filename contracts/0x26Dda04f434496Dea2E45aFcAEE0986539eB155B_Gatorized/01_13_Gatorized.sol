// SPDX-License-Identifier: UNLICENSED

/*

ContractExample                                                                                                          

*/

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Gatorized is ERC721A, Ownable {
    bool public saleEnabled;
    bool public wlSaleEnabled;
    uint256 public price;
    string public metadataBaseURL;
    string public PROVENANCE;

    uint256 public MAX_MINT_PER_WALLET = 3;
    uint256 public constant WL_SUPPLY = 1500;
    uint256 public constant PAID_SUPPLY = 3500;
    uint256 public constant MAX_SUPPLY = WL_SUPPLY + PAID_SUPPLY;
    uint256 public constant GLOBAL_MAX_TXN = MAX_SUPPLY;
    mapping(address => bool) public whitelistClaims;
    mapping(address => uint256) public mints;

    bytes32 public MerkleRootHex;

    constructor() ERC721A("Gatorized", "GTRZD", GLOBAL_MAX_TXN) {
        saleEnabled = false;
        wlSaleEnabled = false;
        price = 0.0069 ether;
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

    function setMaxPerWallet(uint256 _maxPerwallet) external onlyOwner {
        MAX_MINT_PER_WALLET = _maxPerwallet;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataBaseURL;
    }

    function setProvenance(string memory _provenance) external onlyOwner {
        PROVENANCE = _provenance;
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
        require(totalSupply() + numOfTokens <= MAX_SUPPLY, "Exceed max supply");
        require(
            mints[msg.sender] + numOfTokens <= MAX_MINT_PER_WALLET,
            "Exceed max per wallet"
        );
        require(
            (price * numOfTokens) <= msg.value,
            "Insufficient funds to claim."
        );

        mints[msg.sender] += numOfTokens;
        _safeMint(msg.sender, numOfTokens);
    }

    function whitelistMint(bytes32[] calldata _merkleProof) external payable {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, MerkleRootHex, leaf),
            "Invalid proof"
        );
        require(!whitelistClaims[msg.sender], "Exceed max whitelist mint");
        require(wlSaleEnabled, "WL Sale must be active.");
        require(totalSupply() + 1 <= WL_SUPPLY, "Exceed max supply");

        whitelistClaims[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }
}