// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract PixelDoods is Ownable, ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    uint256 public constant MAX_TOKENS = 8889;
    uint256 public constant MINT_TRANSACTION_LIMIT = 9;

    uint256 public tokenPrice = 0.035 ether;
    uint256 public freeMints = 1089;
    bool public saleIsActive;

    string _baseTokenURI;
    address _proxyRegistryAddress;

    constructor(address proxyRegistryAddress) ERC721("Pixel Doods", "PXD") {
        _proxyRegistryAddress = proxyRegistryAddress;
        _tokenSupply.increment();
        _safeMint(msg.sender, 0);
    }

    function freeMint(uint256 amount) external {
        require(saleIsActive, "Sale is not active");
        require(amount < MINT_TRANSACTION_LIMIT, "Mint amount too large");
        uint256 supply = _tokenSupply.current();
        require(supply + amount < freeMints, "Not enough free mints remaining");

        for (uint256 i = 0; i < amount; i++) {
            _tokenSupply.increment();
            _safeMint(msg.sender, supply + i);
        }
    }

    function publicMint(uint256 amount) external payable {
        require(saleIsActive, "Sale is not active");
        require(amount < MINT_TRANSACTION_LIMIT, "Mint amount too large");
        uint256 supply = _tokenSupply.current();
        require(supply + amount < MAX_TOKENS, "Not enough tokens remaining");
        require(tokenPrice * amount <= msg.value, "Not enough ether sent");

        for (uint256 i = 0; i < amount; i++) {
            _tokenSupply.increment();
            _safeMint(msg.sender, supply + i);
        }
    }

    function reserveTokens(address to, uint256 amount) external onlyOwner {
        uint256 supply = _tokenSupply.current();
        require(supply + amount < MAX_TOKENS, "Not enough tokens remaining");
        for (uint256 i = 0; i < amount; i++) {
            _tokenSupply.increment();
            _safeMint(to, supply + i);
        }
    }

    function setTokenPrice(uint256 newPrice) external onlyOwner {
        tokenPrice = newPrice;
    }

    function setFreeMints(uint256 amount) external onlyOwner {
        require(amount <= MAX_TOKENS, "Free mint amount too large");
        freeMints = amount;
    }

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenSupply.current();
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setProxyRegistryAddress(address proxyRegistryAddress)
        external
        onlyOwner
    {
        _proxyRegistryAddress = proxyRegistryAddress;
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    receive() external payable {}

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}