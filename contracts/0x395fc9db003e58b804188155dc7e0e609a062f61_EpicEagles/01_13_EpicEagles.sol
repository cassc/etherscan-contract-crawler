// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract EpicEagles is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 public constant MAX_ELEMENTS = 7676;
    uint256 public constant RESERVE_GIVEAWAYS = 50;
    uint256 public constant PRICE = 0 ether;
    uint256 public constant MAX_BY_MINT = 1;
    uint256 public constant START_AT = 1;

    uint256 private startSales = 1631232000; // 2021-09-10 at 00:00:00 UTC

    address public constant creatorAddress = 0x722FFd38eB050e92f4C3804a8bf823521C726d77;
    address public constant artistAddress = 0xD8103Fb67F82F800fd2422080Bb7738CBe4D3DB4;
    address public constant devAddress = 0xcBCc84766F2950CF867f42D766c43fB2D2Ba3256;

    string public baseTokenURI;

    event adoptAnEpicEagle(uint256 indexed id);

    constructor(string memory baseURI) ERC721("EpicEagles", "EA") {
        setBaseURI(baseURI);
    }

    modifier saleIsOpen {
        require(_totalSupply() <= MAX_ELEMENTS, "Sale end");
        if (_msgSender() != owner()) {
            require(salesIsOpen(), "Sales not open");
        }
        _;
    }
    function _totalSupply() internal view returns (uint256) {
        return _tokenIdTracker.current();
    }
    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }
    function mint(address _to, uint256 _count) public payable saleIsOpen {
        uint256 total = _totalSupply();
        require(_count <= MAX_BY_MINT, "Exceeds number");
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(msg.value >= price(_count), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }
    }
    function _mintAnElement(address _to) private {
        uint id = _totalSupply() + START_AT;
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit adoptAnEpicEagle(id);
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
        uint256 key = 0;
        uint256[] memory tokensId = new uint256[](tokenCount);

        for (uint256 i = START_AT; i <= _totalSupply(); i++) {
            if(rawOwnerOf(i) == _owner){
                tokensId[key] = i;
                key++;

                if(key == tokenCount){
                    break;
                }
            }
        }
        return tokensId;
    }

    function setStartSales(uint256 _start) public onlyOwner {
        startSales = _start;
    }

    function getStartSales() public view returns(uint256) {
        return startSales;
    }

    function salesIsOpen() public view returns (bool){
        return block.timestamp >= startSales;
    }

    function withdrawContract() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(_msgSender(), address(this).balance);
    }

    function withdrawRoyalties() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(devAddress, balance.mul(46).div(100));
        _widthdraw(artistAddress, balance.mul(8).div(100));
        _widthdraw(creatorAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner nor approved");
        _burn(tokenId);
    }

    function reserve(uint256 _count) public onlyOwner {
        uint256 total = _totalSupply();
        require(total + _count <= RESERVE_GIVEAWAYS, "Exceeded");
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_msgSender());
        }
    }
    receive() external payable {}

}