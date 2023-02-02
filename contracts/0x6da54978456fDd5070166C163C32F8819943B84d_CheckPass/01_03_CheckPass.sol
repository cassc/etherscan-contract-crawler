// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721{
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
}

contract CheckPass is Ownable {

    address public CheckBirdsNft=0xc597A66d3c37dB76eB0bC08A5bD5908c2beBe489;
    address public CheckBirdsburn=0x0000000000000000000000000000000000000000;
    bool public BurnMintStatus;
    bool public RareBurnMintStatus;

    mapping(uint256 => bool) public rarecheckbirdslist;
    mapping(address => uint256) public burninfos;
    mapping(address => uint256) public rareburninfos;
    constructor() {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Must from real wallet address");
        _;
    }

    function burn(uint256[] memory tokenids) public payable callerIsUser{
        require(BurnMintStatus,"Error: Burn stage closed");
        require(tokenids.length == 3, "Error: Wrong quantity");
        require(burninfos[msg.sender] == 0, "Error: You have only have one chance");
        for (uint i = 0; i < tokenids.length; i++) {
            address owner = IERC721(CheckBirdsNft).ownerOf(tokenids[i]);
            require(msg.sender == owner, "Error: Not ERC721 owner");
            IERC721(CheckBirdsNft).safeTransferFrom(msg.sender,CheckBirdsburn,tokenids[i]);
        }
        burninfos[msg.sender] += 1;
    }

   function rareburn(uint256[] memory tokenids) public payable callerIsUser{
        require(RareBurnMintStatus,"Error: Burn stage closed");
        require(tokenids.length == 3, "Error: Wrong quantity");
        require(rareburninfos[msg.sender] == 0, "Error: You have only have one chance");
        for (uint i = 0; i < tokenids.length; i++) {
            require(rarecheckbirdslist[tokenids[i]],"Error: Not 1/1 Nft");
            address owner = IERC721(CheckBirdsNft).ownerOf(tokenids[i]);
            require(msg.sender == owner, "Error: Not ERC721 owner");
            IERC721(CheckBirdsNft).safeTransferFrom(msg.sender,CheckBirdsburn,tokenids[i]);
        }
        rareburninfos[msg.sender] += 1;
    }


    function setBurnStatus(bool status) external onlyOwner {
        BurnMintStatus = status;
    }

    function setRareBurnStatus(bool status) external onlyOwner {
        RareBurnMintStatus = status;
    }

    function setCheckBirdsNft(address checkbirdsnft) external onlyOwner {
        CheckBirdsNft = checkbirdsnft;
    }

    function setCheckBirdsBurn(address checkbirdsburn) external onlyOwner {
        CheckBirdsburn = checkbirdsburn;
    }

    function setRarecheckbirdslist(uint256[] memory tokenids, bool status) external onlyOwner {
        for (uint256 i; i < tokenids.length; ++i) {
            rarecheckbirdslist[tokenids[i]] = status;
        }
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}