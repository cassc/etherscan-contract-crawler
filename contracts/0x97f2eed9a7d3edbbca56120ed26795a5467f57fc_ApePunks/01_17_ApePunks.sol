// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./MyERC721Enumerable.sol";
import "./CollectionPartnerInterface.sol";

// thx Pudgy Penguins for the contract <3
contract ApePunks is MyERC721Enumerable, Ownable, ERC721Burnable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 public constant MAX_ELEMENTS = 10000;
    uint256 public constant PRICE = 0.03 ether;
    uint256 public constant MAX_BY_MINT = 20;
    uint256 public constant MAX_RESERVE = 150;

    address public constant nerdAddress = 0x3e5dDB87159DE8E4c0Bb2397720a11514D05Add1;
    address public constant beardyAddress = 0xD097279f0Eba6Ae2c6561C084c73D0c27279606E;
    address public constant dinoAddress = 0xD127b07954f3E57E3e5AaecbB7621b1dAa1ac440;

    uint private startSales = 1629403200; // 2021-08-19 à 20:00:00

    string public baseTokenURI;

    CollectionPartnerInterface private _collectionPartner;
    mapping (address => bool) private _walletClaim;

    event CreatePunk(uint256 indexed id);
    constructor(string memory baseURI) ERC721("ApePunks", "APEK") {
        setBaseURI(baseURI);
    }

    modifier saleIsOpen {
        require(_totalSupply() <= MAX_ELEMENTS, "Sale end.");
        if (_msgSender() != owner()) {
            require(block.timestamp >= startSales, "Sales not open.");
        }
        _;
    }
    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }
    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    function mint(address _to, uint256 _count) public payable saleIsOpen {
        uint256 total = _totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(total <= MAX_ELEMENTS, "Sale end");
        require(_count <= MAX_BY_MINT, "Exceeds number");
        require(msg.value >= price(_count), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }
    }

    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id + 1);
        emit CreatePunk(id + 1);
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

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function setStartSales(uint _start) public onlyOwner {
        startSales = _start;
    }

    function getStartSales() public view returns(uint) {
        return startSales;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(nerdAddress, balance.mul(20).div(100));
        _widthdraw(beardyAddress, balance.mul(40).div(100));
        _widthdraw(dinoAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, MyERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, MyERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function reserve(uint256 _count) public onlyOwner {
        uint256 total = _totalSupply();
        require(total + _count <= MAX_RESERVE, "Exceeded giveaways.");
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_msgSender());
        }
    }

    // for you my friends <3
    function setCollectionPartner(address _collectionContract) external onlyOwner {
        _collectionPartner = CollectionPartnerInterface(_collectionContract);
    }

    function mintPartnerFree() public saleIsOpen {
        uint256 _count = 1;
        uint256 total = _totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(total <= MAX_ELEMENTS, "Sale end");

        address _to = _msgSender();
        require(_walletClaim[_to] == false && _collectionPartner.walletOfOwner(_to).length > 0, "You can't mint free");

        _walletClaim[_to] = true;
        _mintAnElement(_to);
    }

    function hasPartnerCollection(address _to) public view returns(bool){
        return _walletClaim[_to] == false && _collectionPartner.walletOfOwner(_to).length > 0;
    }
}