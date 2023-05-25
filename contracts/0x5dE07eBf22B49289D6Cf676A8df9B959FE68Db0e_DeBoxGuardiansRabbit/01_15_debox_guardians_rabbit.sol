/**
 *Submitted for verification at Etherscan.io on 2022-10-13
*/

// SPDX-License-Identifier: MIT
// Creator: Debox Labs

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract DeBoxGuardiansRabbit is ERC721, ERC721Enumerable, Ownable {

    event NFTMint(address indexed eoa, uint256 offset, uint32 num);
    event NFTMintAllowList(address indexed eoa, uint256 offset, uint32 num);
    event NFTReserve(address indexed eoa, uint256 offset, uint32 num);

    string private baseURIextended;
    mapping(address => uint32) private minted;

    bool public saleActive = false;
    bool public preSaleActive = false;

    uint32 public constant MAX_SUPPLY = 2048;
    uint256 public constant PUBLIC_PRICE = 0.16 ether;
    uint256 public constant ALLOW_PRICE = 0.08 ether;

    bytes32 public root;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;  
    }
    constructor(bytes32 root_,string memory baseURI_) ERC721("DeBox Guardians Rabbit", "DeBox") {
        root = root_;
        baseURIextended = baseURI_;    
    }

    function setRoot(bytes32 root_) public onlyOwner {
        root = root_;
    }

    function isValid(bytes32[] memory proof, bytes32 leaf) private view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override (ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURIextended;
    }

    function reserve(uint32 num) public onlyOwner {
        uint256 ts = totalSupply();
        require(ts + num <= MAX_SUPPLY, "Purchase would exceed max tokens");
        for (uint32 i = 0; i < num; i++) {
            _safeMint(msg.sender, ts + i);
        }
        emit NFTReserve(msg.sender, ts, num);
    }

    function setSaleState(bool newState) public onlyOwner {
        saleActive = newState;
    }
    function setPreSaleState(bool newState) public onlyOwner {
        preSaleActive = newState;
    }

    function mintAllowList(uint256 index, bytes32[] memory proof, uint32 num) external payable callerIsUser {
        uint256 ts = totalSupply();
        require(preSaleActive, "Sale must be active to mint tokens");
        require(num <= 1, "Exceeded max token per purchase");
        require(minted[msg.sender] == 0, "Exceeded max token purchase");
        require(ts + num <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(isValid(proof, keccak256(abi.encodePacked(index, msg.sender))), "Not a part of Allowlist");
        require(ALLOW_PRICE * num <= msg.value, "Ether value sent is not correct");
        minted[msg.sender] += num;
        for (uint32 i = 0; i < num; i++) {
            _safeMint(msg.sender, ts + i);
        }
        emit NFTMintAllowList(msg.sender, ts, num);
    }

    function mint(uint32 num) public payable callerIsUser {
        uint256 ts = totalSupply();
        require(saleActive, "Sale must be active to mint tokens");
        require(num <= 3, "Exceeded max token per purchase");
        require(minted[msg.sender] + num <= 10, "Exceeded max token purchase");
        require(ts + num <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PUBLIC_PRICE * num <= msg.value, "Ether value sent is not correct");
        minted[msg.sender] += num;
        for (uint32 i = 0; i < num; i++) {
            _safeMint(msg.sender, ts + i);
        }
        emit NFTMint(msg.sender, ts, num);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}