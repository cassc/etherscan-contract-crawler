// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CryptoChicks is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 public constant MAX_ELEMENTS = 10000;
    uint256 public constant PRICE = 55 * 10**15; // .055 eth
    uint256 public constant MAX_BY_MINT = 5;
    uint256 public constant MAX_BY_MINT_WHITELIST = 3;
    uint256 public constant MAX_RESERVE_COUNT = 200;
    uint256 public constant LAUNCH_TIMESTAMP = 1632355200; // Thu Sep 23 2021 00:00:00 GMT+0000

    bool public isSaleOpen = false;
    bool public isPresaleOpen = false;

    mapping(address => bool) private _whiteList;
    mapping(address => uint256) private _whiteListClaimed;
    uint256 private _reservedCount = 0;
    uint256 private _reserveAtATime = 10;

    address public constant t1 = 0xDf336017F01182a736bb0999b14f75Dfd2cB6984;
    address public constant t2 = 0x55823E6C16efd081cf52400a73c0444eAD97d3be;
    address public constant t3 = 0x6B3E893B28bEe6E9B9C93a0108Ad2030b9Cd4AB2;
    address public constant t4 = 0x0a15f8D9b8aCb352eE11a1D76e967Ab44842e9f3;
    address public constant t5 = 0xCc47385c67E2C3C42C8f622048B82a481bd47C71;

    string public baseTokenURI;

    event CreateChick(uint256 indexed id);

    constructor(string memory baseURI) ERC721("Crypto Chicks", "CCH") {
        setBaseURI(baseURI);
    }

    modifier saleIsOpen {
        if (_msgSender() != owner()) {
            require(isSaleOpen, "Sale is not open");
        }
        _;
    }

    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    function reserveTokens() public onlyOwner {
        require(_reservedCount + _reserveAtATime <= MAX_RESERVE_COUNT, "Max reserve exceeded");
        uint256 i;
        for (i = 0; i < _reserveAtATime; i++) {
            _reservedCount++;
            _mintAnElement(msg.sender);
        }
    }

    function mint(address _to, uint256 _count) public payable saleIsOpen {
        uint256 total = _totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(total <= MAX_ELEMENTS, "All CryptoChicks are sold out");
        require(_count <= MAX_BY_MINT, "Exceeds number");
        require(msg.value >= price(_count), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }
    }

    function presaleMint(uint256 _count) public payable {
        require(isPresaleOpen, "Presale is not open");
        require(_whiteList[msg.sender], "You are not in whitelist");
        require(_count <= MAX_BY_MINT_WHITELIST, "Incorrect amount to claim");
        require(_whiteListClaimed[msg.sender] + _count <= MAX_BY_MINT_WHITELIST, "Purchase exceeds max allowed");
        uint256 total = _totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(total <= MAX_ELEMENTS, "All CryptoChicks are sold out");
        require(msg.value >= price(_count), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
            _whiteListClaimed[msg.sender] += 1;
            _mintAnElement(msg.sender);
        }
    }

    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreateChick(id);
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

    function setSaleOpen(bool _isSaleOpen) external onlyOwner {
        isSaleOpen = _isSaleOpen;
    }

    function setPresaleOpen(bool _isPresaleOpen) external onlyOwner {
        isPresaleOpen = _isPresaleOpen;
    }

    function addToWhiteList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Null address found");

            _whiteList[addresses[i]] = true;
            _whiteListClaimed[addresses[i]] > 0 ? _whiteListClaimed[addresses[i]] : 0;
        }
    }

    function addressInWhitelist(address addr) external view returns (bool) {
        return _whiteList[addr];
    }

    function removeFromWhiteList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Null address found");

            _whiteList[addresses[i]] = false;
        }
    }

    function setReserveAtATime(uint256 _count) public onlyOwner {
        _reserveAtATime = _count;
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        uint256 withdrawal = balance.mul(30).div(100);
        _withdraw(t1, withdrawal);
        _withdraw(t2, withdrawal);
        _withdraw(t3, withdrawal);

        uint256 withdrawalSecondary = balance.mul(5).div(100);
        _withdraw(t4, withdrawalSecondary);
        _withdraw(t5, address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        payable(_address).transfer(_amount);
    }
}