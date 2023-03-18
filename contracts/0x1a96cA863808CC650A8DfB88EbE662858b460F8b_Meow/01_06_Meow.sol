//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Meow is ERC721A, Ownable, ReentrancyGuard {

    uint goldQuantity = 10;
    uint normalQuantity = 578;
    uint normalMintPrice = 0.05 ether;
    uint goldMintPrice = 10 ether;

    uint maxWalletMintCount = 2;
    uint maxQuantityPerMint = 100;
    mapping(address => uint) public walletMintCount;

    uint public goldMintedCount;
    uint public normalMintedCount;
    mapping(uint => bool) public isGoldTokenId;

    string public baseURI;
    mapping(address => bool) public isRestrict;

    constructor(string memory baseURI_) ERC721A("Meow Pass", "Meow") {
        baseURI = baseURI_;
        isRestrict[0x00000000000111AbE46ff893f3B2fdF1F759a8A8] = true; //blur bid
    }

    function maxSupply() public view returns (uint) {
        return (goldQuantity + normalQuantity);
    }

    
    function mintNormal(uint256 quantity) external payable nonReentrant {
        require(
            quantity <= maxQuantityPerMint,
            "mintNormal: Over Max Quantity Per Mint"
        );
        require(
            walletMintCount[msg.sender] < maxWalletMintCount,
            "mintNormal: Over Max Wallet Mint Count"
        );
        require(
            msg.value == normalMintPrice * quantity,
            "mintNormal: ETH Value is incorrect"
        );
        require(
            (quantity + normalMintedCount) <= normalQuantity,
            "mintNormal: No More NFTs"
        );

        normalMintedCount += quantity;
        walletMintCount[msg.sender] += 1;
        _mint(msg.sender, quantity);
    }

    function mintGold() external payable nonReentrant {
        require(
            walletMintCount[msg.sender] < maxWalletMintCount,
            "mintGold: Over Max Wallet Mint Count"
        );
        require(msg.value == goldMintPrice, "mintGold: ETH Value is incorrect");
        require(
            (1 + goldMintedCount) <= goldQuantity,
            "mintGold: No More NFTs"
        );

        isGoldTokenId[_nextTokenId()] = true;
        goldMintedCount += 1;
        walletMintCount[msg.sender] += 1;
        _mint(msg.sender, 1);
    }

    //////////////////////////////////
    //            owner
    //////////////////////////////////

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function withdraw() external onlyOwner {
        uint withdrawValue = address(this).balance;
        (bool success, ) = payable(owner()).call{value: withdrawValue}("");
        require(success, "withdraw: Withdeaw Fail");
    }

    function setRestrict(address _newAddress, bool _bool) public onlyOwner {
        isRestrict[_newAddress] = _bool;
    }

    //////////////////////////////////
    //            override
    //////////////////////////////////
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (!isGoldTokenId[tokenId]) {
            return
                bytes(baseURI).length != 0
                    ? string(abi.encodePacked(baseURI, "normal"))
                    : "";
        } else {
            return
                bytes(baseURI).length != 0
                    ? string(abi.encodePacked(baseURI, "gold"))
                    : "";
        }
    }

    function isApprovedForAll(address nftOwner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        if (isRestrict[operator] == true) {
            return false;
        }
        return super.isApprovedForAll(nftOwner, operator);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(isRestrict[operator] == false, "Is Restrict");
        super.setApprovalForAll(operator, approved);
    }

    function approve(address to, uint256 tokenId)
        public
        payable
        virtual
        override
    {
        require(isRestrict[to] == false, "Is Restrict");
        super.approve(to, tokenId);
    }
}