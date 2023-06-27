// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";

contract Moondusa is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 public constant MAX_ELEMENTS = 8888;
    uint256 public constant PRICE = 7 * 10**16; // (WEI) 0.07 Ether
    uint256 public constant MAX_BY_MINT = 20;
    
    address public constant creatorOneAddress = 0xb026fC5adDE0f21061E00f56e5612361d02D5A56;
    address public constant creatorTwoAddress = 0x5A12c6E3839008eA478A9f09675C7519f58D3416;
    address public constant marketingAddress = 0x7C69E0436F591ff83119fbFFD28c92415fCD2442;
    address public constant devAddress = 0xf82E101983159DF83CC89a76021c442429b2595c;
    address public constant artAddress = 0xD9A24f14dC3FC16b2F5adfaa7d7E6B38d398cE79;

    string public baseTokenURI;

    event CreateMoondusa(uint256 indexed id);
    constructor()
    ERC721("Moondusa", "MOON") 
    {
        setBaseURI('https://api.moondusa.io/moondusa/');
        pause(true);
    }

    modifier saleIsOpen {
        require(_totalSupply() <= MAX_ELEMENTS, "Sale end");
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
        _safeMint(_to, id);
        emit CreateMoondusa(id);
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

    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        uint256 creatorOneShare = balance.mul(22).div(100);
        uint256 creatorTwoShare = balance.mul(22).div(100);
        uint256 devShare = balance.mul(15).div(100);
        uint256 marketingShare = balance.mul(19).div(100);
        uint256 artShare = balance.mul(22).div(100);
        require(balance > 0);
        _withdraw(creatorOneAddress, creatorOneShare);
        _withdraw(creatorTwoAddress, creatorTwoShare);
        _withdraw(devAddress, devShare);
        _withdraw(marketingAddress, marketingShare);
        _withdraw(artAddress, artShare);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
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