// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/// @title: EllaDAO
/// @author: null.eth

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract EllaDAO is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _ownerCounter;
    bool public saleIsActive;
    string public baseURI;
    uint256 public immutable maxSupply;
    uint256 public immutable reservedAmount;
    address public immutable proxyRegistryAddress;

    constructor(string memory _name, string memory _symbol, uint256 _maxSupply, uint256 _reservedAmount, address _proxyRegistryAddress) ERC721(_name, _symbol) {
        maxSupply = _maxSupply;
        reservedAmount = _reservedAmount;
        proxyRegistryAddress = _proxyRegistryAddress;
    }
   
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseURI = _baseTokenURI;
    }

    function toggleSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    // NFTs reserved for the team.
    function mintReserved(address to, uint256 amount) public onlyOwner {
        require(_ownerCounter.current() + amount <= reservedAmount, "Max reserved amount reached.");
        uint256 totalSupply = _tokenIdCounter.current();
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, totalSupply + i);
        }
        _tokenIdCounter._value += amount;
        _ownerCounter._value += amount;
    }

    function safeMint() public nonReentrant {
        require(saleIsActive, "Public mint is currently paused.");
        uint256 totalSupply = _tokenIdCounter.current();
        require(totalSupply < maxSupply, "Maximum amount of NFTs have been minted.");
        _safeMint(_msgSender(), totalSupply);
        _tokenIdCounter.increment();
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    // Returns the current amount of NFTs minted.
    function currentSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // Withdraw contract balance in case someone sends Ether to the address.
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function isApprovedForAll(address account, address operator) override public view returns (bool) {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(account)) == operator) {
            return true;
        }
        return ERC721.isApprovedForAll(account, operator);
    }
}