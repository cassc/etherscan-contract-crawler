// SPDX-License-Identifier: MIT
// Creator: twitter.com/runo_dev

/* 
8888888b.          888               888               d8b               8888888b.  d8b                            d8b                   
888   Y88b         888               888               Y8P               888  "Y88b Y8P                            Y8P                   
888    888         888               888                                 888    888                                                      
888   d88P .d88b.  88888b.   .d88b.  888 .d8888b       888 88888b.       888    888 888 .d8888b   .d88b.  888  888 888 .d8888b   .d88b.  
8888888P" d8P  Y8b 888 "88b d8P  Y8b 888 88K           888 888 "88b      888    888 888 88K      d88P"88b 888  888 888 88K      d8P  Y8b 
888 T88b  88888888 888  888 88888888 888 "Y8888b.      888 888  888      888    888 888 "Y8888b. 888  888 888  888 888 "Y8888b. 88888888 
888  T88b Y8b.     888 d88P Y8b.     888      X88      888 888  888      888  .d88P 888      X88 Y88b 888 Y88b 888 888      X88 Y8b.     
888   T88b "Y8888  88888P"   "Y8888  888  88888P'      888 888  888      8888888P"  888  88888P'  "Y88888  "Y88888 888  88888P'  "Y8888  
                                                                                                      888                                
                                                                                                 Y8b d88P                                
                                                                                                  "Y88P"                                 
*/

// Rebels in Disguise - ERC-721 based NFT contract

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

error FunctionLocked();
error SaleNotStarted();
error InsufficientPayment();
error AmountExceedsSupply();
error InvalidQuantity();
error AmountExceedsTransactionLimit();
error RequestedSupplyShouldExceedsCurrentSupply();
error RequestedSupplyShouldNotExceedsCurrentMaxSupply();
error OnlyExternallyOwnedAccountsAllowed();
error OnlyExternallyCoinContractAllowed();
error AddressCanNotBeZeroAddress();

interface RebelsInDisguiseOld {
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
    function tokensOfOwner(address account) external view returns (uint256[] memory);
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface RebelsInDisguiseCoin {
    function totalSupply() external view returns (uint256);
}

contract RebelsInDisguise is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    uint256 public MAX_SUPPLY = 5555;
    uint256 private constant MAX_MINTS_PER_TX = 10;

    address private _creator1 = 0xd228c59148a3428B845b572d88E7ec77839cf474;
    address private _creator2 = 0xdBdFdB5a3c50BE2481cC021828b6815B46d2f2f8;
    address private _creator3 = 0x13205830f2bf6f1197D057f145454CE99A955A6d;
    address private _creator4 = 0xE2BFf72848B50e2385E63c23681695e990eC42cb;
    address private _creator5 = 0x3F838Fb407b750655632088bDf1D0430F53AC8F3;
    address private _creator6 = 0xCdC82eE2cbC9168e7DA4CD3EeF49705C5610839b;
    address private _creator7 = 0x35364A2B2c2DC73bEdF16e7fBCd29D2dA27E04D4;
    address private _creator8 = 0xDf82600D2fA71B2Cb9406EEF582114b395729d23;
    address private _creator9 = 0x9D35BaDbC2300003B5CF077262e7Ef389a89e981;
    bool private _lock = false;
    bool private _saleStatus = false;
    uint256 private _salePrice = 0.055 ether;
    string private _baseUri = "http://api.rebelsindisguise.co/rebels/";

    Counters.Counter private _reedemCounter;
    Counters.Counter private _tokenIdCounter;
    RebelsInDisguiseOld private _ridOldContract;
    RebelsInDisguiseCoin private _ridCoinContract;

    constructor(address ridCoinAddress, address ridOldAddress) ERC721("RebelsInDisguise", "RBLS") {
        _ridCoinContract = RebelsInDisguiseCoin(ridCoinAddress);
        _ridOldContract = RebelsInDisguiseOld(ridOldAddress);
    }

    //views
    function isSaleActive() public view returns (bool) {
        return _saleStatus;
    }

    function getPrice() public view returns (uint256) {
        return _salePrice;
    }

    function getRidOldContractAddress() public view returns (address) {
        return address(_ridOldContract);
    }

    function getRidCoinContractAddress() public view returns (address) {
        return address(_ridCoinContract);
    }

    function getReedemableSupply() public view returns (uint256) {
        return _ridCoinContract.totalSupply() - _ridOldContract.totalSupply() - _reedemCounter.current();
    }

    function mintTransfer(address account, uint256 quantity) external onlyECC {
        if (quantity == 0) revert InvalidQuantity();
        if (quantity > getReedemableSupply()) revert AmountExceedsSupply();
        for (uint256 index = 0; index < quantity; index++) {
            _tokenIdCounter.increment();
            _reedemCounter.increment();
            _safeMint(account, totalSupply());
        }
    }

