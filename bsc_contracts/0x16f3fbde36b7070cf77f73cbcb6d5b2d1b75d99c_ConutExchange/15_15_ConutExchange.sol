// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ConutExchange is Ownable, ReentrancyGuard {
    enum CirculatingToken { BNB, BUSD, CONUT }

    struct NftPrice {
        uint256 price;
        CirculatingToken token;
    }

    event SellToken ( uint256 indexed tokenId, uint256 indexed price, CirculatingToken indexed token );
    event BuyToken ( uint256 indexed tokenId, uint256 indexed price, CirculatingToken indexed token );

    // Mapping from NFT ID to NFT price
    mapping (uint256 => NftPrice) public nftSellPrices; 

    ERC721 public nftAddress;
    IERC20 public busdAddress;
    IERC20 public conutAddress;
    //address  public main_address = 0xb399430F54B25AC33b5E90f23fb7Bb5e9A6c3eCa;



    constructor (address _nftAddress, address _busdAddress, address _conutAddress) {
        require(_nftAddress != address(0), "ConutExchange: nftAddress is the zero address");
        require(_busdAddress != address(0), "ConutExchange: busdAddress is the zero address");

        nftAddress = ERC721(_nftAddress);
        busdAddress = ERC20(_busdAddress);
        conutAddress = ERC20(_conutAddress);
    }

    function sellToken(uint256 tokenId, NftPrice memory nftPrice) public {
        require(msg.sender != address(0) && msg.sender != address(this), "ConutExchange: sender is the zero address");
        require(nftAddress.ownerOf(tokenId) == msg.sender, "ConutExchange: sender is not owner ");
        require(nftPrice.price > 0, "ConutExchange: NFT price must than ZERO");

        NftPrice memory nftPriceExisted = nftSellPrices[tokenId];
        require(nftPriceExisted.price == 0, "ConutExchange: NFT is selling");

        nftSellPrices[tokenId] = nftPrice;

        emit SellToken(tokenId, nftPrice.price, nftPrice.token);
    }

    function buyToken(uint256 tokenId) payable public nonReentrant {
        require(msg.sender != address(0) && msg.sender != address(this), "ConutExchange: sender is the zero address");

        NftPrice memory nftPrice = nftSellPrices[tokenId];
        require(nftPrice.price > 0, "ContExchange: NFT not for sell");

        address addressSeller = nftAddress.ownerOf(tokenId);

        if (nftPrice.token == CirculatingToken.BUSD) {
            require(busdAddress.balanceOf(msg.sender) >= nftPrice.price, "ConutExchange: BUSD amount is less than price");
            busdAddress.transferFrom(msg.sender, addressSeller, nftPrice.price);
           // busdAddress.transferFrom(msg.sender, payable(main_address), nftPrice.price*25/1000);
        } else if (nftPrice.token == CirculatingToken.CONUT) {
            require(conutAddress.balanceOf(msg.sender) >= nftPrice.price, "ConutExchange: CONT amount is less than price");
            conutAddress.transferFrom(msg.sender, addressSeller, nftPrice.price);
           // contAddress.transferFrom(msg.sender, payable(main_address), nftPrice.price*25/1000);
        } else if (nftPrice.token == CirculatingToken.BNB) {
            require(msg.value >= nftPrice.price, "ConutExchange: BNB amount is less than price");
            payable(addressSeller).transfer(msg.value);
           // payable(main_address).transfer(msg.value*25/1000);
        } else {
            require(false, "ConutExchange: token is not support");
        }

        nftAddress.safeTransferFrom(addressSeller, msg.sender, tokenId);
        delete nftSellPrices[tokenId];

        emit BuyToken(tokenId, nftPrice.price, nftPrice.token);
    }
}