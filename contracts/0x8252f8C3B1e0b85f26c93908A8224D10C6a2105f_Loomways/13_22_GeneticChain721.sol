// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//------------------------------------------------------------------------------
// geneticchain.io - NextGen Generative NFT Platform
//------------------------------------------------------------------------------
//    _______                   __   __        ______ __          __
//   |     __|-----.-----.-----|  |_|__|----. |      |  |--.---.-|__|-----.
//   |    |  |  -__|     |  -__|   _|  |  __| |   ---|     |  _  |  |     |
//   |_______|_____|__|__|_____|____|__|____| |______|__|__|___._|__|__|__|
//
//------------------------------------------------------------------------------
// Genetic Chain: GeneticChain721
//------------------------------------------------------------------------------
// Author: papaver (@tronicdreams)
//------------------------------------------------------------------------------

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";
import "./geneticchain/ERC721Sequencial.sol";
import "./geneticchain/ERC721SeqEnumerable.sol";
import "./libraries/State.sol";

//------------------------------------------------------------------------------
// helper contracts
//------------------------------------------------------------------------------

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

//------------------------------------------------------------------------------
// GeneticChain721
//------------------------------------------------------------------------------

/**
 * @title GeneticChain721
 *
 * ERC721 contract with various features:
 *  - low-gas implmentation
 *  - off-chain whitelist verify (secure minting)
 *  - dynamic token allocation
 *  - artist allocation
 *  - gallery allocation
 *  - low-gas generative token hash
 *  - protected controlled burns
 *  - opensea proxy setup
 *  - simple funds withdrawl
 */
