// SPDX-License-Identifier: MIT
/*

█▀▄▀█ ████▄ ████▄    ▄   ███   ▄█ █▄▄▄▄ ██▄      ▄▄▄▄▄   ███   ██     ▄▄▄▄▀ ▄▄▄▄▄▄
█ █ █ █   █ █   █     █  █  █  ██ █  ▄▀ █  █    █     ▀▄ █  █  █ █ ▀▀▀ █   ▀   ▄▄▀
█ ▄ █ █   █ █   █ ██   █ █ ▀ ▄ ██ █▀▀▌  █   █ ▄  ▀▀▀▀▄   █ ▀ ▄ █▄▄█    █    ▄▀▀   ▄▀
█   █ ▀████ ▀████ █ █  █ █  ▄▀ ▐█ █  █  █  █   ▀▄▄▄▄▀    █  ▄▀ █  █   █     ▀▀▀▀▀▀
   █              █  █ █ ███    ▐   █   ███▀             ███      █  ▀
  ▀               █   ██           ▀                             █
                                                                ▀

*/
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// @author neek

contract MoonbirdsBatz is
    ERC721,
    Ownable,
    ReentrancyGuard
{
    using Strings for uint256;
    using Counters for Counters.Counter;



    uint256 public maxSupply = 3000;
    //change to normal address for mainnet
    address proxyRegistryAddress;
    string public baseURI;
    string public notRevealedUri = "ipfs://QmUAYJu8dc16t8tPH9ZDffxkLE7UdYwBQ7MZK23UZiVgbw";

    bool public paused = false;
    bool public revealed = false;
    bool public presaleM = false;
    bool public publicM = false;
    bool public freesaleM = true;

    uint256 freeAmountLimit = 2;
    mapping(address => uint256) public _presaleClaimed;
    mapping(address => uint256) public _freeClaimed;

    uint256 _price = 10000000000000000;
    uint256 _freePrice = 0;
    Counters.Counter private _tokenIds;


    constructor()
        ERC721("MoonbirdsBatz", "MBB")
        ReentrancyGuard() // A modifier that can prevent reentrancy during certain functions
    {
    }

    function setBaseURI(string memory _tokenBaseURI) public onlyOwner {
        baseURI = _tokenBaseURI;
    }

    function setProxyRegistry(address _proxyRegistryAddress) public onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }


    modifier onlyAccounts () {
        require(msg.sender == tx.origin, "Not allowed origin");
        _;
    }


    function togglePublicSale() public onlyOwner {
        publicM = !publicM;
    }

    function freeSaleMint(uint256 _amount)
    external
    payable
    onlyAccounts
    {
        require(!paused, "MoonbirdsBatz: Contract is paused");
        require(_amount < 5, "MoonbirdsBatz: zero amount");

        uint current = _tokenIds.current();

        require(
            current + _amount <= 100,
            "MoonbirdsBatz: Max supply exceeded"
        );
        require(
            _freePrice * _amount <= msg.value,
            "MoonbirdsBatz: Not enough ethers sent"
        );


        for (uint i = 0; i < _amount; i++) {
            mintInternal();
        }
    }


    function publicSaleMint(uint256 _amount)
    external
    payable
    onlyAccounts
    {
        require(publicM, "MoonbirdsBatz: PublicSale is OFF");
        require(!paused, "MoonbirdsBatz: Contract is paused");
        require(_amount > 0, "MoonbirdsBatz: zero amount");

        uint current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "MoonbirdsBatz: Max supply exceeded"
        );
        require(
            _price * _amount <= msg.value,
            "MoonbirdsBatz: Not enough ethers sent"
        );


        for (uint i = 0; i < _amount; i++) {
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
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();

        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString()
                    )
                )
                : "";
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
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
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }


    function withdraw_all() public onlyOwner{
        uint balance = address(this).balance;
        require(payable(msg.sender).send(balance));
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