    function publicMint(uint256 quantity) external payable nonReentrant onlyEOA {
        if (_lock) revert FunctionLocked();
        if (quantity == 0) revert InvalidQuantity();
        if (!isSaleActive()) revert SaleNotStarted();
        if (totalSupply() + quantity > MAX_SUPPLY - getReedemableSupply())
            revert AmountExceedsSupply();
        if (getPrice() * quantity > msg.value) revert InsufficientPayment();
        if (quantity > MAX_MINTS_PER_TX) revert AmountExceedsTransactionLimit();

        for (uint256 index = 0; index < quantity; index++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, totalSupply());
        }
    }

    function tokensOfAccount(address account) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(account);
        if (tokenCount == 0) return new uint256[](0);
        else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(account, index);
            }
            return result;
        }
    }

    // owner fns
    function setRIDOldContract(address newAddress) external onlyOwner {
        if (_lock) revert FunctionLocked();
        if (newAddress == address(0)) revert AddressCanNotBeZeroAddress();
        _ridOldContract = RebelsInDisguiseOld(newAddress);
    }

    function setRIDCoinAddr(address newAddress) external onlyOwner {
        if (_lock) revert FunctionLocked();
        if (newAddress == address(0)) revert AddressCanNotBeZeroAddress();
        _ridCoinContract = RebelsInDisguiseCoin(newAddress);
    }

    function ownerMint(uint256 quantity) external onlyOwner {
        if (_lock) revert FunctionLocked();
        if (quantity == 0) revert InvalidQuantity();
        if (totalSupply() + quantity > MAX_SUPPLY - getReedemableSupply()) revert AmountExceedsSupply();

        for (uint256 index = 0; index < quantity; index++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, totalSupply());
        }
    }

    function toggleSaleStatus() external onlyOwner {
        _saleStatus = !_saleStatus;
    }

    function setBaseUri(string memory newUri) external onlyOwner {
        if (_lock) revert FunctionLocked();
        _baseUri = newUri;
    }

    function lock() external onlyOwner {
        _lock = true;
    }

    function setMaxSupply(uint256 supply) external onlyOwner {
        if (_lock) revert FunctionLocked();
        if (MAX_SUPPLY <= supply) revert RequestedSupplyShouldNotExceedsCurrentMaxSupply();
        if (totalSupply() + getReedemableSupply() > supply) revert RequestedSupplyShouldExceedsCurrentSupply();
        MAX_SUPPLY = supply;
    }

    function withdrawAll() external onlyOwner {
        uint256 amountToCreator1 = (address(this).balance * 150) / 1000; // 15%
        uint256 amountToCreator2 = (address(this).balance * 125) / 1000; // 12.5%
        uint256 amountToCreator4 = (address(this).balance * 50) / 1000; // 5%
        uint256 amountToCreator5 = (address(this).balance * 125) / 1000; // 12.5%
        uint256 amountToCreator6 = (address(this).balance * 125) / 1000; // 12.5%
        uint256 amountToCreator7 = (address(this).balance * 125) / 1000; // 12.5%
        uint256 amountToCreator8 = (address(this).balance * 125) / 1000; // 12.5%
        uint256 amountToCreator9 = (address(this).balance * 125) / 1000; // 12.5%

        withdraw(_creator1, amountToCreator1);
        withdraw(_creator2, amountToCreator2);
        withdraw(_creator4, amountToCreator4);
        withdraw(_creator5, amountToCreator5);
        withdraw(_creator6, amountToCreator6);
        withdraw(_creator7, amountToCreator7);
        withdraw(_creator8, amountToCreator8);
        withdraw(_creator9, amountToCreator9);

        uint256 amountToCreator3 = address(this).balance; // ~5%
        withdraw(_creator3, amountToCreator3);
    }

    // internals
    function withdraw(address account, uint256 amount) internal {
        (bool os, ) = payable(account).call{value: amount}("");
        require(os, "Failed to send ether");
    }

    // overrides
    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function totalSupply() public view override returns (uint256) {
        return _ridOldContract.totalSupply() + _tokenIdCounter.current();
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        if (_ridOldContract.totalSupply() >= tokenId) {
            return _ridOldContract.tokenURI(tokenId);
        }
        return super.tokenURI(tokenId);
    }

    function balanceOf(address owner) public view override(ERC721) returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return super.balanceOf(owner) + _ridOldContract.balanceOf(owner);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        uint256 balanceForOld = _ridOldContract.balanceOf(owner);
        if (balanceForOld > 0 && index < balanceForOld) {
            return _ridOldContract.tokenOfOwnerByIndex(owner, index);
        }
        return super.tokenOfOwnerByIndex(owner, index - balanceForOld);
    }

    function tokenByIndex(uint256 index) public view override returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        uint256 totalSupplyOfOld = _ridOldContract.totalSupply();
        if (totalSupplyOfOld > 0 && index < totalSupplyOfOld) {
            return _ridOldContract.tokenByIndex(index);
        }
        return super.tokenByIndex(index - totalSupplyOfOld);
    }

    function ownerOf(uint256 tokenId) public view override(ERC721) returns (address) {
        if (tokenId <= _ridOldContract.totalSupply()) {
            return _ridOldContract.ownerOf(tokenId);
        }
        return super.ownerOf(tokenId);
    }

    function _beforeTokenTransfer(address from,address to,uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // modifiers
    modifier onlyEOA() {
        if (tx.origin != msg.sender)
            revert OnlyExternallyOwnedAccountsAllowed();
        _;
    }

    modifier onlyECC() {
        if (msg.sender != getRidCoinContractAddress())
            revert OnlyExternallyCoinContractAllowed();
        _;
    }
}