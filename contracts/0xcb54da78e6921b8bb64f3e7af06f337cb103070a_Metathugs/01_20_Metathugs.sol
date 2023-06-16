//SPDX-License-Identifier: Unlicense

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

contract Metathugs is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {

    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;
    bool private whitelist;
    bool private presale;
    bool private sale;

    uint256 public constant MAX_ITEMS = 10000;
    uint256 public constant MAX_ITEMS_WHITELIST = 3000;
    uint256 public constant WHITELIST_PRICE = 0.085 ether;
    uint256 public constant PRESALE_PRICE = 0.1 ether;
    uint256 public constant PRICE = 0.12 ether;
    uint256 public constant MAX_MINT = 15;
    uint256 public constant MAX_MINT_PRESALE = 3;
    address public constant devAddress = 0xC51a2f1f1b0BB69D744fA07E3561a52efcCFA1c3;
    string public baseTokenURI;

    mapping(address => bool) private _presaleList;
    mapping(address => uint256) private _presaleListClaimed;

    event CreateNft(uint256 indexed id);

    constructor(string memory baseURI) ERC721("Metathugs", "METATHUGS") {
        setBaseURI(baseURI);
        whitelist = false;
        presale = false;
        sale = false;
    }

    function addToPresaleList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            _presaleList[addresses[i]] = true;
            _presaleListClaimed[addresses[i]] > 0 ? _presaleListClaimed[addresses[i]] : 0;
        }
    }

    function onPresaleList(address addr) external view returns (bool) {
        return _presaleList[addr];
    }

    function removeFromPresaleList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            _presaleList[addresses[i]] = false;
        }
    }

    function presaleListClaimedBy(address owner) external view returns (uint256){
        require(owner != address(0), 'Zero address not on Allow List');

        return _presaleListClaimed[owner];
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

    function mint(address _to, uint256 _count) public payable saleIsOpen {
        uint256 total = _totalSupply();

        if(whitelist == true) {
            require(_presaleList[_to], 'You are not on the whitelist');
            require(_count <= MAX_MINT, "Exceeds number");
            require(total <= MAX_ITEMS_WHITELIST, "Whitelist sale ended");
            require(msg.value >= whitelistPrice(_count), "Value below price");

            for (uint256 i = 0; i < _count; i++) {
                _mintAnElement(_to);
            }
        }

        if(presale == true) {
            require(total <= MAX_ITEMS, "Sale ended");
            require(total + _count <= MAX_ITEMS, "Max limit");
            require(_count <= MAX_MINT, "Exceeds number");
            require(msg.value >= presalePrice(_count), "Value below price");

            for (uint256 i = 0; i < _count; i++) {
                _mintAnElement(_to);
            }
        }

        if(sale == true) {
            require(total <= MAX_ITEMS, "Sale ended");
            require(total + _count <= MAX_ITEMS, "Max limit");
            require(_count <= MAX_MINT, "Exceeds number");
            require(msg.value >= price(_count), "Value below price");

            for (uint256 i = 0; i < _count; i++) {
                _mintAnElement(_to);
            }
        }
    }

    function _mintAnElement(address _to) private {
        // @dev start token id at 1 instead of 0
        _tokenIdTracker.increment();
        uint id = _totalSupply();
        _safeMint(_to, id);
        emit CreateNft(id);
    }

    function whitelistPrice(uint256 _count) public pure returns (uint256) {
        if(_count == 5) {
            return 0.405 ether;
        }
        if(_count == 10) {
            return 0.8 ether;
        }

        return WHITELIST_PRICE.mul(_count);
    }

    function presalePrice(uint256 _count) public pure returns (uint256) {
        if(_count == 5) {
            return 0.48 ether;
        }
        if(_count == 10) {
            return 0.95 ether;
        }

        return PRESALE_PRICE.mul(_count);
    }

    function price(uint256 _count) public pure returns (uint256) {
        if(_count == 5) {
            return 0.58 ether;
        }
        if(_count == 10) {
            return 1.15 ether;
        }

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

    function whitelistActive() external view returns (bool) {
        return whitelist;
    }

    function presaleActive() external view returns (bool) {
        return presale;
    }

    function saleActive() external view returns (bool) {
        return sale;
    }

    function toggleWhitelist() public onlyOwner {
        whitelist = !whitelist;
    }

    function togglePresale() public onlyOwner {
        presale = !presale;
    }

    function toggleSale() public onlyOwner {
        sale = !sale;
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