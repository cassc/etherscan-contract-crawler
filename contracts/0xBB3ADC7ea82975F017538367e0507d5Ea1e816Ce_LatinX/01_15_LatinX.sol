//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract LatinX is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _counter;
    uint public MAX_SUPPLY = 1000;
    uint256 public price = .08 ether;
    string public baseURI;
    bool public saleIsActive = false;
    uint public constant maxPassTxn = 5;
    address private _manager;
    uint256 public startDate;

    constructor() ERC721("Latin X", "LATINX") Ownable() {}

    function setManager(address manager) public onlyOwner {
        _manager = manager;
    }

    function getManager() public view onlyOwnerOrManager returns (address) {
        return _manager;
    }

    modifier onlyOwnerOrManager() {
        require(
            owner() == _msgSender() || _manager == _msgSender(),
            "Caller is not the owner or manager"
        );
        _;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwnerOrManager {
        baseURI = newBaseURI;
    }

    function setMaxSupply(uint _maxSupply) public onlyOwnerOrManager {
        MAX_SUPPLY = _maxSupply;
    }

    function setPrice(uint256 _price) public onlyOwnerOrManager {
        price = _price;
    }

    function setStartDate(uint256 _startDate) public onlyOwnerOrManager {
        startDate = _startDate;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function totalToken() public view returns (uint256) {
        return _counter.current();
    }

    function contractBalance()
        public
        view
        onlyOwnerOrManager
        returns (uint256)
    {
        return address(this).balance;
    }

    function flipSale() public onlyOwnerOrManager {
        saleIsActive = !saleIsActive;
    }

    function withdrawAll(address _address) public onlyOwnerOrManager {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance is zero");
        (bool success, ) = _address.call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function _widthdraw(
        address _address,
        uint256 _amount
    ) public onlyOwnerOrManager {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function reserveLatinX(
        uint256 reserveAmount,
        address mintAddress
    ) public onlyOwnerOrManager {
        require(
            totalSupply() + reserveAmount <= MAX_SUPPLY,
            "LatinX Sold Out"
        );
        for (uint256 i = 0; i < reserveAmount; i++) {
            _safeMint(mintAddress, _counter.current() + 1);
            _counter.increment();
        }
    }

    function mintLatinX(uint32 numberOfTokens) public payable {
        require(
            block.timestamp >= startDate,
            "Sale must be active to mint LatinX"
        );
        require(
            numberOfTokens >= 1,
            "You must at least mint 1 Token"
        );
        require(
            price * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );
        require(
            numberOfTokens <= maxPassTxn,
            "You can only mint 5 LatinX's at a time"
        );
        require(
            totalSupply() + numberOfTokens <= MAX_SUPPLY,
            "LatinX's Sold Out"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = _counter.current() + 1;
            if (mintIndex <= MAX_SUPPLY) {
                _safeMint(msg.sender, mintIndex);
                _counter.increment();
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}