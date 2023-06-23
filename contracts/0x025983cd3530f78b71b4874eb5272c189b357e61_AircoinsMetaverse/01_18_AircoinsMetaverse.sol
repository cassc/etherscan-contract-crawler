// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";

contract AircoinsMetaverse is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 public MAX_ELEMENTS = 1200;
    uint256 public constant PRICE = 1 * 10**17; // 0.1 ETH
    uint256 public constant MAX_BY_MINT = 10;
    uint256 public constant MAX_PER_ADDRESS = 10;
    uint256 public SOLD_OUT_ELEMENTS = 449;
    uint256 public constant reveal_timestamp = 1634954400000; // Sat Oct 22nd 2021 10 PM EST
    address public devAddress; // account
    string public baseTokenURI; // IPFS

    event CreateAircoinsMetaverse(uint256 indexed id);

    constructor(string memory baseURI, address DEV_ADDRESS) ERC721("Aircoins Metaverse", "AIRx") {
        devAddress = DEV_ADDRESS;

        setBaseURI(baseURI);
        pause(true);
    }

    modifier saleIsOpen {
        require(_totalSupply() <= (MAX_ELEMENTS - SOLD_OUT_ELEMENTS), "Sale end");
        if (_msgSender() != owner()) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }

    modifier saleIsReveal {
        require(block.timestamp >= reveal_timestamp, "Not revealed yet");
        _;
    }

    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    // multiple mint (saleIsReveal)
    function mint(address _to, uint256 _count) public payable saleIsOpen {
        uint256 total = _totalSupply();
        
        require(total + _count <= (MAX_ELEMENTS - SOLD_OUT_ELEMENTS), "Mint: over Max limit");
        require(_count <= MAX_BY_MINT, "Exceeds number");
        require(balanceOf(_to) + _count <= MAX_PER_ADDRESS, "Exceeds balance");        
        require(msg.value >= price(_count), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }
    }

    // this is for presale
    function presaleMint(address _to) public payable onlyOwner {
        _mintAnElement(_to);
    }

    // mint one Token to sender
    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        
        emit CreateAircoinsMetaverse(id);
    }

    // the total price of token amounts which the sender will mint
    function price(uint256 _count) public pure returns (uint256) {
        return PRICE.mul(_count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // set BaseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    // set MAX_ELEMENTS
    function setMaxElements(uint256 _count) public onlyOwner {
        MAX_ELEMENTS = _count;
    }

    // set MAX_ELEMENTS
    function setSoldOutElements(uint256 _count) public onlyOwner {
        SOLD_OUT_ELEMENTS = _count;
    }

    // get wallet infos
    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    // set the state of market
    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    // withdraw all coins
    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(devAddress, balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    // override function
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

    // set dev address
    function setDevAddr(address new_dev_addr) public onlyOwner{
        require(new_dev_addr != address(0), 'Invalid address');
        devAddress = new_dev_addr;
    }
}