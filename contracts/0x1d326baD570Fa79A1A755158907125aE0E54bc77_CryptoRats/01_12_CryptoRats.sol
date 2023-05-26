// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// dev is @elbrupt on telegram

contract CryptoRats is ERC721, Ownable {
    using Strings for uint256;

    address private memberOne = 0x847dcb02Cb3Ee2A292b8b3440d2E5A9363EB1201;
    address private memberTwo = 0xBf4d452Be8b6c0Bf38525292A59e156CC60A7B22;
    address private memberThree = 0xA9568E6803567aaC4b3C8595a74D5d7Cd383dceD;
    address private memberFour = 0xCae9565Ba534CC6a3Eb1D1CbbB868A36DF2A4D19;

    uint256 public NFT_MAX = 1500;
    uint256 public NFT_PRICE = 0.06 ether;
    uint256 public constant NFTS_PER_MINT = 8;
    string private _contractURI;
    string private _tokenBaseURI;
    string public _mysteryURI;

    bool public revealed;
    bool public saleLive;
    bool public giftLive = true;

    uint256 public totalSupply;

    constructor() ERC721("CryptoRats", "RATS") {}

    function mintGiftAsOwner(uint256 tokenQuantity, address wallet)
        external
        onlyOwner
    {
        require(giftLive, "GIFTING_CLOSED");
        require(totalSupply < NFT_MAX, "OUT_OF_STOCK");
        require(totalSupply + tokenQuantity <= NFT_MAX, "EXCEED_STOCK");

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(wallet, totalSupply + i + 1);
        }

        totalSupply += tokenQuantity;
    }

    function mint(uint256 tokenQuantity) external payable {
        require(saleLive, "SALE_CLOSED");
        require(totalSupply < NFT_MAX, "OUT_OF_STOCK");
        require(totalSupply + tokenQuantity <= NFT_MAX, "EXCEED_STOCK");
        require(NFT_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");
        require(tokenQuantity <= NFTS_PER_MINT, "EXCEED_NFTS_PER_MINT");

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(msg.sender, totalSupply + i + 1);
        }

        totalSupply += tokenQuantity;
    }

    function withdraw() external {
        uint256 currentBalance = address(this).balance;
        payable(memberOne).transfer((currentBalance * 6) / 100);
        payable(memberTwo).transfer((currentBalance * 4) / 100);
        payable(memberThree).transfer((currentBalance * 2) / 100);
        payable(memberFour).transfer((currentBalance * 88) / 100);
    }

    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }

    function toggleSaleGiftStatus() external onlyOwner {
        giftLive = !giftLive;
    }

    function toggleMysteryURI() public onlyOwner {
        revealed = !revealed;
    }

    function setMysteryURI(string calldata URI) public onlyOwner {
        _mysteryURI = URI;
    }

    function setPriceOfNFT(uint256 price) external onlyOwner {
        // 70000000000000000 = .07 eth
        NFT_PRICE = price;
    }

    function setNFTMax(uint256 max) external onlyOwner {
        NFT_MAX = max;
    }

    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Cannot query non-existent token");

        if (revealed == false) {
            return _mysteryURI;
        }

        return
            string(
                abi.encodePacked(_tokenBaseURI, tokenId.toString(), ".json")
            );
    }
}