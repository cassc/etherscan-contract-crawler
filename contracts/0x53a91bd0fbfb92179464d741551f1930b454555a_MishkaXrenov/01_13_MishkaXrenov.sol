// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {ERC721, Strings} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// import "hardhat/console.sol";

contract MishkaXrenov is ERC721, Ownable {
    using Strings for uint256;

    address payable public possessor;

    uint256 public reserve;
    uint256 public uniqueAmount;
    uint256 public repetitiveAmount;
    uint256 public supply;
    uint256 public price;

    string public baseURI;

    mapping(address => mapping(uint256 => bool)) private claimedCounter;
    mapping(uint256 => uint256) private typeCounter;

    constructor(
        address payable possessor_,
        uint256 reserve_,
        uint256 uniqueAmount_,
        uint256 repetitiveAmount_,
        uint256 supply_,
        uint256 price_,
        string memory baseURI_
    ) ERC721("MishkaXrenov", "MX") {
        possessor = possessor_;
        reserve = reserve_;
        uniqueAmount = uniqueAmount_;
        repetitiveAmount = repetitiveAmount_;
        supply = supply_;
        price = price_;
        baseURI = baseURI_;
    }


    function mint(uint256[] calldata nftTypes) payable external {

        if (msg.sender == possessor) batchMintForPossessor(nftTypes);
        else {
            require(msg.value >= price * nftTypes.length, "Not enough eth for mint");
            possessor.transfer(msg.value);
            batchMint(nftTypes);
        }

    }

    function batchMintForPossessor(uint256[] calldata types) internal {
        for (uint256 i = 0; i < types.length;) {
            require(types[i] <= uniqueAmount, "Wrong calldata: nft type should be lower");
            require(types[i] > 0, "Wrong calldata: nft type should be greater than zero");
            require(!claimedCounter[msg.sender][types[i]], "This NFT already minted");
            claimedCounter[msg.sender][types[i]] = true;
            _mint(msg.sender, types[i] - 1);
        unchecked { i++; }
        }
    }

    function batchMint(uint256[] calldata types) internal {
        for (uint256 i = 0; i < types.length;) {
            require(typeCounter[types[i]] < repetitiveAmount - 1, "This nft type is sold");
            require(types[i] <= uniqueAmount, "Wrong calldata: nft type should be lower");
            require(types[i] > 0, "Wrong calldata: nft type should be greater than zero");
            require(!claimedCounter[msg.sender][types[i]], "This NFT already minted");

            claimedCounter[msg.sender][types[i]] = true;
            _mint(msg.sender, getNftTypeId(types[i]));
            typeCounter[types[i]]++;
        unchecked { i++; }
        }
    }

    function getNftTypeId(uint256 nftType) public view returns(uint256) {
        return nftType - 1 + (typeCounter[nftType] + 1) * uniqueAmount; 
    } 

    function calculateAvailableNFTs() public view returns(uint256[] memory availableAmounts) {
        availableAmounts = new uint256[](uniqueAmount);
        for (uint256 i = 0; i < uniqueAmount;){
            availableAmounts[i] = repetitiveAmount - typeCounter[i + 1] - 1;
        unchecked { i++; }
        }
    }

    function calculateAvailableNFTsForUser(address user) public view returns(uint256[] memory availableAmounts) {
        availableAmounts = new uint256[](uniqueAmount);
        for (uint256 i = 0; i < uniqueAmount;){
            claimedCounter[user][i + 1] ? availableAmounts[i] = 0 : availableAmounts[i] = 1;
        unchecked { i++; }
        }
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return
            bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, (((tokenId) % 36) + 1).toString(), ".json")) : "";
    }

    function setPossessor(address payable _possessor) public onlyOwner {
        possessor = _possessor;
    }
}