// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract HollyDAO is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _ownerCounter;
    bool public saleIsActive;
    string public baseURI;
    uint256 public immutable maxSupply;
    uint256 public immutable reservedAmount;
    address public immutable proxyRegistryAddress;
    uint256 public mintPrice = 40000000000000000; // 0.04 ETH
    uint256 public maxSaleMint = 4;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        uint256 _maxSupply,
        uint256 _reservedAmount,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        baseURI = _baseTokenURI;
        maxSupply = _maxSupply;
        reservedAmount = _reservedAmount;
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseURI = _baseTokenURI;
    }

    function toggleSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function mint(uint256 _mintAmount) public payable nonReentrant {
        require(saleIsActive, "Public mint is not open");
        require(msg.value >= _mintAmount * mintPrice, "Insufficient funds");
        require(
            _mintAmount < maxSaleMint + 1,
            "Max mint amount per tx exceeded"
        );
        uint256 totalSupply = _tokenIdCounter.current();
        require(totalSupply < maxSupply, "All NFTs have been minted.");

        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(_msgSender(), totalSupply + i);
        }
        _tokenIdCounter._value += _mintAmount;
    }

    function mintReserved(address to, uint256 amount) public onlyOwner {
        require(
            _ownerCounter.current() + amount <= reservedAmount,
            "Max reserved amount reached."
        );
        uint256 totalSupply = _tokenIdCounter.current();
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, totalSupply + i);
        }
        _tokenIdCounter._value += amount;
        _ownerCounter._value += amount;
    }

    // Returns the current amount of NFTs minted.
    function currentSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function isApprovedForAll(address account, address operator)
        public
        view
        override
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(account)) == operator) {
            return true;
        }
        return ERC721.isApprovedForAll(account, operator);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}