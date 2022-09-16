// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Lawrence X. Rogers

pragma solidity ^0.8.9;

import "contracts/IMergeFlowerArt.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/// @title MergeFlowers
/// @author Lawrence X Rogers
/// @notice This smart contract creates on-chain NFT flower "buds" that bloom when the Ethereum Merge completes.
/// @notice It communicates with the contract MergeFlowerArt to generate the art.

contract MergeFlowers is ERC721, Ownable {
    using Strings for uint256;

    bool public hasMerged = false;

    enum MintPhase {WAITING, WHITELIST, OPEN}
    MintPhase public currentMintPhase;
    uint constant public TOTAL_SUPPLY = 2000;
    uint public tokenCounter = 0;

    uint constant MINT_FEE = 0.025 ether;
    uint constant WL_MINT_FEE = 0.01 ether;
    uint public balance;
    mapping (address => bool) hasMinted;

    address public artAddress; //art contract

    uint prevrandao = 42;

    struct AttrData {
        bytes hintColor;
    }

    mapping (address => uint) public whitelistMints;
    mapping (uint => AttrData) attributes;

    constructor(address[] memory whitelist, address _artAddress ) ERC721("Merge Flowers", "MGF") {
        artAddress = _artAddress;
        currentMintPhase = MintPhase.WAITING;

        addToWhitelist(whitelist);
    }


    /// @notice adds addresses to the whitelist, incrementing whitelist supply for each duplicate
    /// @dev this is NOT a very efficient way to do whitelists.
    function addToWhitelist(address[] memory toAdd) public {
        for (uint i = 0; i < toAdd.length; i++) {
            whitelistMints[toAdd[i]]++;
        }
    }

    /// @notice mints during the whitelist, at a cheaper price and allowing batch minting
    function wlMint(uint count) external payable {
        require(currentMintPhase == MintPhase.WHITELIST);
        require(msg.value >= count * WL_MINT_FEE, "MGF: Mint fee not met");
        require(count <= whitelistMints[msg.sender], "MGF: Not enough WL slots");
        require (tokenCounter + count <= TOTAL_SUPPLY, "MGF: Sold out");
        balance += msg.value;

        for (uint i = 0; i < count; i++) {
            whitelistMints[msg.sender]--;
            tokenCounter++;
            _safeMint(msg.sender, tokenCounter - 1);
        }
    }

    /// @notice mint during the open phase
    /// @notice minting is disabled after the merge
    function openMint() external payable {
        require (currentMintPhase == MintPhase.OPEN, "MGF: Mint not open yet");
        require (tokenCounter <= TOTAL_SUPPLY, "MGF: Sold out");
        require (!checkMerge(), "MGF: Minting disabled after merge");
        require(!hasMinted[msg.sender], "MGF: sender already minted");
        require(msg.value >= MINT_FEE, "MGF: Mint fee not met");
           
        hasMinted[msg.sender] = true;
        balance+= msg.value;
        tokenCounter++;
        _safeMint(msg.sender, tokenCounter - 1);
    }

    /// @notice gets a list of tokenIds per owner. more gas-efficient than ERC721 Enumerable
    function getTokensByOwner(address owner, uint start, uint end) public view returns(uint[] memory) {
        uint[] memory tokens = new uint[](balanceOf(owner));
        uint found = 0;
        for (uint i = start; i < end; i++) {
            if (ownerOf(i) == owner) {
                tokens[found] = i;
                found++;
            }
        }
        return tokens;
    }

    /// @notice detect whether the merge has happened based on block.difficulty
    function hasMergedYet() public view returns (bool) {
        return (block.difficulty > (2**64)) || (block.difficulty == 0);
    }

    /// @notice function to check if the merge has happened, and if it has, turn hasMerged to true, causing the flowers to "bloom"
    function checkMerge() public returns (bool) {
        if (hasMerged) {
            return true;
        }
        else if (hasMergedYet()) {
            hasMerged = true;
            prevrandao = block.difficulty;
            return true;
        }
        return false;
    }

    /// @notice failsafe allowing the owner to set the flowers to bloomed, in case assumptions about block.difficulty don't hold true
    function setMerged() public onlyOwner {
        require(!hasMerged, "MGF: Already merged");
        hasMerged = true;
        prevrandao = block.difficulty;
    }

    function advancePhase() external onlyOwner {
        if (currentMintPhase == MintPhase.WAITING) {
            currentMintPhase = MintPhase.WHITELIST;
        }
        else if (currentMintPhase == MintPhase.WHITELIST) {
            currentMintPhase = MintPhase.OPEN;
        }
        else {
            return;
        }
    }

    /// @notice returns bud art unless hasMerged is true, then return flower art
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "MGF: Token doesn't exist");
        
        if (!hasMerged) {
            bytes memory imageURI = IMergeFlowerArt(artAddress).getBudArt(tokenId);
            return formatTokenURI(imageURI, "", tokenId, "[]");
        }
        else {
            (bytes memory imageURI, bytes memory animationURI, bytes memory attributesBytes) = IMergeFlowerArt(artAddress).getFlowerArt(prevrandao, tokenId);
            return formatTokenURI(imageURI, animationURI, tokenId, attributesBytes);
        }
    }

    function formatTokenURI(bytes memory imageURI, bytes memory animationURI, uint tokenId, bytes memory attributesBytes) internal pure returns (string memory) {
        bytes memory anim = animationURI.length != 0 ? abi.encodePacked(',"animation_url":"', animationURI, '"') : abi.encodePacked("");

        return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"',
                            "MergeFlower #", tokenId.toString(), '",' ,
                            '"attributes":', attributesBytes,
                            ', "description":"Flowers that bloom when the Merge completes",',
                            '"image":"', imageURI , '"',
                            anim, '}'
                        )
                    )
                )
            );
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "MGF: Transfer failed");
        balance = 0;
    }

    
}