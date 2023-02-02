// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BooWhoBabies is ERC721, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;

    uint256 private _tokenIdTracker;

    uint256 public constant maxMintPerTransaction = 40;
    uint256 public price = 0.065 ether;
    uint256 public max_elements = 6001;
    
    string public baseTokenURI;

    address public creatorAddress = 0x5B9a38f60DC2C6398895e326eED1029B18b93446;
    address public artAddress = 0x53fa194fBcEaBf02dbC29ED94d37Fc9fB5c918FE;
    address public advisoryAddress = 0x47a3dC6A23b477008e9ae687E65dCF8164Ef0F5c;
    address public treasuryAddress = 0x57679319Fc509729c3b2DD2eBd1637C9B8fAf9BD;
    address public devAddress = 0xD3FDa2fBa1C26b8D168Bc5Ae6E98197E51679376;

    bool public saleOpen;

    event CreateItem(uint256 indexed id);
    constructor()
    ERC721("BooWho Babies", "BOO")
    {
        pause(true);
    }

    modifier saleIsOpen {
        require(_tokenIdTracker <= max_elements, "Sale end");
        if (_msgSender() != owner()) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdTracker;
    }

    function setSale(bool val) public onlyOwner {
        saleOpen = val;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function mint(uint256 _count, address _recipient) public payable saleIsOpen {
        uint256 total = totalSupply();
        require(saleOpen, "Public sale not open at this time.");
        require(msg.value == price * _count, "Value is over or under price.");
        require(total + _count <= max_elements, "Max limit");
        require(_count <= maxMintPerTransaction, "Max limit per transaction.");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_recipient);
        }

    }

    function ownerMint(uint256 _count, address _recipient) public onlyOwner {
        uint256 total = totalSupply();
        require(total + _count <= max_elements, "Sale end");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_recipient);
        }

    }

    function _mintAnElement(address _to) private {
        uint id = totalSupply();
        _tokenIdTracker += 1;
        _mint(_to, id);
        emit CreateItem(id);
    }

    function setCollectionSize(uint256 elements) external onlyOwner {
        max_elements = elements;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 creatorShare = balance.mul(24).div(100);
        uint256 artShare = balance.mul(34).div(100);
        uint256 advisoryShare = balance.mul(2).div(100);
        uint256 treasuryShare = balance.mul(25).div(100);
        uint256 devShare = balance.mul(15).div(100);
        require(balance > 0);
        _withdraw(creatorAddress, creatorShare);
        _withdraw(artAddress, artShare);
        _withdraw(advisoryAddress, advisoryShare);
        _withdraw(treasuryAddress, treasuryShare);
        _withdraw(devAddress, devShare);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
}