abstract contract GeneticChain721 is
    ContextMixin,
    ERC721SeqEnumerable,
    NativeMetaTransaction,
    Ownable
{
    using ECDSA for bytes32;
    using State for State.Data;

    //-------------------------------------------------------------------------
    // fields
    //-------------------------------------------------------------------------

    // mint price (0.03 / 0.05)
    uint256 constant public memberPrice = 30000000000000000;
    uint256 constant public publicPrice = 50000000000000000;

    // verification address
    address constant private _signer = 0x11CD1d96F4F215E7240E8072535bA85dDaaB2A09;

    // token limits
    uint256 public immutable publicMax;
    uint256 public immutable artistMax;
    uint256 public immutable galleryMax;

    // token data
    uint256 private immutable _seed;

    // opensea proxy
    address private immutable _proxyRegistryAddress;

    // token limits
    State.Data private _state;

    // roles
    address private _burnerAddress;
    address private _artistAddress = 0xDA9e8026FbDe7D44d7E9268d6e2efd76033a49c7;

    // track mint count per address
    mapping (address => uint256) private _mints;

    //-------------------------------------------------------------------------
    // modifiers
    //-------------------------------------------------------------------------

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
        require(_state._locked == 0, "contract is locked");
        _;
    }

    //-------------------------------------------------------------------------
    // ctor
    //-------------------------------------------------------------------------

    constructor(
        uint256[3] memory tokenMax_,
        uint256 seed,
        address proxyRegistryAddress)
        ERC721Sequencial("Loomways", "GCP6")
    {
        publicMax             = tokenMax_[0];
        artistMax             = tokenMax_[1];
        galleryMax            = tokenMax_[2];
        _seed                 = seed;
        _proxyRegistryAddress = proxyRegistryAddress;
        _initializeEIP712("Loomways");

        // start tokens at 1 index
        _owners.push();
    }

    //-------------------------------------------------------------------------
    // accessors
    //-------------------------------------------------------------------------

    /**
     * Set artist address.
     */
    function setArtistAddress(address artist)
        public onlyOwner
    {
        _artistAddress = artist;
    }

    //-------------------------------------------------------------------------

    /**
     * Set burner address.
     */
    function setBurnerAddress(address burner)
        public onlyOwner
    {
        _burnerAddress = burner;
    }

    //-------------------------------------------------------------------------

    /**
     * Enable public minting.
     */
    function enablePublicMint()
        public onlyOwner
    {
        _state.setLive(1);
    }

    //-------------------------------------------------------------------------

    /**
     * Lock contract.  Disable public/member minting. Disallow on-chain
     *  code/library updates.
     */
    function lockContract()
        public onlyOwner
    {
        _state.setLocked(1);
    }

    //-------------------------------------------------------------------------

    /**
     * Get total gallery has minted.
     */
    function gallryMinted()
        public view returns (uint256)
    {
        return _state._gallery;
    }

    //-------------------------------------------------------------------------

    /**
     * Get total artist has minted.
     */
    function artistMinted()
        public view returns (uint256)
    {
        return _state._artist;
    }

    //-------------------------------------------------------------------------

    /**
     * Get total public has minted.
     */
    function publicMinted()
        public view returns (uint256)
    {
        return _state._public;
    }

    //-------------------------------------------------------------------------

    /**
     * Check if public minting is live.
     */
    function publicLive()
        public view returns (bool)
    {
        return _state._live == 1;
    }

    //-------------------------------------------------------------------------
    // security
    //-------------------------------------------------------------------------

    /**
     * Validate hash contains input data.
     */
    function validateHash(
            bytes32 msgHash,
            address sender,
            uint256 allocation,
            uint256 count)
        private pure returns(bool)
    {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(sender, allocation, count)))) == msgHash;
    }

    //-------------------------------------------------------------------------

    /**
     * Validate message was signed by signer.
     */
    function validateSigner(bytes32 msgHash, bytes memory signature)
        private pure returns(bool)
    {
        return msgHash.recover(signature) == _signer;
    }

    //-------------------------------------------------------------------------
    // minting
    //-------------------------------------------------------------------------

    /**
     * Allow anyone to mint tokens for the right price.
     */
    function mint(uint256 count)
        payable public notLocked
    {
        require(_state._live == 1, "public mint not live");
        require(publicPrice * count == msg.value, "insufficient funds");
        require(_state._public + count <= publicMax, "exceed public supply");
        _state.addPublic(count);
        for (uint256 i = 0; i < count; ++i) {
            _safeMint(msg.sender);
        }
    }

    //-------------------------------------------------------------------------

    /**
     * Mint count tokens using securely signed message.
     */
    function secureMint(
            bytes32 msgHash,
            bytes calldata signature,
            uint256 allocation,
            uint256 count)
        payable external notLocked
    {
        require(memberPrice * count == msg.value, "insufficient funds");
        require(_state._public + count <= publicMax, "exceed public supply");
        require(_mints[msg.sender] + count <= allocation, "exceed allocation");
        require(validateSigner(msgHash, signature), "invalid signer");
        require(validateHash(msgHash, msg.sender, allocation, count), "invalid hash");
        _state.addPublic(count);
        unchecked {
            _mints[msg.sender] += count;
        }
        for (uint256 i = 0; i < count; ++i) {
            _safeMint(msg.sender);
        }
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Mints a token to an address.
     * @param _to address of the future owner of the token
     */
    function galleryMintTo(address _to, uint256 count)
        public onlyOwner
    {
        require(_state._gallery + count <= galleryMax, "exceed gallery supply");
        _state.addGallery(count);
        for (uint256 i = 0; i < count; ++i) {
            _safeMint(_to);
        }
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Mints a token to an address.
     * @param _to address of the future owner of the token
     */
    function artistMintTo(address _to, uint256 count)
        public isArtist
    {
        require(_state._artist + count <= artistMax, "exceed artist supply");
        _state.addArtist(count);
        for (uint256 i = 0; i < count; ++i) {
            _safeMint(_to);
        }
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     */
    function burn(uint256 tokenId)
        public isBurner
    {
        _burn(tokenId);
    }

    //-------------------------------------------------------------------------
    // ERC721Metadata
    //-------------------------------------------------------------------------

    function baseTokenURI()
        virtual public view returns (string memory);

    //-------------------------------------------------------------------------

    /**
     * @dev Returns uri of a token.  Not guarenteed token exists.
     */
    function tokenURI(uint256 tokenId)
        override public view returns (string memory)
    {
        return string(abi.encodePacked(
            baseTokenURI(), "/", Strings.toString(tokenId), "/meta"));
    }

    //-------------------------------------------------------------------------
    // generative
    //-------------------------------------------------------------------------

    /**
     * @dev Low-Gas alternative to storing the hash on the chain.
     * @return generated hash associated with valid a token.
     */
    function tokenHash(uint256 tokenId)
        public view validTokenId(tokenId) returns (bytes32)
    {
      return keccak256(
          abi.encodePacked(
              _seed,
              tokenId,
              address(this)));
    }

    //-------------------------------------------------------------------------
    // money
    //-------------------------------------------------------------------------

    /**
     * Pull money out of this contract.
     */
    function withdraw(address to, uint256 amount)
        public onlyOwner
    {
        require(amount > 0, "amount empty");
        require(amount <= address(this).balance, "amount exceeds balance");
        require(to != address(0), "address null");
        payable(to).transfer(amount);
    }

    //-------------------------------------------------------------------------
    // approval
    //-------------------------------------------------------------------------

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts
     *  to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override public view returns (bool)
    {
        // whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    //-------------------------------------------------------------------------

    /**
     * This is used instead of msg.sender as transactions won't be sent by
     *  the original token owner, but by OpenSea.
     */
    function _msgSender()
        override internal view returns (address sender)
    {
        return ContextMixin.msgSender();
    }

}