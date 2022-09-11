// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract BAFCExclusiveNFT is ERC721, ERC721Enumerable, Ownable {
    using Strings for uint256;

    struct HolderDiscount {
        uint256 quantity;
        uint256 discount;
    }

    bool public revealed = true;
    bool public saleActive = false;
    string private _baseURIextended;
    string private _nonRevealedBaseURIextended;
    uint256 public MAX_SUPPLY = 30;
    uint256 public MAX_TX_MINT = 30;
    uint256 public MAX_WALLET_MINT = 30;
    uint256 public PRICE_PER_MINT = 10 ether;

    // Users could hold specific number of tokens in order to be eligibles for discounts
    IERC20 public token;
    HolderDiscount[] public holdDiscounts;
    bool public holdDiscountsEnabled = false;

    // Variables to set the next step for the increase of price for each NFT
    uint256 public nextPrice = PRICE_PER_MINT;
    uint256 public nextPriceIndex = 0;

    mapping (address => bool) blacklist;

    // Events
    event MintedNFT(address _buyer, uint256 numberOfNfts, uint256 _price);

    constructor() ERC721("BAFC Exclusive NFT", "BAFCExclusiveNFT") {
        
    }

    // Set the token to use holder discount feature
    function setToken(address _token) public onlyOwner {
        token = IERC20(_token);
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        MAX_SUPPLY = _maxSupply;
    }

    function setMaxTxMint(uint256 _maxTxMint) public onlyOwner {
        MAX_TX_MINT = _maxTxMint;
    }

    function setMaxWalletMint(uint256 _maxWalletMint) public onlyOwner {
        MAX_WALLET_MINT = _maxWalletMint;
    }

    function setHoldDiscountsEnabled(bool value) public onlyOwner {
        holdDiscountsEnabled = value;
    }

    function setBlacklist(address addr, bool blacklisted) public onlyOwner {
        blacklist[addr] = blacklisted;
    }

    function isBlacklisted(address addr) public view returns (bool) {
        return blacklist[addr];
    }

    function isRevealed(bool value) public onlyOwner {
        revealed = value;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function setNonRevealedBaseURI(string memory baseURI_) external onlyOwner() {
        _nonRevealedBaseURIextended = baseURI_;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        super.tokenURI(tokenId);
        
        string memory baseURI = _baseURI();

        if(!revealed) {
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(_nonRevealedBaseURIextended, "placeholder.json")) : "";
        }

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function reserve(uint256 n) public onlyOwner {
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < n; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function reserveFor(uint256 n, address _address) public onlyOwner {
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < n; i++) {
            _safeMint(_address, supply + i);
        }
    }

    function burn(uint256 tokenId) public onlyOwner {
        // Burn the NFT zero
        super._burn(tokenId);
    }

    function isSaleActive(bool active) public onlyOwner {
        saleActive = active;
    }

    function setPrice(uint256 pPublic) public onlyOwner {
        require(pPublic >= 0, "Prices should be higher or equal than zero.");
        PRICE_PER_MINT = pPublic;
    }

    function mint(uint numberOfTokens) public payable {
        uint256 ts = totalSupply();
        require(saleActive, "Sale must be active to mint tokens");
        require(numberOfTokens <= MAX_TX_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require((balanceOf(msg.sender) + numberOfTokens) <= MAX_WALLET_MINT, "You have exceeded the limit of nfts for your wallet");

        if(holdDiscountsEnabled) {
            require(getMintPriceByAddress(msg.sender) * numberOfTokens <= msg.value, "Ether value sent is not correct");
        } else {
            require(PRICE_PER_MINT * numberOfTokens <= msg.value, "Ether value sent is not correct");
        }

        require(!isBlacklisted(msg.sender), "The current address is blacklisted");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }

        if(nextPriceIndex > 0 && totalSupply() >= nextPriceIndex) {
            PRICE_PER_MINT = nextPrice;
        }

        emit MintedNFT(msg.sender, numberOfTokens, msg.value);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /*
    *   Holder discount feature
    */
    function addTokenDiscount(uint256 quantity, uint256 discount) public onlyOwner {
        holdDiscounts.push(HolderDiscount(quantity, discount));
    }

    function removeTokenDiscount(uint256 quantity) public onlyOwner {
        for(uint256 i=0; i < holdDiscounts.length; i++) {
            if(holdDiscounts[i].quantity == quantity) {
                delete holdDiscounts[i];
            }
        }
    }

    function getTokenBalance(address _address) public view returns (uint256) {
        uint256 balance = IERC20(token).balanceOf(_address);
        return balance;
    }
    
    function getEligibleDiscount(address _address) public view returns (uint256 discountPercentage) {
        uint256 discount = 0;
        uint256 balance = getTokenBalance(_address);

        if(holdDiscountsEnabled) {
            for(uint i=0; i < holdDiscounts.length; i++) {
                if(holdDiscounts[i].quantity <= balance && discount <= holdDiscounts[i].discount) {
                    discount = holdDiscounts[i].discount;
                }
            }
        }

        return discount;
    }

    function getMintPriceByAddress(address _address) public view returns (uint256 price) {
        uint256 discount = 0;
        if(holdDiscountsEnabled) {
            discount = getEligibleDiscount(_address);
            if(discount > 0) {
                return PRICE_PER_MINT - (discount * PRICE_PER_MINT / 100);
            }
        }

        return PRICE_PER_MINT;
    }

    function getHoldDiscounts() public view returns (HolderDiscount[] memory) {
        return holdDiscounts;
    }

    /*
    *   Let next price be dinamically based on the index.
    *   Owner can set the price for NFT's once last minted ID reaches _nextPriceIndex
    */
    function setNextPrice(uint256 _nextPriceIndex, uint256 _nextPrice) public onlyOwner {
        nextPriceIndex = _nextPriceIndex;
        nextPrice = _nextPrice;
    }
}