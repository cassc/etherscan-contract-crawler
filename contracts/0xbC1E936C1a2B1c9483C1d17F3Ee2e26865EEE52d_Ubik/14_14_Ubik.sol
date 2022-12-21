// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//-----------------------------------------------------------------------------
// geneticchain.io - NextGen Generative NFT Platform
//-----------------------------------------------------------------------------
 /*\_____________________________________________________________   .¿yy¿.   __
 MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM```````/MMM\\\\\  \\$$$$$$S/  .
 MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM``   `/  yyyy    ` _____J$$$^^^^/%#//
 MMMMMMMMMMMMMMMMMMMYYYMMM````      `\/  .¿yü  /  $ùpüüü%%% | ``|//|` __
 MMMMMYYYYMMMMMMM/`     `| ___.¿yüy¿.  .d$$$$  /  $$$$SSSSM |   | ||  MMNNNNNNM
 M/``      ``\/`  .¿ù%%/.  |.d$$$$$$$b.$$$*°^  /  o$$$  __  |   | ||  MMMMMMMMM
 M   .¿yy¿.     .dX$$$$$$7.|$$$$"^"$$$$$$o`  /MM  o$$$  MM  |   | ||  MMYYYYYYM
   \\$$$$$$S/  .S$$o"^"4$$$$$$$` _ `SSSSS\        ____  MM  |___|_||  MM  ____
  J$$$^^^^/%#//oSSS`    YSSSSSS  /  pyyyüüü%%%XXXÙ$$$$  MM  pyyyyyyy, `` ,$$$o
 .$$$` ___     pyyyyyyyyyyyy//+  /  $$$$$$SSSSSSSÙM$$$. `` .S&&T$T$$$byyd$$$$\
 \$$7  ``     //o$$SSXMMSSSS  |  /  $$/&&X  _  ___ %$$$byyd$$$X\$`/S$$$$$$$S\
 o$$l   .\\YS$$X>$X  _  ___|  |  /  $$/%$$b.,.d$$$\`7$$$$$$$$7`.$   `"***"`  __
 o$$l  __  7$$$X>$$b.,.d$$$\  |  /  $$.`7$$$$$$$$%`  `*+SX+*|_\\$  /.     ..\MM
 o$$L  MM  !$$$$\$$$$$$$$$%|__|  /  $$// `*+XX*\'`  `____           ` `/MMMMMMM
 /$$X, `` ,S$$$$\ `*+XX*\'`____  /  %SXX .      .,   NERV   ___.¿yüy¿.   /MMMMM
  7$$$byyd$$$>$X\  .,,_    $$$$  `    ___ .y%%ü¿.  _______  $.d$$$$$$$S.  `MMMM
  `/S$$$$$$$\\$J`.\\$$$ :  $\`.¿yüy¿. `\\  $$$$$$S.//XXSSo  $$$$$"^"$$$$.  /MMM
 y   `"**"`"Xo$7J$$$$$\    $.d$$$$$$$b.    ^``/$$$$.`$$$$o  $$$$\ _ 'SSSo  /MMM
 M/.__   .,\Y$$$\\$$O` _/  $d$$$*°\ pyyyüüü%%%W $$$o.$$$$/  S$$$. `  S$To   MMM
 MMMM`  \$P*$$X+ b$$l  MM  $$$$` _  $$$$$$SSSSM $$$X.$T&&X  o$$$. `  S$To   MMM
 MMMX`  $<.\X\` -X$$l  MM  $$$$  /  $$/&&X      X$$$/$/X$$dyS$$>. `  S$X%/  `MM
 MMMM/   `"`  . -$$$l  MM  yyyy  /  $$/%$$b.__.d$$$$/$.'7$$$$$$$. `  %SXXX.  MM
 MMMMM//   ./M  .<$$S, `` ,S$$>  /  $$.`7$$$$$$$$$$$/S//_'*+%%XX\ `._       /MM
 MMMMMMMMMMMMM\  /$$$$byyd$$$$\  /  $$// `*+XX+*XXXX      ,.      .\MMMMMMMMMMM
 GENETIC/MMMMM\.  /$$$$$$$$$$\|  /  %SXX  ,_  .      .\MMMMMMMMMMMMMMMMMMMMMMMM
 CHAIN/MMMMMMMM/__  `*+YY+*`_\|  /_______//MMMMMMMMMMMMMMMMMMMMMMMMMMM/-/-/-\*/
//-----------------------------------------------------------------------------
// Genetic Chain: Ubik | Transformation
//-----------------------------------------------------------------------------
// Author: papaver (@papaver42)
//-----------------------------------------------------------------------------

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

//------------------------------------------------------------------------------
// Ubik - Transformation
//------------------------------------------------------------------------------

/**
 * @title GeneticChain - Project #18 - Ubik | Transformation
 */
contract Ubik is
    ERC721,
    ERC2981,
    Ownable
{
    using ECDSA for bytes32;

    //-------------------------------------------------------------------------
    // constants
    //-------------------------------------------------------------------------

    // erc721 metadata
    string constant private __name   = "Ubik Transformation";
    string constant private __symbol = "TRANSFORMATION";

    // mint info
    uint256 constant public _maxSupply = 100;

    // verification wallet
    address constant private _signer = 0xA1e0010fa4D3BeE4061c46E535Ca3F00Ba73Fc35;

    // contract info
    string private _contractUri;

    // token info
    string private _baseUri;
    string private _tokenIpfsHash;

    // mint info
    uint256 private _totalSupply;

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
    // ctor
    //-------------------------------------------------------------------------

    constructor(
        string memory baseUri_,
        string memory ipfsHash_,
        string memory contractUri_,
        address royaltyAddress)
        ERC721(__name, __symbol)
    {
        _baseUri       = baseUri_;
        _tokenIpfsHash = ipfsHash_;
        _contractUri   = contractUri_;

        // royalty
        _setDefaultRoyalty(royaltyAddress, 1000);
    }

    //-------------------------------------------------------------------------
    // accessors
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

    /**
     * Get total minted.
     */
    function totalSupply()
        public view
        returns (uint256)
    {
        return _totalSupply;
    }

    //-------------------------------------------------------------------------

    /**
     * Get max supply allowed.
     */
    function maxSupply()
        public pure
        returns (uint256)
    {
        return _maxSupply;
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
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    //-------------------------------------------------------------------------
    // ERC721Metadata
    //-------------------------------------------------------------------------

    function baseTokenURI()
        public
        view
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
        public
        view
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
    // security
    //-------------------------------------------------------------------------

    /**
     * Generate hash from input data.
     */
    function generateHash(uint256 tokenId, uint256 redeem)
        private view
        returns(bytes32)
    {
        return ECDSA.toEthSignedMessageHash(
            keccak256(abi.encodePacked(address(this), msg.sender, tokenId, redeem)));
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
     * Mint token using securely signed message.
     */
    function secureMint(
            bytes calldata signature,
            uint256 tokenId,
            uint256 redeemCode)
        external
    {
        bytes32 msgHash = generateHash(tokenId, redeemCode);
        require(!_exists(tokenId), "token minted");
        require(0 < tokenId && tokenId <= _maxSupply, "invalid token");
        require(validateSigner(msgHash, signature, _signer), "invalid sig");

        // track supply
        unchecked {
          _totalSupply += 1;
        }

        // mint token
        _safeMint(msg.sender, tokenId);
    }

    //-------------------------------------------------------------------------
    // contractUri
    //-------------------------------------------------------------------------

    function setContractURI(string memory contractUri)
        external onlyOwner
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