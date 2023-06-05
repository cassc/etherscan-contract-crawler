// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./ProxyRegistry.sol";

contract Onemizer is ERC721, Ownable {
    using Counters for Counters.Counter;

    address proxyRegistryAddress;

    Counters.Counter private _tokenSupply;

    uint256 public PRICE;
    uint256 public START_DATE;
    uint256 public MAX_SUPPLY;

    string private baseUri;

    modifier saleIsActive() {
        require(START_DATE != 0 && block.timestamp >= START_DATE, "Sale is not active yet");
        _;
    }

    constructor(
        address _proxyRegistryAddress,
        uint256 _price,
        uint256 _startDate,
        uint256 _maxSupply,
        string memory _baseUri
    ) ERC721("Onemizer", "OM") {
        proxyRegistryAddress = _proxyRegistryAddress;
        PRICE = _price;
        START_DATE = _startDate;
        MAX_SUPPLY = _maxSupply;
        baseUri = _baseUri;
    }

    function mint(uint256 numberOfTokens) public payable saleIsActive {
        require(numberOfTokens * PRICE == msg.value, "Ether value is not correct");
        require(_tokenSupply.current() + numberOfTokens <= MAX_SUPPLY, "Sold out!");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, _tokenSupply.current());
            _tokenSupply.increment();
        }
    }

    function reserve(address[] calldata to) public onlyOwner {
        for (uint256 i = 0; i < to.length; i++) {
            _safeMint(to[i], _tokenSupply.current());
            _tokenSupply.increment();
        }
    }

    function totalSupply() public view returns (uint256) {
        return _tokenSupply.current();
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://bafybeidpkwijgj42zkcu6cky5ufb542pwuigphgnw5uuheqvioptpc5lv4";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function setPrice(uint256 _price) public onlyOwner {
        PRICE = _price;
    }

    function setStartDate(uint256 _startDate) public onlyOwner {
        START_DATE = _startDate;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        MAX_SUPPLY = _maxSupply;
    }

    function walletOfOwner(address owner) public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](balanceOf(owner));
        uint256 i = 0;

        for (uint256 tokenId = 0; tokenId < _tokenSupply.current(); tokenId++) {
            if (_exists(tokenId) && ownerOf(tokenId) == owner) {
                result[i] = tokenId;
                i += 1;
            }
        }
        return result;
    }

    function withdraw(address payable to, uint256 amount) public onlyOwner {
        require(to != address(0x0), "Invalid address");
        to.transfer(amount);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}