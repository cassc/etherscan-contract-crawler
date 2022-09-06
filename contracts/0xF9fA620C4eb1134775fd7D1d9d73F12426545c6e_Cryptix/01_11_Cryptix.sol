// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Cryptix is ERC721, Ownable {
    using Strings for uint256;

    address private whitelistedWallet = 0x58bb8A6Db0256E584ba28851a970d811EdD8AC80;
    uint256 public constant NFT_STOCK = 10000;
    uint256 public constant NFTS_PER_WALLET = 4;
    uint256 public NFT_PRICE = 0.04 ether;

    string private _tokenBaseURI;

    bool public giftLive = true;
    bool public saleLive = false;

    mapping(address => uint256) public addressMinted;

    uint256 public totalSupply;

    constructor(string memory tokenBaseURI) ERC721("Cryptix", "CRYPTIX") {
        _tokenBaseURI = tokenBaseURI;
    }

    function mintGift(uint256 tokenQuantity, address wallet)
        external
        onlyOwner
    {
        require(giftLive, "GIFTING CLOSED");
        require(tokenQuantity > 0, "INVALID TOKEN QUANTITY");
        require(totalSupply <= NFT_STOCK, "OUT OF STOCK");
        require(totalSupply + tokenQuantity <= NFT_STOCK, "EXCEEDS STOCK");

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(wallet, totalSupply + i + 1);
        }

        totalSupply += tokenQuantity;
    }

    function mint(
        uint256 tokenQuantity
    ) external payable {
        require(saleLive, "SALE IS NOT LIVE");
        require(totalSupply <= NFT_STOCK, "OUT OF STOCK");
        require(tokenQuantity > 0, "INVALID TOKEN QUANTITY");
        if (msg.sender != whitelistedWallet) {
            if (addressMinted[msg.sender] > 0) {
                require(addressMinted[msg.sender] + tokenQuantity <= NFTS_PER_WALLET, "EXCEEDS YOUR 4 CRYPTIX MAX");
                require(NFT_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");
            } else { // One free mint
                require(addressMinted[msg.sender] + tokenQuantity <= NFTS_PER_WALLET, "EXCEEDS YOUR 4 CRYPTIX MAX");
                require(NFT_PRICE * (tokenQuantity - 1) <= msg.value, "INSUFFICIENT_ETH");
            }
        }
        require(totalSupply + tokenQuantity <= NFT_STOCK, "EXCEEDS STOCK");
        
        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(msg.sender, totalSupply + i + 1);
        }

        addressMinted[msg.sender] += tokenQuantity;
        totalSupply += tokenQuantity;
    }

    function withdraw() external onlyOwner {
        uint256 currentBalance = address(this).balance;
        payable(whitelistedWallet).transfer((currentBalance * 1000) / 1000);
    }

    function toggleSaleStatus() public onlyOwner {
        saleLive = !saleLive;
    }

    function toggleGiftStatus() public onlyOwner {
        giftLive = !giftLive;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function setNFTPrice(uint256 p) external onlyOwner {
        NFT_PRICE = p;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Cannot query non-existent token");
        return
            string(
                abi.encodePacked(_tokenBaseURI, tokenId.toString(), ".json")
            );
    }
}