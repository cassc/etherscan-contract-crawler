// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@openzeppelin/contracts/finance/PaymentSplitter.sol';
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NoogaNaega is 
    ERC721,
    Ownable, 
    ReentrancyGuard, 
    PaymentSplitter 
{
    using Strings for uint256;
    using Counters for Counters.Counter;
    
    address proxyRegistryAddress;

    uint256 public maxSupply = 9001;
    uint8 constant maxTokensPerTx = 10;

    string public baseURI;
    string public baseExtension = ".json";

    bool public paused = false;

    uint256 _price = 100000000000000000; // 0.10 ETH

    Counters.Counter private _tokenIds;

    uint256[] private _walletAllocations = [50, 50];
    address[] private _wallet = [
        0x753B8f059cc9e0d5588524aAC078B01DC2327c68, 
        0xcf7103015F10455B9F0C85d44FeD5C10B01CF4C6
    ];

    constructor(string memory uri, address _proxyRegistryAddress)
        ERC721("NoogaNaega", "N_N")
        PaymentSplitter(_wallet, _walletAllocations)
        ReentrancyGuard()
    {
        proxyRegistryAddress = _proxyRegistryAddress;

        setBaseURI(uri);
    }    

    function setBaseURI(string memory _tokenBaseURI) public onlyOwner {
        baseURI = _tokenBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    modifier onlyAccounts () {
        require(msg.sender == tx.origin, "Not allowed origin");
        _;
    }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function publicMint(uint256 amount) 
    external 
    payable
    onlyAccounts
    {
        require(!paused, "NoogaNaega Red: Contract is paused");
        require(amount > 0, "NoogaNaega Red: Mint cannot be 0 amount");

        uint current = _tokenIds.current();

        require(amount <= maxTokensPerTx, "NoogaNaega Red: Maximum mint amount is set to 10 at a time.");

        require(
            current + amount <= maxSupply,
            "NoogaNaega Red: Max supply exceeded"
        );
        require(
            _price * amount <= msg.value,
            "NoogaNaega Red: Not enough ethers sent"
        );

        for (uint i = 0; i < amount; i++) {
            mintInternal();
        }
    }

    function mintInternal() internal nonReentrant {
        _tokenIds.increment();

        uint256 tokenId = _tokenIds.current();
        _safeMint(msg.sender, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
    
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)) : "";
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function totalSupply() public view returns (uint) {
        return _tokenIds.current();
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == address(this)) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}

/**
  @title An OpenSea delegate proxy contract which we include for whitelisting.
  @author OpenSea
*/
contract OwnableDelegateProxy {}

/**
  @title An OpenSea proxy registry contract which we include for whitelisting.
  @author OpenSea
*/
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}