// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract FractionalNFT is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    struct FNFTDetails {
        uint256 tokenId;
        address fractionalToken;
    }

    struct SaleDetails {
        uint256 tokenId;
        uint256 tokensToSale;
        uint256 salePrice;
        bool isActive;
    }

    event CreateSale(address NFTOwner, uint256 tokenId, uint256 tokensToSale, uint256 salePrice, uint256 time);
    event CancelSale(address NFTOwner, uint256 tokenId, uint256 time);
    event Purchase(address user, uint256 tokenId, uint256 tokensPurchased, uint256 time);


    mapping(uint256 => SaleDetails) private saleTokens;

    mapping(uint256 => FNFTDetails) private fractionalNFTs;


    constructor() ERC721("MESS", "MESS") {}


    function getFNFTDetails(uint256 tokenId) public view returns (FNFTDetails memory) {
        return (fractionalNFTs[tokenId]);
    }

    function getSaleDetails(uint256 tokenId) public view returns (SaleDetails memory) {
        return saleTokens[tokenId];         
    }

    function cancelSale(uint256 tokenId) public whenNotPaused {
        require(fractionalNFTs[tokenId].fractionalToken != address(0), "NFT Does not exist");

        require(msg.sender == checkNFTOwner(tokenId), "Not the owner of the NFT");
        require(saleTokens[tokenId].isActive, "NFT Sale is allready Closed");

        FNFToken fnfToken = FNFToken(fractionalNFTs[tokenId].fractionalToken);
        fnfToken.transfer(msg.sender, (saleTokens[tokenId].tokensToSale * 1 ether));

        emit CancelSale(msg.sender, tokenId, block.timestamp);

        saleTokens[tokenId].tokensToSale = 0;
        saleTokens[tokenId].isActive = false;

    }

    function createSales(uint256 tokenId, uint256 tokensToSale, uint256 salePrice) public whenNotPaused {
        require(fractionalNFTs[tokenId].fractionalToken != address(0), "NFT Does not exist");
        require(msg.sender == ownerOf(tokenId), "Not the owner of the NFT");
        require(!saleTokens[tokenId].isActive, "Allready Sale Created for the NFT");
        
        require(tokensToSale > 0, "Invalid Tokens to sale");
        require(salePrice > 0, "Invalid Sale Price");

        FNFToken fnfToken = FNFToken(fractionalNFTs[tokenId].fractionalToken);
        require(fnfToken.balanceOf(msg.sender) >= (tokensToSale * 1 ether), "Insufficient FNFToken Balance");
        require(fnfToken.allowance(msg.sender, address(this)) >= (tokensToSale * 1 ether), "Tokens are Not Approved");

        fnfToken.transferFrom(msg.sender, address(this), tokensToSale * 1 ether);

        SaleDetails memory newSale = SaleDetails({
            tokenId: tokenId,
            tokensToSale: tokensToSale,
            salePrice: salePrice,
            isActive: true
        });

        saleTokens[tokenId] = newSale;
        emit CreateSale(msg.sender, tokenId, tokensToSale, salePrice, block.timestamp);
    }

    function purchase(uint256 tokenId, uint256 tokensToPurchase) public payable whenNotPaused {
        require(fractionalNFTs[tokenId].fractionalToken != address(0), "NFT Does not exist");
        require(saleTokens[tokenId].isActive, "NFT Sale is Closed");
        require(saleTokens[tokenId].salePrice * tokensToPurchase <= msg.value, "Insufficient amount sent");

        if (saleTokens[tokenId].tokensToSale < tokensToPurchase) {
            tokensToPurchase = saleTokens[tokenId].tokensToSale;
        }

        uint256 totalPrice = saleTokens[tokenId].salePrice * tokensToPurchase;
        uint256 remainingValue = msg.value - totalPrice;

        FNFToken fnfToken = FNFToken(fractionalNFTs[tokenId].fractionalToken);
        fnfToken.transfer(msg.sender, (tokensToPurchase * 1 ether));

        payable(checkNFTOwner(tokenId)).transfer(totalPrice);

        if (remainingValue > 0) {
            payable(msg.sender).transfer(remainingValue);
        }

        saleTokens[tokenId].tokensToSale -= tokensToPurchase;

        if (saleTokens[tokenId].tokensToSale == 0) {
            saleTokens[tokenId].isActive = false;
        }

        emit Purchase(msg.sender, tokenId, tokensToPurchase, block.timestamp);

    }
    

    function safeMint(address to) internal onlyOwner {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _baseURI() internal pure override returns (string memory) {
        return "";
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchId) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function checkNFTOwner(uint256 tokenId) public view returns (address) {
        require(fractionalNFTs[tokenId].fractionalToken != address(0), "NFT Does not exist");
        return (ownerOf(tokenId));
    }

    function mint(address _to, string memory tokenURI_, uint256 _totalFractionalTokens) external onlyOwner {
        _safeMint(_to, _tokenIdCounter.current());
        _setTokenURI(_tokenIdCounter.current(), tokenURI_);

        FNFToken fnfToken = (new FNFToken)();
        fnfToken.mint(_to, _totalFractionalTokens * 1 ether);

        FNFTDetails memory fnft; 
        fnft.tokenId = _tokenIdCounter.current();
        fnft.fractionalToken = address(fnfToken);
        fractionalNFTs[_tokenIdCounter.current()] = fnft;

        _tokenIdCounter.increment();
    }
}

contract FNFToken is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("MESS", "MESS") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
 