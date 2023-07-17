// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title GeneticChain721
 * GeneticChainBase - ERC721 contract that whitelists a trading address, and has
 *  minting functionality.
 */
abstract contract GeneticChain721 is
    ContextMixin,
    ERC721Enumerable,
    NativeMetaTransaction,
    Ownable
{
    using ECDSA for bytes32;

    // message signer
    address constant private _signer = 0xDA9F95f43d4189285fA618Df89f66d9666e80694;

    // opensea proxy
    address _proxyRegistryAddress;

    // mapping from token id to token hash
    mapping (uint256 => bytes32) private _hash;

    // only allow nonces to be used once
    mapping(string => bool) private _usedNonces;

    // track mint count per address
    mapping (address => uint256) private _mints;

    // token data
    uint256 private _currentTokenId = 0;
    uint256 private _seed;

    // settings
    bool private _locked   = false;
    bool public publicLive = false;

    // mint price (0.03 / 0.05)
    uint256 public memberPrice = 30000000000000000;
    uint256 public publicPrice = 50000000000000000;

    // token limits
    uint256 public publicMax;
    uint256 public artistMax;
    uint256 public galleryMax;
    uint256 public tokenMax;
    uint256 public publicMinted = 0;
    uint256 public artistMinted = 0;
    uint256 public galleryMinted = 0;

    // roles
    address private _burnerAddress;
    address private _artistAddress = 0xC76cb2613026998b82cEB467134ecFF003Ebbb80;

    modifier validTokenId(uint256 tokenId) {
        require(_exists(tokenId), "invalid token");
        _;
    }

    modifier approvedOrOwner(address operator, uint256 tokenId) {
        require(_isApprovedOrOwner(operator, tokenId));
        _;
    }

    modifier isArtist() {
        require(_msgSender() == _artistAddress, "caller not artist");
        _;
    }

    modifier isBurner() {
        require(_msgSender() == _burnerAddress, "caller not burner");
        _;
    }

    modifier notLocked() {
        require(!_locked, "contract is locked");
        _;
    }

    constructor(
        uint256[3] memory tokenMax_,
        uint256 seed,
        address proxyRegistryAddress)
        ERC721("Ikebana", "GCP5")
    {
        publicMax             = tokenMax_[0];
        artistMax             = tokenMax_[1];
        galleryMax            = tokenMax_[2];
        tokenMax              = publicMax + artistMax + galleryMax;
        _seed                 = seed;
        _proxyRegistryAddress = proxyRegistryAddress;
        _initializeEIP712("Ikebana");
    }

    /**
     * Set artist address.
     */
    function setArtistAddress(address artist)
        public
        onlyOwner
    {
        _artistAddress = artist;
    }

    /**
     * Set burner address.
     */
    function setBurnerAddress(address burner)
        public
        onlyOwner
    {
        _burnerAddress = burner;
    }

    /**
     * Enable public minting.
     */
    function enablePublicMint()
        public
        onlyOwner
    {
        publicLive = true;
    }

    /**
     * Lock contract.  Disable public/member minting.
     *  Disallow on-chain code/library updates.
     */
    function lockContract()
        public
        onlyOwner
    {
        _locked = true;
    }

    /**
     * Validate hash contains input data.
     */
    function validateHash(bytes32 msgHash, address sender, uint256 allocation, uint256 count, string memory nonce)
        private
        pure
        returns(bool)
    {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(sender, allocation, count, nonce)))) == msgHash;
    }

    /**
     * Validate message was signed by signer.
     */
    function validateSigner(bytes32 msgHash, bytes memory signature)
        private
        pure
        returns(bool)
    {
        return msgHash.recover(signature) == _signer;
    }

    /**
     * Allow anyone to mint tokens for the right price.
     */
    function mint()
        payable
        public
        notLocked
    {
        require(publicLive, "public mint not live");
        require(publicPrice == msg.value, "insufficient funds");
        require(totalSupply() < tokenMax, "exceed token supply");
        require(publicMinted < publicMax, "exceed public supply");
        ++publicMinted;
        _mintTo(msg.sender);
    }

    /**
     * @dev Mints a token to an address.
     * @param _to address of the future owner of the token
     */
    function galleryMintTo(address _to, uint256 count)
        external
        onlyOwner
    {
        require(totalSupply() + count <= tokenMax, "exceed token supply");
        require(galleryMinted + count <= galleryMax, "exceed gallery supply");
        galleryMinted += count;
        for (uint256 i = 0; i < count; ++i) {
            _mintTo(_to);
        }
    }

    /**
     * @dev Mints a token to an address.
     * @param _to address of the future owner of the token
     */
    function artistMintTo(address _to, uint256 count)
        external
        isArtist
    {
        require(totalSupply() + count <= tokenMax, "exceed token supply");
        require(artistMinted + count <= artistMax, "exceed artist supply");
        artistMinted += count;
        for (uint256 i = 0; i < count; ++i) {
            _mintTo(_to);
        }
    }

    /**
     * Mint count tokens using securely signed message.
     */
    function secureMint(bytes32 msgHash, bytes memory signature, uint256 allocation, uint256 count, string memory nonce)
        payable
        external
        notLocked
    {
        require(memberPrice * count == msg.value, "insufficient funds");
        require(!_usedNonces[nonce], "invalid nonce");
        require(totalSupply() < tokenMax, "all tokens minted");
        require(totalSupply() + count <= tokenMax, "exceed token supply");
        require(publicMinted + count <= publicMax, "exceed public supply");
        require(_mints[msg.sender] + count <= allocation, "exceed allocation");
        require(validateSigner(msgHash, signature), "invalid signer");
        require(validateHash(msgHash, msg.sender, allocation, count, nonce), "invalid hash");
        publicMinted += count;
        _mints[msg.sender] += count;
        _usedNonces[nonce] = true;
        for (uint256 i = 0; i < count; ++i) {
            _mintTo(msg.sender);
        }
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     */
    function burn(uint256 tokenId)
        public
        isBurner
    {
        _burn(tokenId);
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function _mintTo(address _to)
        internal
    {
        uint256 newTokenId = totalSupply() + 1;
        _safeMint(_to, newTokenId);
        _hash[newTokenId] = _randomHash(_to, newTokenId);
    }

    function baseTokenURI()
        virtual
        public
        view
        returns (string memory);

    /**
     * @dev Returns uri of a token.  Not guarenteed token exists.
     */
    function tokenURI(uint256 tokenId)
        override
        public
        view
        returns (string memory)
    {
        return string(abi.encodePacked(baseTokenURI(), "/", Strings.toString(tokenId), "/meta"));
    }

    /**
     * @return randomly generated hash associated with valid a token.
     */
    function tokenHash(uint256 tokenId)
        public
        view
        validTokenId(tokenId)
        returns (bytes32)
    {
        return _hash[tokenId];
    }

    /**
     * Pull money out of this contract.
     */
    function withdraw(address to, uint256 amount)
        public
        onlyOwner
    {
        require(amount > 0, "amount empty");
        require(amount <= address(this).balance, "amount exceeds balance");
        require(to != address(0), "address null");
        payable(to).transfer(amount);
    }

    /**
     * @dev Pseudo-random number generator.
     */
    function _randomHash(address _to, uint256 tokenId)
        internal
        returns (bytes32)
    {
      bytes32 hash = keccak256(
          abi.encodePacked(
              blockhash(block.number - 1),
              msg.sender,
              _seed,
              tokenId,
              _to));
      _seed = uint256(hash);
      return hash;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts
     *  to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by
     *  the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }

}