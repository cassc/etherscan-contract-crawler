// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";



contract NFTMarketplace is ERC1155URIStorage, Ownable, EIP712, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIds;

    string private constant SIGNING_DOMAIN = "Voucher-Domain";
    string private constant SIGNATURE_VERSION = "1";
    address public minter;
    address public ETHdepot = 0x858e1904315d1Cb4c39d54514Db968B87610a04a;

    struct LazyNFTVoucher {
        uint256 tokenId;
        uint256 price;
        string uri;
        address buyer;
        bytes signature;
    }

    constructor(address _minter) ERC1155("") EIP712 (SIGNING_DOMAIN, SIGNATURE_VERSION) {
                minter = _minter;
    }

    /* Updates the listing price of the contract */


    //* @desc function for getting royalty info for a collection
    //* @param salePrice - sale price of the nft needs to be passed in so function can return the correct royalty fee
    function getRoyaltyInfo(
        address nftContract,
        uint256 tokenId,
        uint256 salePrice
    ) public view returns (address, uint256) {
        return IERC2981(nftContract).royaltyInfo(tokenId, salePrice);
    }


    function calculateFee(uint256 _num) public view returns (uint256){
        uint256 onePercentofTokens = _num.mul(100).div(100 * 10 ** uint256(2));
        uint256 twoPercentOfTokens = onePercentofTokens.mul(2);
        uint256 halfPercentOfTokens = onePercentofTokens.div(2);
        return twoPercentOfTokens + halfPercentOfTokens;
    }

    function recover(LazyNFTVoucher calldata voucher) public view returns (address) {
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("LazyNFTVoucher(uint256 tokenId,uint256 price,string uri,address buyer)"),
            voucher.tokenId,
            voucher.price,
            keccak256(bytes(voucher.uri)),
            voucher.buyer
        )));
        address signer = ECDSA.recover(digest, voucher.signature);
        return signer;
    }

    function getCurrentTokenId () public view returns (uint256) {
       return  _tokenIds.current();
    } 
    
    function ChangeETHdepot (address _ETHdepot) onlyOwner public {
       ETHdepot = _ETHdepot;
    }

    function createToken(LazyNFTVoucher calldata voucher, uint256 supply, address sellerAddress) public payable nonReentrant returns (uint256) {
        uint256 extractFee = this.calculateFee(voucher.price);
        require(minter == recover(voucher), "Wrong signature.");
        require(msg.value >= voucher.price + extractFee, "Not enough ether sent.");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        payable(sellerAddress).transfer(voucher.price);
        payable(ETHdepot).transfer(extractFee);

        _mint(msg.sender, newTokenId, supply, "");
        _setURI(newTokenId, voucher.uri);
        return newTokenId;
    }

    function createMarketSale1155(LazyNFTVoucher calldata voucher, address sellerAddress, uint256 supply) public payable nonReentrant {
        uint256 price = voucher.price;
        uint256 extractFee = this.calculateFee(price);
        require(minter == recover(voucher), "Wrong signature.");
        require(msg.value >= price + extractFee, "Not enough ETH sent");

        safeTransferFrom(sellerAddress, voucher.buyer, voucher.tokenId, supply, "");

        payable(ETHdepot).transfer(extractFee);

        payable(sellerAddress).transfer(price);
    }
 
   function createMarketSale721(LazyNFTVoucher calldata voucher, address listerAddress, address _nftContract) public payable nonReentrant {
 
      uint256 extractFee = this.calculateFee(voucher.price);
      require(minter == recover(voucher), "Wrong signature.");
      require(msg.value >= voucher.price + extractFee, "Not enough ETH sent");
 
       (address artist, uint256 royaltyFee) = getRoyaltyInfo(
          _nftContract,
          voucher.tokenId,
          voucher.price
      );
  
       IERC721(_nftContract).safeTransferFrom(listerAddress, voucher.buyer, voucher.tokenId, "");
 
       if(royaltyFee > 0){
          payable(ETHdepot).transfer(extractFee);
          payable(listerAddress).transfer(voucher.price-royaltyFee);
          payable(artist).transfer(royaltyFee);
      }else{
          payable(ETHdepot).transfer(extractFee);
          payable(listerAddress).transfer(voucher.price);
     }
    }
   }