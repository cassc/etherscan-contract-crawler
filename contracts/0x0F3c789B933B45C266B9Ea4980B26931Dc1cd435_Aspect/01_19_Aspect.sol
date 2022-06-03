// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

contract Aspect is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Pausable,
    Ownable,
    AccessControl
{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    mapping(address => uint256) public minted;
    uint256 public _mintPrice = 0.9 ether;
    string private _baseTokenURI;
    address payable public _drainAddress;
    uint256 public _mintLimit = 81;

    // Create a new role identifier for the admin role
    bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');

    // Error messages
    string private constant UNAUTHORIZED = 'Nada Bruh';
    string private constant LIMIT_EXCEEDED = 'Mint Less';
    string private constant WHITELIST_PAUSED = 'Need Wait';
    string private constant INSUFFICIENT_PRICE = 'Need More Money';

    uint256 public constant PER_WALLET_MINT = 1;

    constructor(
        string memory collectionName,
        string memory tokenName,
        string memory baseURI,
        uint256 mintLimit,
        address admin,
        address payable drainAddress
    ) ERC721(collectionName, tokenName) {
        _pause();
        _setupRole(ADMIN_ROLE, admin);

        _baseTokenURI = baseURI;
        _drainAddress = drainAddress;
        _mintLimit = mintLimit;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function pause() public {
        // Check that the calling account has the admin role
        require(hasRole(ADMIN_ROLE, msg.sender), 'Caller is not an admin');
        _pause();
    }

    function unpause() public {
        // Check that the calling account has the admin role
        require(hasRole(ADMIN_ROLE, msg.sender), 'Caller is not an admin');
        _unpause();
    }

    /**
     * Updates the mint price, only callable by admin role
     */
    function setPrice(uint256 price) public {
        // Check that the calling account has the admin role
        require(hasRole(ADMIN_ROLE, msg.sender), 'Caller is not an admin');
        _mintPrice = price;
    }

    /**
     * Returns the digest to be signed using `await web3.eth.sign(digest, signer);`.
     */
    function getWhitelistDigest(address minter) public pure returns (bytes32) {
        return keccak256(abi.encode(minter));
    }

    /**
     * Extracts the signer from a digest and the signature. Can be used
     * together with the `getWhitelistDigest()` method and `await web3.eth.sign()`.
     */
    function recoverSigner(bytes32 digest, bytes calldata _signature)
        public
        pure
        returns (address)
    {
        return ECDSA.recover(digest, _signature);
    }

    /**
     * Drains collected funds to the specified wallet
     */
    function drain() public payable {
        _drainAddress.transfer(address(this).balance);
    }

    /**
     * Allows the Admin to mint free gifts
     */
    function mintGift(address to) public {
        // Check that the calling account has the admin role
        require(hasRole(ADMIN_ROLE, msg.sender), 'Caller is not an admin');

        // Check that we have not minted the max already
        require(_tokenIdCounter.current() < _mintLimit, LIMIT_EXCEEDED);

        // Check that the destination wallet doesnt alreay have the max amount
        require(minted[to] <= PER_WALLET_MINT, LIMIT_EXCEEDED);

        // Check pause
        require(!paused(), WHITELIST_PAUSED);

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        minted[to] += 1;
        _safeMint(to, tokenId);
    }

    /**
     * Allows a whitelisted mint
     */
    function mintWhitelist(bytes calldata _signature) public payable {
        require(_tokenIdCounter.current() < _mintLimit, LIMIT_EXCEEDED);
        require(msg.value == _mintPrice, INSUFFICIENT_PRICE);

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        // check pause
        require(!paused(), WHITELIST_PAUSED);

        // check whitelist authorization first
        bytes32 authorizationDigest = getWhitelistDigest(msg.sender);
        bytes32 message = ECDSA.toEthSignedMessageHash(authorizationDigest);
        address authority = recoverSigner(message, _signature);
        require(authority == owner(), UNAUTHORIZED);

        // mint the NFTs
        minted[msg.sender] += 1;
        _safeMint(msg.sender, tokenId);

        // check supply
        require(totalSupply() <= _mintLimit, LIMIT_EXCEEDED);
        require(minted[msg.sender] <= PER_WALLET_MINT, LIMIT_EXCEEDED);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}