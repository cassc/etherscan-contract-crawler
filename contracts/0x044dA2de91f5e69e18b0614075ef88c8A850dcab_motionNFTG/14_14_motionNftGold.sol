// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract motionNFTG is ERC721, Ownable, ReentrancyGuard {
    string internal baseTokenUri;
    uint256 public Price;
    uint256 public totalSupply;
    uint256 public maxSupply;
    uint256 public maxPerWallet;
    bool public isPublicMintEnabled;
    address payable public withdrawWallet;
    mapping(address => uint256) public walletMints;

    constructor() payable ERC721("MOTION NFT", "MGOLD") ReentrancyGuard() {
        Price = 0.3 ether;
        totalSupply = 0;
        maxSupply = 500;
        maxPerWallet = 5;
    }

    function setIsPublicMintEnabled(
        bool isPublicMintEnabled_
    ) external onlyOwner {
        isPublicMintEnabled = isPublicMintEnabled_;
    }

    function setBaseTokenUri(string calldata baseTokenUri_) external onlyOwner {
        baseTokenUri = baseTokenUri_;
    }

    modifier onlyAccounts() {
        require(msg.sender == tx.origin, "Not allowed origin");
        _;
    }

    function setPrice(uint256 _price) external onlyOwner {
        Price = _price;
    }

    function setTotalSupply(uint256 _totalSupply) external onlyOwner {
        totalSupply = _totalSupply;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxMintPerWallet(uint256 _qty) external onlyOwner {
        maxPerWallet = _qty;
    }

    function tokenURI(
        uint256 tokenId_
    ) public view virtual override returns (string memory) {
        require(_exists(tokenId_), "Token does not exist");
        return
            bytes(baseTokenUri).length > 0
                ? string(
                    abi.encodePacked(
                        baseTokenUri,
                        Strings.toString(tokenId_),
                        ".json"
                    )
                )
                : "";
    }

    function withdrawAll() external payable onlyOwner {
        uint256 balance = address(this).balance;
        uint256 balanceOne = (balance * 100) / 100;
        (bool transferOne, ) = payable(
            0x167d4191fD9bb41A15347f49717c3B068FE45E77
        ).call{value: balanceOne}("");
        require(transferOne, "Transfer failed.");
    }

    function mint(uint256 _qty) public payable onlyAccounts {
        require(isPublicMintEnabled, "Minting not enabled");
        require(msg.value == Price * _qty, "Wrong mint value");
        require(totalSupply + _qty <= maxSupply, "All NFTS sold out");
        require(
            walletMints[msg.sender] + _qty <= maxPerWallet,
            "exceed per wallet limit"
        );

        for (uint256 i = 0; i < 1; i++) {
            uint256 newTokenId = totalSupply + 1;
            totalSupply++;
            _safeMint(msg.sender, newTokenId);
        }
    }
}