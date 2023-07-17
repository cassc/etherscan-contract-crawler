// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//------------------------------------------------------------------------------
// geneticchain.io - NextGen Generative NFT Platform
//------------------------------------------------------------------------------
//________________________________________________________________   .¿yy¿.   __
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM```````/MMM\\\\\  \\$$$$$$S/  .
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM``   `/  yyyy    ` _____J$$$*^^*/%#//
//MMMMMMMMMMMMMMMMMMMYYYMMM````      `\/  .¿yü  /  $ùpüüü%%% | ``|//|` __
//MMMMMYYYYMMMMMMM/`     `| ___.¿yüy¿.  .d$$$$  /  $$$$SSSSM |   | ||  MMNNNNNNM
//M/``      ``\/`  .¿ù%%/.  |.d$$$$$$$b.$$$*°^  /  o$$$  __  |   | ||  MMMMMMMMM
//M   .¿yy¿.     .dX$$$$$$7.|$$$$"^"$$$$$$o`  /MM  o$$$  MM  |   | ||  MMYYYYYYM
//  \\$$$$$$S/  .S$$o"^"4$$$$$$$` _ `SSSSS\        ____  MM  |___|_||  MM  ____
// J$$$*^^*/%#//oSSS`    YSSSSSS  /  pyyyüüü%%%XXXÙ$$$$  MM  pyyyyyyy, `` ,$$$o
//.$$$` ___     pyyyyyyyyyyyy//+  /  $$$$$$SSSSSSSÙM$$$. `` .S&&T$T$$$byyd$$$$\
//\$$7  ``     //o$$SSXMMSSSS  |  /  $$/&&X  _  ___ %$$$byyd$$$X\$`/S$$$$$$$S\
//o$$l   .\\YS$$X>$X  _  ___|  |  /  $$/%$$b.,.d$$$\`7$$$$$$$$7`.$   `"***"`  __
//o$$l  __  7$$$X>$$b.,.d$$$\  |  /  $$.`7$$$$$$$$%`  `*+SX+*|_\\$  /.     ..\MM
//o$$L  MM  !$$$$\$$$$$$$$$%|__|  /  $$// `*+XX*\'`  `____           ` `/MMMMMMM
///$$X, `` ,S$$$$\ `*+XX*\'`____  /  %SXX .      .,   NERV   ___.¿yüy¿.   /MMMMM
// 7$$$byyd$$$>$X\  .,,_    $$$$  `    ___ .y%%ü¿.  _______  $.d$$$$$$$S.  `MMMM
// `/S$$$$$$$\\$J`.\\$$$ :  $\`.¿yüy¿. `\\  $$$$$$S.//XXSSo  $$$$$"^"$$$$.  /MMM
//y   `"**"`"Xo$7J$$$$$\    $.d$$$$$$$b.    ^``/$$$$.`$$$$o  $$$$\ _ 'SSSo  /MMM
//M/.__   .,\Y$$$\\$$O` _/  $d$$$*°\ pyyyüüü%%%W $$$o.$$$$/  S$$$. `  S$To   MMM
//MMMM`  \$P*$$X+ b$$l  MM  $$$$` _  $$$$$$SSSSM $$$X.$T&&X  o$$$. `  S$To   MMM
//MMMX`  $<.\X\` -X$$l  MM  $$$$  /  $$/&&X      X$$$/$/X$$dyS$$>. `  S$X%/  `MM
//MMMM/   `"`  . -$$$l  MM  yyyy  /  $$/%$$b.__.d$$$$/$.'7$$$$$$$. `  %SXXX.  MM
//MMMMM//   ./M  .<$$S, `` ,S$$>  /  $$.`7$$$$$$$$$$$/S//_'*+%%XX\ `._       /MM
//MMMMMMMMMMMMM\  /$$$$byyd$$$$\  /  $$// `*+XX+*XXXX      ,.      .\MMMMMMMMMMM
//GENETIC/MMMMM\.  /$$$$$$$$$$\|  /  %SXX  ,_  .      .\MMMMMMMMMMMMMMMMMMMMMMMM
//CHAIN/MMMMMMMM/__  `*+YY+*`_\|  /_______//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
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

    // erc721 metadata
    string constant private __name   = "Tiny Ghost Genesis";
    string constant private __symbol = "TINYGHOST";

    // metadata
    uint256 constant public projectId  = 9;
    string constant public artist      = "Reis O'Brien";
    string constant public description = "Collection of 666 unique Tiny Ghost NFTs.";

    // mint price
    uint256 constant public memberPrice = .05 ether;
    uint256 constant public publicPrice = .05 ether;

    // verification address
    address constant private _signer = 0xf0f137b3f4b6862d5ef02C4dAC6264DDbC110528;

    // token limits
    uint256 public immutable publicMax;
    uint256 public immutable artistMax;
    uint256 public immutable galleryMax;

    // opensea proxy
    address private immutable _proxyRegistryAddress;

    // contract state
    State.Data private _state;

    // roles
    address private _burnerAddress;
    address private _artistAddress = 0x00f630965f882298219edBB1B96e0409EC6C8698;

    // track mint count per address
    mapping (address => uint256) private _mints;

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
        require(_msgSender() == _artistAddress, "caller not artist");
        _;
    }

    //-------------------------------------------------------------------------

    modifier isBurner() {
        require(_msgSender() == _burnerAddress, "caller not burner");
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
        uint256[3] memory tokenMax_,
        address proxyRegistryAddress)
        ERC721Sequential(__name, __symbol)
    {
        publicMax             = tokenMax_[0];
        artistMax             = tokenMax_[1];
        galleryMax            = tokenMax_[2];
        _proxyRegistryAddress = proxyRegistryAddress;
        _initializeEIP712(__name);

        // start tokens at 1 index
        _owners.push();
    }

    //-------------------------------------------------------------------------
    // accessors
    //-------------------------------------------------------------------------

    /**
     * Set artist address.
     */
    function setArtistAddress(address artistAddress)
        public onlyOwner
    {
        _artistAddress = artistAddress;
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
     * Check if public minting is live.
     */
    function publicLive()
        public view returns (bool)
    {
        return _state._live == 1;
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
     * Check if contract is locked.
     */
    function isLocked()
        public view returns (bool)
    {
        return _state._locked == 1;
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
        return ECDSA.toEthSignedMessageHash(
            keccak256(abi.encodePacked(sender, allocation, count))) == msgHash;
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
        override internal view returns (address sender)
    {
        return ContextMixin.msgSender();
    }

}