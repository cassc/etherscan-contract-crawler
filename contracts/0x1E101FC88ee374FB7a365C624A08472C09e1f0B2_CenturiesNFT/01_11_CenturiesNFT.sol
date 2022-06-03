// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract CenturiesNFT is ERC721, Ownable {
    uint256 public mintPrice;
    uint256 public totalSupply;
    uint256 public maxSupply;
    uint256 public maxPerWallet;
    bool public isPublicMintEnabled;
    string internal baseTokenURI;
    address payable public withdrawWallet;
    mapping(address => uint256) public walletMints;


    constructor() payable ERC721('Centuries NFT', 'CET'){
        mintPrice = 0.0777 ether;
        totalSupply = 0;
        maxSupply = 250;
        maxPerWallet = 10;

        // Set withdraw address
        withdrawWallet = payable(0xA0125FDcb3e65A2cEaDF459B8d4454167eC51D7E);
    }

    function setIsPublicMintEnabled(bool isPublicMintEnabled_) external onlyOwner {
        isPublicMintEnabled = isPublicMintEnabled_;
    }

    function setBaseTokenURI (string calldata baseTokenURI_) external onlyOwner {
        baseTokenURI = baseTokenURI_;
    }

    function tokenURI (uint tokenId_) public view override returns (string memory) {
        require(_exists(tokenId_), 'Token does not exist.');
        return string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId_), ".json"));
    }

    function withdraw() external onlyOwner{
        (bool success, ) = withdrawWallet.call{ value: address(this).balance }('');
        require(success, "Withdraw failed!");
    }

    function mint(uint256 quantity_) public payable {
        require(isPublicMintEnabled, "Minting not enabled.");
        require(msg.value == quantity_ * mintPrice, "Wrong mint value");
        require(totalSupply + quantity_ <= maxSupply, "Sold out!");
        require(walletMints[msg.sender] + quantity_ <= maxPerWallet, "Reached max mint!");

        for (uint256 i = 0; i < quantity_; i++) {
            uint256 newTokenId = totalSupply + 1;
            totalSupply++;
            _safeMint(msg.sender, newTokenId);
        }

    }

}