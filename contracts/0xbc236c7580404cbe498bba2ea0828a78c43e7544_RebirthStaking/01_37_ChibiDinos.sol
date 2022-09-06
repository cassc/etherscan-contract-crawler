//SPDX-License-Identifier: Unlicense

// @title: Chibi Dinos
// @author: Chibi Dinos Team

//
//      ______  __    __   __  .______    __      _______   __  .__   __.   ______        _______.
//     /      ||  |  |  | |  | |   _  \  |  |    |       \ |  | |  \ |  |  /  __  \      /       |
//    |  ,----'|  |__|  | |  | |  |_)  | |  |    |  .--.  ||  | |   \|  | |  |  |  |    |   (----`
//    |  |     |   __   | |  | |   _  <  |  |    |  |  |  ||  | |  . `  | |  |  |  |     \   \
//    |  `----.|  |  |  | |  | |  |_)  | |  |    |  '--'  ||  | |  |\   | |  `--'  | .----)   |
//     \______||__|  |__| |__| |______/  |__|    |_______/ |__| |__| \__|  \______/  |_______/
//
//

pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ChibiDinos is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {

    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;
    bool private presale;
    bool private sale;

    uint256 public constant MAX_ITEMS = 10000;
    uint256 public constant MAX_PRESALE_ITEMS = 1000;
    uint256 public constant MAX_RESERVE = 100;
    uint256 public constant PRICE = 6E16; // 0.06 ETH
    uint256 public constant RENAME_PRICE = 1E16; // 0.01 ETH
    uint256 public constant MAX_MINT = 20;
    uint256 public constant MAX_MINT_PRESALE = 2;
    address public constant creatorAddress = 0xF27030ef0ace4dFEE90f45C2Ac6210Bcf53bA7B4;
    address public constant devAddress = 0x6f095133E814200fcf06bC185569544249Bd1713;
    string public baseTokenURI;

    event CreateChibi(uint256 indexed id);
    event AttributeChanged(uint256 indexed _tokenId, string _key, string _value);

    constructor(string memory baseURI) ERC721("CHIBI DINOS", "CHIBIDINOS") {
        setBaseURI(baseURI);
        pause(true);
        presale = false;
        sale = false;
    }

    modifier saleIsOpen {
        require(_totalSupply() <= MAX_ITEMS, "Sale ended");
        if (_msgSender() != owner()) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }

    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    function mintReserve(uint256 _count, address _to) public onlyOwner {
        uint256 total = _totalSupply();
        require(total <= MAX_ITEMS, "Sale ended");
        require(total + _count <= MAX_ITEMS, "Max limit");
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }
    }

    function presaleMint(address _to, uint256 _count) public payable {
        uint256 total = _totalSupply();
        require(presale == true, "Presale has not yet started");
        require(total <= MAX_PRESALE_ITEMS, "Presale ended");
        require(total + _count <= MAX_PRESALE_ITEMS, "Max limit");
        require(_count <= MAX_MINT_PRESALE, "Exceeds number");
        require(msg.value >= price(_count), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }
    }

    function mint(address _to, uint256 _count) public payable saleIsOpen {
        uint256 total = _totalSupply();
        require(sale == true, "Sale has not yet started");
        require(total <= MAX_ITEMS, "Sale ended");
        require(total + _count <= MAX_ITEMS, "Max limit");
        require(_count <= MAX_MINT, "Exceeds number");
        require(msg.value >= price(_count), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }
    }

    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreateChibi(id);
    }

    function price(uint256 _count) public pure returns (uint256) {
        return PRICE.mul(_count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    function startPresale() public onlyOwner {
        presale = true;
    }

    function startSale() public onlyOwner {
        sale = true;
    }

    function changeAttribute(uint256 tokenId, string memory key, string memory value) public payable {
        address owner = ERC721.ownerOf(tokenId);
        require(_msgSender() == owner, "This is not your Chibi.");

        uint256 amountPaid = msg.value;
        require(amountPaid == RENAME_PRICE, "There is a price for changing your attributes.");

        emit AttributeChanged(tokenId, key, value);
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(devAddress, balance.mul(40).div(100));
        _widthdraw(creatorAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success,) = _address.call{value : _amount}("");
        require(success, "Transfer failed.");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}