//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

/********************************************************************
      ____             __      __  __           _
     / __ \____ ______/ /__   / / / /___  _____(_)___  ____  ____
    / / / / __ `/ ___/ //_/  / /_/ / __ \/ ___/ /_  / / __ \/ __ \
   / /_/ / /_/ / /  / ,<    / __  / /_/ / /  / / / /_/ /_/ / / / /
  /_____/\__,_/_/  /_/|_|  /_/ /_/\____/_/  /_/ /___/\____/_/ /_/

********************************************************************/

contract DarkHorizon is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    uint256 public constant MAX_SUPPLY = 8686;
    uint256 public constant PRESALE_PRICE = 0.0757 ether;
    uint256 public constant SALE_PRICE = 0.0868 ether;

    address private _verifier = 0xBC2BE33AA56186764e716b04A64c5aa617139cad;
    address proxyRegistryAddress;

    bool public IS_PRESALE_ACTIVE = false;
    bool public IS_SALE_ACTIVE = false;

    Counters.Counter private _tokenIdCounter;

    string public provenanceHash = '5cf6b17cb2efeaf9521921fe27718f30e4fe251fde73e773f9fb62390bde8757';

    /**
     * Metadata has some dynamic traits (like skills).
     * Images and static traits are proveable on-chain by provenanceHash.
     */
    string private baseTokenURI = 'https://www.darkhorizon.io/api/tokens/';

    constructor(address _proxyRegistryAddress) ERC721('DarkHorizon', 'DH') {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal view override returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }

    function _recoverWallet(
        address wallet,
        uint256 tokensAmount,
        uint256 id,
        bytes memory signature
    ) internal pure returns (address) {
        return
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(
                    keccak256(abi.encodePacked(wallet, tokensAmount, id))
                ),
                signature
            );
    }

    function _mintOneToken(address to) internal {
        _tokenIdCounter.increment();
        _safeMint(to, _tokenIdCounter.current());
    }

    function _mintTokens(
        uint256 tokensLimit,
        uint256 tokensAmount,
        uint256 tokenPrice
    ) internal {
        require(tokensAmount <= tokensLimit, 'Incorrect tokens amount');
        require(
            (_tokenIdCounter.current() + tokensAmount) <= MAX_SUPPLY,
            'Minting would exceed total supply'
        );
        require(msg.value >= (tokenPrice * tokensAmount), 'Incorrect price');

        address sender = _msgSender();

        require(
            (balanceOf(sender) + tokensAmount) <= tokensLimit,
            'Limit per wallet'
        );

        for (uint256 i = 0; i < tokensAmount; i++) {
            _mintOneToken(sender);
        }
    }

    function mintSale(uint256 tokensAmount) public payable {
        require(IS_SALE_ACTIVE, 'Sale is closed');

        _mintTokens(6, tokensAmount, SALE_PRICE);
    }

    function mintPresale(uint256 id, bytes calldata signature) public payable {
        require(IS_PRESALE_ACTIVE, 'PreSale is closed');

        address signer = _recoverWallet(_msgSender(), 1, id, signature);

        require(signer == _verifier, 'Unverified transaction');

        _mintTokens(1, 1, PRESALE_PRICE);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        return super.isApprovedForAll(_owner, _operator);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Enumerable, ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mintReserved(uint256 tokensAmount) public onlyOwner {
        require(
            _tokenIdCounter.current() + tokensAmount <= MAX_SUPPLY,
            'Minting would exceed total supply'
        );

        for (uint256 i = 0; i < tokensAmount; i++) {
            _mintOneToken(msg.sender);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setVerifier(address _newVerifier) public onlyOwner {
        _verifier = _newVerifier;
    }

    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        provenanceHash = _provenanceHash;
    }

    function setSaleState(bool _isPresaleActive, bool _isSaleActive)
        public
        onlyOwner
    {
        IS_PRESALE_ACTIVE = _isPresaleActive;
        IS_SALE_ACTIVE = _isSaleActive;
    }

    function withdrawAll() public onlyOwner {
        (bool success, ) = _msgSender().call{value: address(this).balance}('');
        require(success, 'Withdraw failed');
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}