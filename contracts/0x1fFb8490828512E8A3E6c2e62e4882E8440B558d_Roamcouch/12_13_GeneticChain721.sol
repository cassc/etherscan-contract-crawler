// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//------------------------------------------------------------------------------
// Roamcouch | Graffiti Kimono Collection
//------------------------------------------------------------------------------
// Author: papaver (@tronicdreams)
//------------------------------------------------------------------------------

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";

//------------------------------------------------------------------------------
// GeneticChain721
//------------------------------------------------------------------------------

/**
 * @title GeneticChain721
 */
abstract contract GeneticChain721 is
    ERC721,
    Ownable
{
    using ECDSA for bytes32;

    //-------------------------------------------------------------------------
    // constants
    //-------------------------------------------------------------------------

    // erc721 metadata
    string constant private __name   = "Roamcouch Graffiti Kimono";
    string constant private __symbol = "KIMONO";

    // mint info
    uint256 constant public _maxSupply = 115;

    // verification wallet
    address constant private _signer = 0xA1A02a3A32B31C065FFf50d8ac7770B6e0CbB343;

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

    constructor()
        ERC721(__name, __symbol)
    {
    }

    //-------------------------------------------------------------------------
    // accessors
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

}