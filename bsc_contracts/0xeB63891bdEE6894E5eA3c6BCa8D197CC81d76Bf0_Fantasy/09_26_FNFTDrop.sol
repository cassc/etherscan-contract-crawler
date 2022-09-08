// SPDX-License-Identifier: MIT LICENSE

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract FNFTDrop is ERC721Enumerable, Ownable {
    using MerkleProof for bytes32[];

    mapping(address => bool) public alreadyMinted;

    uint16 private reserveFNFTDropsId;
    uint16 private FNFTsId;

    bytes32 public merkleRoot;
    bool public merkleEnabled = true;

    string private baseURI;

    bool private saleStarted = true;
    uint256 public constant maxMint = 4000;

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    constructor() ERC721("Fantasy", "FNFT") {
        reserveFNFTDropsId = 2000;
        FNFTsId = 2001;
    }

    function reserveMicDrops(address to, uint8 amount) public onlyOwner {
        require(reserveFNFTDropsId + amount <= 4000, "Out of stock");

        for (uint8 i = 0; i < amount; i++) _safeMint(to, reserveFNFTDropsId++);
    }

    function setMerkleRoot(bytes32 _root) public onlyOwner {
        merkleRoot = _root;
    }

    function startMerkle() public onlyOwner {
        merkleEnabled = true;
    }

    function stopMerkle() public onlyOwner {
        merkleEnabled = false;
    }
}