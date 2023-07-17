//SPDX-License-Identifier: Unlicense

//     _____                                   _____                 .__
//    /  _  \   ____    ___________ ___.__.   /  _  \   ____    ____ |  |   ___________  ______
//   /  /_\  \ /    \  / ___\_  __ <   |  |  /  /_\  \ /    \  / ___\|  | _/ __ \_  __ \/  ___/
//  /    |    \   |  \/ /_/  >  | \/\___  | /    |    \   |  \/ /_/  >  |_\  ___/|  | \/\___ \
//  \____|__  /___|  /\___  /|__|   / ____| \____|__  /___|  /\___  /|____/\___  >__|  /____  >
//          \/     \//_____/        \/              \/     \//_____/           \/           \/

// @title: Angry Anglers
// @author: Angry Anglers Team


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

contract AngryAnglers is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {

    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;
    bool private presale;
    bool private sale;

    uint256 public constant MAX_ITEMS = 4500;
    uint256 public constant MAX_PRESALE_ITEMS = 575;
    uint256 public constant MAX_RESERVE = 75;
    uint256 public constant PRICE = 0.07 ether;
    uint256 public constant RENAME_PRICE = 0.01 ether;
    uint256 public constant MAX_MINT = 100;
    uint256 public constant MAX_MINT_PRESALE = 100;
    address public constant devAddress = 0x6b3Aba514bb2A57a20632B3160f1F4c08278ed17;
    string public baseTokenURI;

    event CreateNft(uint256 indexed id);
    event AttributeChanged(uint256 indexed _tokenId, string _key, string _value);

    constructor(string memory baseURI) ERC721("ANGRY ANGLERS", "AA") {
        setBaseURI(baseURI);
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
        // @dev start token id at 1 instead of 0
        _tokenIdTracker.increment();
        uint id = _totalSupply();
        _safeMint(_to, id);
        emit CreateNft(id);
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

    function togglePresale() public onlyOwner {
        presale = !presale;
    }

    function toggleSale() public onlyOwner {
        sale = !sale;
    }

    function changeAttribute(uint256 tokenId, string memory key, string memory value) public payable {
        address owner = ERC721.ownerOf(tokenId);
        require(_msgSender() == owner, "This is not your NFT.");

        uint256 amountPaid = msg.value;
        require(amountPaid == RENAME_PRICE, "There is a price for changing your attributes.");

        emit AttributeChanged(tokenId, key, value);
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(devAddress, address(this).balance);
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