// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract UNKS is ERC721A, Ownable {
    using Strings for uint256;

    uint256 constant PRICE = 0.03 ether;
    uint8 constant MINTS_PER_WALLET = 4;
    mapping(address => uint8) amountMinted;

    struct UnkData {
        string unrevealedURI;
        string revealedURI;
        uint256 allowListStartTime;
        uint256 publicStartTime;
        bytes32 allowList;
        uint256 unkIndex;
        uint256 MAX_UNKS;
        bool hasTeamMinted;
        bool isRevealed;
    }

    UnkData public unkdata;

    constructor() ERC721A("Unks", "UNKS") {
        unkdata.unkIndex = 0;
        unkdata.MAX_UNKS = 3500;
        unkdata.allowListStartTime = 1661738400;
        unkdata.publicStartTime = 1661695200;
        unkdata.hasTeamMinted = false;
        unkdata.isRevealed = false;
        unkdata
            .unrevealedURI = "https://unks.s3.amazonaws.com/preview/prereveal.json";
        unkdata
            .allowList = 0x772707da833e391decea45a50a83339cfa66f3b6b7c3dd9fe2796d30a16d6f7e;
    }

    function changeAllowlist(bytes32 newList) public onlyOwner {
        unkdata.allowList = newList;
    }

    function changeAllowlistStartTime(uint256 newTime) public onlyOwner {
        unkdata.allowListStartTime = newTime;
    }

    function changePublicStartTime(uint256 newTime) public onlyOwner {
        unkdata.publicStartTime = newTime;
    }

    function toggleTokenReveal() public onlyOwner {
        unkdata.isRevealed = !unkdata.isRevealed;
    }

    function setRevealedURI(string memory newURI) public onlyOwner {
        unkdata.revealedURI = newURI;
    }

    function publicMint(uint8 amount) public payable {
        if (block.timestamp < unkdata.publicStartTime) {
            revert("Not Public Mint Time.");
        }
        if (msg.value < amount * PRICE) {
            revert("Insufficient Payment");
        }
        if (amountMinted[msg.sender] + amount > 4) {
            revert("Too Many Unks");
        }
        if (unkdata.unkIndex + amount > unkdata.MAX_UNKS) {
            revert("Minting beyond scope");
        }
        amountMinted[msg.sender] += amount;
        unkdata.unkIndex += amount;
        _mint(msg.sender, amount);
    }

    function allowlistMint(uint8 amount, bytes32[] calldata proof)
        public
        payable
    {
        if (block.timestamp < unkdata.allowListStartTime) {
            revert("Not Advanced Mint Time.");
        }
        if (block.timestamp > unkdata.publicStartTime) {
            revert("Not Advanced Mint Time.");
        }
        if (msg.value < amount * PRICE) {
            revert("Insufficient Payment");
        }
        if (amountMinted[msg.sender] + amount > 4) {
            revert("Too Many Unks");
        }
        if (unkdata.unkIndex + amount > unkdata.MAX_UNKS) {
            revert("Minting beyond scope");
        }
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        bool isAllowed = MerkleProof.verify(proof, unkdata.allowList, leaf);
        require(isAllowed, "Not Allowlisted");
        amountMinted[msg.sender] += amount;
        unkdata.unkIndex += amount;
        _mint(msg.sender, amount);
    }

    function teamMint() public onlyOwner {
        require(!unkdata.hasTeamMinted, "Already Minted");
        unkdata.unkIndex += 160;
        _mint(0xdbf137072D98CFD292e7Fa1B06b99536537047dD, 160);
    }

    function tokenURI(uint256 _tokenID)
        public
        view
        override
        returns (string memory)
    {
        require(_tokenID <= unkdata.unkIndex, "Unreal Token");
        require(_tokenID > 0, "Unreal Token");
        if (unkdata.isRevealed) {
            return
                string(
                    abi.encodePacked(unkdata.revealedURI, _tokenID.toString())
                );
        } else {
            return string(abi.encodePacked(unkdata.unrevealedURI));
        }
    }

    function withdrawAll() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}