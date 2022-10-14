// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//------------------------------------------------------------------------------
// Dall-E Punks - Dunkz
//------------------------------------------------------------------------------
// Author: papaver (@papaver42)
//------------------------------------------------------------------------------

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";
import "./geneticchain/ERC721Sequential.sol";
import "./geneticchain/ERC721SeqEnumerable.sol";
import "./libraries/State.sol";

//------------------------------------------------------------------------------
// helper contracts
//------------------------------------------------------------------------------

contract OwnableDelegateProxy {}

//------------------------------------------------------------------------------

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

//------------------------------------------------------------------------------
// Dunkz721
//------------------------------------------------------------------------------

/**
 * @title Dunkz
 *
 * ERC721 contract with various features:
 *  - low-gas implmentation
 *  - off-chain whitelist verify (secure minting)
 *  - public/artist/team token allocation
 *  - protected controlled burns
 *  - opensea proxy setup
 *  - simple funds withdrawl
 */
contract Dunkz is
    ContextMixin,
    ERC721SeqEnumerable,
    ERC2981,
    NativeMetaTransaction,
    Ownable
{
    using ECDSA for bytes32;
    using State for State.Data;

    //-------------------------------------------------------------------------
    // structs
    //-------------------------------------------------------------------------

    struct Minted {
        uint128 claim;
        uint128 mint;
    }

    //-------------------------------------------------------------------------
    // constants
    //-------------------------------------------------------------------------

    // erc721 metadata
    string constant private __name   = "Dall-E Punks";
    string constant private __symbol = "DUNKZ";

    // mint price
    uint256 constant public memberPrice = .01 ether;
    uint256 constant public publicPrice = .02 ether;

    // allocations
    uint256 constant public maxPublic = 5;

    // artist wallets
    address constant private _ataraAddress      = 0xceC15d87719feDEcA61F7d11D2d205a4C0628517;
    address constant private _papaverAddress    = 0xa7B8a64dF4e47013C8A168945c9eb4F83BADC9C1;
    address constant private _noStandingAddress = 0x6A4f0ECbBb10dFdFD010F8E7B1C7e4a358692981;

    // verification address
    address constant private _signer = 0xE5cb964B8b21491929414b969078CcF7FeCD4725;

    // signature tags
    uint256 constant private _tagClaim  = 8118;
    uint256 constant private _tagMember = 4224;

    //-------------------------------------------------------------------------
    // fields
    //-------------------------------------------------------------------------

    // token limits
    uint256 public immutable publicMax;
    uint256 public immutable artistMax;
    uint256 public immutable teamMax;

    // opensea proxy
    address private immutable _proxyRegistryAddress;

    // contract state
    State.Data private _state;

    // roles
    mapping (address => bool) private _burnerAddress;
    mapping (address => bool) private _artistAddress;
    mapping (address => bool) private _teamAddress;

    // track mint count per address
    mapping (address => Minted) private _minted;

    // token info
    string private _baseUri;
    string private _tokenIpfsHash;

    // contract info
    string private _contractUri;

    //-------------------------------------------------------------------------
    // modifiers
    //-------------------------------------------------------------------------

    modifier validTokenId(uint256 tokenId) {
        require(_exists(tokenId), "invalid token");
        _;
    }

    //-------------------------------------------------------------------------

    modifier approvedOrOwner(address operator, uint256 tokenId) {
        require(_isApprovedOrOwner(operator, tokenId));
        _;
    }

    //-------------------------------------------------------------------------

    modifier isArtist() {
        require(_artistAddress[_msgSender()], "caller not artist");
        _;
    }

    //-------------------------------------------------------------------------

    modifier isTeam() {
        require(_teamAddress[_msgSender()] || owner() == _msgSender(), "caller not team");
        _;
    }

    //-------------------------------------------------------------------------

    modifier isBurner() {
        require(_burnerAddress[_msgSender()], "caller not burner");
        _;
    }

    //-------------------------------------------------------------------------

    modifier notLocked() {
        require(_state._locked == 0, "contract is locked");
        _;
    }

    //-------------------------------------------------------------------------
    // ctor
    //-------------------------------------------------------------------------

    constructor(
        string memory baseUri_,
        string memory ipfsHash_,
        string memory contractUri_,
        uint256[3] memory tokenMax_,
        address royaltyAddress,
        address proxyRegistryAddress)
        ERC721Sequential(__name, __symbol)
    {
        // collection link
        _baseUri       = baseUri_;
        _tokenIpfsHash = ipfsHash_;
        _contractUri   = contractUri_;

        // allocations
        publicMax  = tokenMax_[0];
        artistMax  = tokenMax_[1];
        teamMax    = tokenMax_[2];

        // os gas free listings
        _proxyRegistryAddress = proxyRegistryAddress;
        _initializeEIP712(__name);

        // royalty
        _setDefaultRoyalty(royaltyAddress, 750);

        // register wallets
        registerArtistAddress(_ataraAddress);
        registerArtistAddress(_papaverAddress);
        registerTeamAddress(_noStandingAddress);
    }

    //-------------------------------------------------------------------------
    // accessors
    //-------------------------------------------------------------------------

    /**
     * Check if public minting is live.
     */
    function publicLive()
        public view
        returns (bool)
    {
        return _state._live == 1;
    }

    //-------------------------------------------------------------------------

    /**
     * Check if contract is locked.
     */
    function isLocked()
        public view
        returns (bool)
    {
        return _state._locked == 1;
    }

    //-------------------------------------------------------------------------

    /**
     * Get total team has minted.
     */
    function teamMinted()
        public view
        returns (uint256)
    {
        return _state._team;
    }

    //-------------------------------------------------------------------------

    /**
     * Get total artist has minted.
     */
    function artistMinted()
        public view
        returns (uint256)
    {
        return _state._artist;
    }

    //-------------------------------------------------------------------------

    /**
     * Get total public has minted.
     */
    function publicMinted()
        public view
        returns (uint256)
    {
        return _state._public;
    }

    //-------------------------------------------------------------------------

    /**
     * Authorize artist wallet.
     */
    function registerArtistAddress(address artist)
        public
        onlyOwner
    {
        require(!_artistAddress[artist], "address already registered");
        _artistAddress[artist] = true;
    }

    //-------------------------------------------------------------------------

    /**
     * Remove artist wallet.
     */
    function revokeArtistAddress(address artist)
        public
        onlyOwner
    {
        require(_artistAddress[artist], "address not registered");
        delete _artistAddress[artist];
    }

    //-------------------------------------------------------------------------

    /**
     * Authorize team wallet.
     */
    function registerTeamAddress(address team)
        public
        onlyOwner
    {
        require(!_teamAddress[team], "address already registered");
        _teamAddress[team] = true;
    }

    //-------------------------------------------------------------------------

    /**
     * Remove team wallet.
     */
    function revokeTeamAddress(address team)
        public
        onlyOwner
    {
        require(_teamAddress[team], "address not registered");
        delete _teamAddress[team];
    }


    //-------------------------------------------------------------------------

    /**
     * Authorize burnder contract.
     */
    function registerBurnerAddress(address burner)
        public
        onlyOwner
    {
        require(!_burnerAddress[burner], "address already registered");
        _burnerAddress[burner] = true;
    }

    //-------------------------------------------------------------------------

    /**
     * Remove burner contract.
     */
    function revokeBurnerAddress(address burner)
        public
        onlyOwner
    {
        require(_burnerAddress[burner], "address not registered");
        delete _burnerAddress[burner];
    }

    //-------------------------------------------------------------------------

    function setTokenIpfsHash(string memory hash)
        public
        onlyOwner
    {
        if (bytes(hash).length == 0) {
            delete _tokenIpfsHash;
        } else {
            _tokenIpfsHash = hash;
        }
    }

    //-------------------------------------------------------------------------

    function setBaseTokenURI(string memory baseUri)
        public
        onlyOwner
    {
        _baseUri = baseUri;
    }

    //-------------------------------------------------------------------------

    function setTokenURI(string memory baseUri, string memory hash)
        public
        onlyOwner
    {
        setBaseTokenURI(baseUri);
        setTokenIpfsHash(hash);
    }

    //-------------------------------------------------------------------------
    // admin
    //-------------------------------------------------------------------------

    /**
     * Enable/disable public/member minting.
     */
    function toggleLock()
        public
        onlyOwner
    {
        _state.setLocked(_state._locked == 0 ? 1 : 0);
    }

    //-------------------------------------------------------------------------

    /**
     * Enable/disable public minting.
     */
    function togglePublicMint()
        public
        onlyOwner
    {
        _state.setLive(_state._live == 0 ? 1 : 0);
    }


    //-------------------------------------------------------------------------

    /**
     * Get minted info for a user.
     */
    function getMintInfo(address wallet)
        public view
        returns(Minted memory)
    {
        return _minted[wallet];
    }

    //-------------------------------------------------------------------------
    // security
    //-------------------------------------------------------------------------

    /**
     * Generate hash from input data.
     */
    function generateHash(uint256 tag, uint256 allocation, uint256 count)
        private view
        returns(bytes32)
    {
        return ECDSA.toEthSignedMessageHash(
            keccak256(abi.encodePacked(
                address(this), msg.sender, tag, allocation, count)));
    }

    //-------------------------------------------------------------------------

    /**
     * Validate message was signed by signer.
     */
    function validateSigner(bytes32 msgHash, bytes memory signature, address signer)
        private pure
        returns(bool)
    {
        return msgHash.recover(signature) == signer;
    }

    //-------------------------------------------------------------------------
    // minting
    //-------------------------------------------------------------------------

    /**
     * Allow anyone to mint tokens for the right price.
     */
    function mint(uint256 count)
        public payable
        notLocked
    {
        require(_state._live == 1, "public mint not live");
        require(publicPrice * count == msg.value, "insufficient funds");
        require(_state._public + count <= publicMax, "exceed public supply");
        require(_minted[msg.sender].mint + count <= maxPublic, "exceed allocation");
        _state.addPublic(count);
        unchecked {
            _minted[msg.sender].mint += uint128(count);
        }
        for (uint256 i = 0; i < count; ++i) {
            _safeMint(msg.sender);
        }
    }

    //-------------------------------------------------------------------------

    /**
     * Mint count tokens using securely signed message.
     */
    function secureMint(bytes calldata signature, uint256 allocation, uint256 count)
        external payable
        notLocked
    {
        bytes32 msgHash = generateHash(_tagMember, allocation, count);
        require(memberPrice * count == msg.value, "insufficient funds");
        require(_state._public + count <= publicMax, "exceed public supply");
        require(_minted[msg.sender].mint + count <= allocation, "exceed allocation");
        require(validateSigner(msgHash, signature, _signer), "invalid signer");
        _state.addPublic(count);
        unchecked {
            _minted[msg.sender].mint += uint128(count);
        }
        for (uint256 i = 0; i < count; ++i) {
            _safeMint(msg.sender);
        }
    }

    //-------------------------------------------------------------------------

    /**
     * Allow cryptopunk holders to claim.
     */
    function claim(bytes calldata signature, uint256 allocation, uint256 count)
        external
        notLocked
    {
        bytes32 msgHash = generateHash(_tagClaim, allocation, count);
        require(_state._public + count <= publicMax, "exceed public supply");
        require(_minted[msg.sender].claim + count <= allocation, "exceed allocation");
        require(validateSigner(msgHash, signature, _signer), "invalid signer");
        _state.addPublic(count);
        unchecked {
            _minted[msg.sender].claim += uint128(count);
        }
        for (uint256 i = 0; i < count; ++i) {
            _safeMint(msg.sender);
        }
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Mints a token to an address.
     * @param wallet address of the future owner of the token
     */
    function teamMintTo(address wallet, uint256 count)
        public
        isTeam
    {
        require(_state._team + count <= teamMax, "exceed team supply");
        _state.addTeam(count);
        for (uint256 i = 0; i < count; ++i) {
            _safeMint(wallet);
        }
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Mints a token to an address.
     * @param wallet address of the future owner of the token
     */
    function artistMintTo(address wallet, uint256 count)
        public
        isArtist
    {
        require(_state._artist + count <= artistMax, "exceed artist supply");
        _state.addArtist(count);
        for (uint256 i = 0; i < count; ++i) {
            _safeMint(wallet);
        }
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     */
    function burn(uint256 tokenId)
        public
        isBurner
    {
        _burn(tokenId);
    }

    //-------------------------------------------------------------------------
    // money
    //-------------------------------------------------------------------------

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

    //-------------------------------------------------------------------------
    // approval
    //-------------------------------------------------------------------------

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts
     *  to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override(ERC721Sequential, IERC721)
        public view
        returns (bool)
    {
        // whitelist OpenSea proxy contract for easy trading
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
        override
        internal view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }

    //-------------------------------------------------------------------------
    // ERC2981 - NFT Royalty Standard
    //-------------------------------------------------------------------------

    /**
     * @dev Update royalty receiver + basis points.
     */
    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    //-------------------------------------------------------------------------
    // IERC165 - Introspection
    //-------------------------------------------------------------------------

    function supportsInterface(bytes4 interfaceId)
        public view
        override(ERC721SeqEnumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    //-------------------------------------------------------------------------
    // ERC721Metadata
    //-------------------------------------------------------------------------

    function baseTokenURI()
        public view
        returns (string memory)
    {
        return _baseUri;
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Returns uri of a token.  Not guarenteed token exists.
     */
    function tokenURI(uint256 tokenId)
        override
        public view
        returns (string memory)
    {
        return bytes(_tokenIpfsHash).length == 0
            ? string(abi.encodePacked(
                baseTokenURI(), "/", Strings.toString(tokenId)))
            : string(abi.encodePacked(
                baseTokenURI(),
                    "/", _tokenIpfsHash,
                    "/", Strings.toString(tokenId)));
    }

    //-------------------------------------------------------------------------
    // OpenSea contractUri
    //-------------------------------------------------------------------------

    function setContractURI(string memory contractUri)
        external
        onlyOwner
    {
        _contractUri = contractUri;
    }

    //-------------------------------------------------------------------------

    function contractURI()
        public view
        returns (string memory)
    {
        return _contractUri;
    }


}