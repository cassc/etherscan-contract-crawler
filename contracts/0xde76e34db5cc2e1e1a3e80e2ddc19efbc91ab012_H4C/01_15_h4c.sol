// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract H4C is ERC721Enumerable, Ownable {
    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant MAX_MINT_PUBLIC = 2;
    uint256 public constant H4C_LIST_PRICE = 0.015 ether;
    uint256 public constant PUBLIC_SALE_PRICE = 0.025 ether;

    uint32 public h4cListStartTime = 1671454800;
    uint32 public h4cListEndTime = 1671465600;

    bytes32 public h4cOgListRoot;
    bytes32 public h4cListRoot;
    bool public teamMinted;
 
    mapping(address => uint256) public h4cMintedByAddress;
    mapping(address => bool) public h4cListMinted;
    
    uint256 private h4cListMintedTotal;
    string private _baseTokenURI = "https://h4c.mypinata.cloud/ipfs/QmV3JPpV6kKZJUQifdnefVuhA4H5FWbavXTR5GADGVWW1o/";

    constructor() ERC721("H4C", "H4C") {}

    function setH4cOgListRoot(uint256 root) external onlyOwner {
        h4cOgListRoot = bytes32(root);
    }

    function setH4cListRoot(uint256 root) external onlyOwner {
        h4cListRoot = bytes32(root);
    }

    function ogPresaleMint(bytes32[] memory h4cListProof) external payable {
        require(
            block.timestamp >= h4cListStartTime &&
                block.timestamp < h4cListEndTime,
            "Sale not active"
        );
        require(!h4cListMinted[msg.sender], "Already minted");
        bytes32 h4cListLeaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(h4cListProof, h4cOgListRoot, h4cListLeaf),
            "Not whitelisted"
        );
        require(msg.value == H4C_LIST_PRICE, "Insufficient payment");
        h4cListMinted[msg.sender] = true;
        uint256 tokenId = totalSupply() + 1;
        _safeMint(msg.sender, tokenId);
    }

    function presaleMint(bytes32[] memory h4cListProof) external payable {
        require(
            block.timestamp >= h4cListStartTime &&
                block.timestamp < h4cListEndTime,
            "Sale not active"
        );
        require(!h4cListMinted[msg.sender], "Already minted");
        bytes32 h4cListLeaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(h4cListProof, h4cListRoot, h4cListLeaf),
            "Not whitelisted"
        );
        require(h4cListMintedTotal <= 1500, "Whitelist sold out");
        require(msg.value == H4C_LIST_PRICE, "Insufficient payment");
        h4cListMinted[msg.sender] = true;
        ++h4cListMintedTotal;
        uint256 tokenId = totalSupply() + 1;
        _safeMint(msg.sender, tokenId);
    }

    function publicSaleMint(uint256 quantity) external payable {
        uint256 ts = totalSupply();
        if (ts < 2053) {
            require(block.timestamp >= h4cListEndTime, "Sale not active");
        }
        require(ts + quantity <= MAX_SUPPLY, "Sold out");
        require(
            h4cMintedByAddress[msg.sender] + quantity <= MAX_MINT_PUBLIC,
            "No more than two during public"
        );
        require(
            msg.value == PUBLIC_SALE_PRICE * quantity,
            "Insufficient payment"
        );
        h4cMintedByAddress[msg.sender] += quantity;
        for (uint256 i = 1; i <= quantity; i++) {
            uint256 tokenId = ts + i;
            _safeMint(msg.sender, tokenId);
        }
    }

    function setPresale(uint32 start, uint32 end) external onlyOwner {
        h4cListStartTime = start;
        h4cListEndTime = end;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function teamMint(address h4cVault) external onlyOwner {
        require(!teamMinted, "Already done");
        teamMinted = true;
        for (uint256 i = 1; i <= 25; i++) {
            _safeMint(h4cVault, i);
        }
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}