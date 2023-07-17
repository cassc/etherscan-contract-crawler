// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//------------------------------------------------------------------------------
// Jerkface Genesis Collection
//------------------------------------------------------------------------------
// Author: papaver (@tronicdreams)
//------------------------------------------------------------------------------

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";

import "./libraries/State.sol";

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
    using State for State.Data;

    //-------------------------------------------------------------------------
    // constants
    //-------------------------------------------------------------------------


    // erc721 metadata
    string constant private __name   = "Jerkface Genesis";
    string constant private __symbol = "JERKFACE";

    // mint info
    uint256 constant public _tokenOffset = 100;

    // verification address
    address constant private _signer = 0xa98673D426BCf78eA72aeF978F2cFF756d941d2A;

    //-------------------------------------------------------------------------
    // fields
    //-------------------------------------------------------------------------

    // mint data
    uint64[4] public tokenPrice;

    // contract state
    State.Data private _state;

    // track mint count per address
    mapping (address => uint8) private _minted;

    // roles
    mapping (address => bool) private _burnerAddress;

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

    modifier notLocked() {
        require(!_state.locked(), "contract locked");
        _;
    }

    //-------------------------------------------------------------------------

    modifier isBurner() {
        require(_burnerAddress[_msgSender()], "caller not burner");
        _;
    }

    //-------------------------------------------------------------------------
    // ctor
    //-------------------------------------------------------------------------

    constructor(
        uint16[4] memory pmax,
        uint16[4] memory max)
        ERC721(__name, __symbol)
    {
        // 0 - mr. sparklechu
        // 1 - mr. sparklechu - variant
        // 2 - homerbob
        // 3 - homerbob - variant
        tokenPrice[0] = 1 ether;
        tokenPrice[1] = 2 ether;
        tokenPrice[2] = 1 ether;
        tokenPrice[3] = 2 ether;

        // setup state with token mint limits
        _state.initialize(pmax, max);
    }

    //-------------------------------------------------------------------------
    // accessors
    //-------------------------------------------------------------------------

    /**
     * Get variant price.
     */
    function price(uint256 variantId)
        public view returns (uint256)
    {
        return tokenPrice[variantId];
    }

    //-------------------------------------------------------------------------

    /**
     * Get total minted.
     */
    function totalSupply()
        public view returns (uint256)
    {
        return _state.totalSupply();
    }

    //-------------------------------------------------------------------------

    /**
     * Get total minted of variant.
     */
    function variantSupply(uint256 variantId)
        public view returns (uint256)
    {
        return _state.getSupply(variantId);
    }

    //-------------------------------------------------------------------------

    /**
     * Get max supply allowed for variant.
     */
    function variantMax(uint256 variantId)
        public view returns (uint256)
    {
        return _state.getMax(variantId);
    }

    //-------------------------------------------------------------------------

    /**
     * Check if public minting is live.
     */
    function publicLive()
        public view returns (bool)
    {
        return _state.publicLive();
    }

    //-------------------------------------------------------------------------

    /**
     * Check if contract locked.
     */
    function locked()
        public view returns (bool)
    {
        return _state.locked();
    }

    //-------------------------------------------------------------------------

    /**
     * Enable public live.
     */
    function enablePublicLive()
        public onlyOwner
    {
        _state.enablePublicLive();
    }

    //-------------------------------------------------------------------------

    /**
     * Toggle locking contract..
     */
    function toggleLocked()
        public onlyOwner
    {
        _state.toggleLocked();
    }

    //-------------------------------------------------------------------------
    // admin
    //-------------------------------------------------------------------------

    /**
     * Authorize artist address.
     */
    function registerBurnerAddress(address burner)
        public onlyOwner
    {
        require(!_burnerAddress[burner], "address already registered");
        _burnerAddress[burner] = true;
    }

    //-------------------------------------------------------------------------

    /**
     * Remove burner address.
     */
    function revokeBurnerAddress(address burner)
        public onlyOwner
    {
        require(_burnerAddress[burner], "address not registered");
        delete _burnerAddress[burner];
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
     * Mint token using securely signed message.
     */
    function secureMint(
            uint256 variantId,
            bytes32 msgHash,
            bytes calldata signature,
            uint256 allocation,
            uint256 count)
        payable external notLocked
    {
        require(variantId < tokenPrice.length, "invalid variant");
        require(tokenPrice[variantId] * count == msg.value, "insufficient funds");
        require(_minted[msg.sender] + count <= allocation, "exceed allocation");
        require(validateSigner(msgHash, signature), "invalid signer");
        require(validateHash(msgHash, msg.sender, allocation, count), "invalid hash");

        // mark user minted
        _minted[msg.sender] += uint8(count);

        // get current token id
        uint256 tokenId = _tokenOffset * (variantId + 1)
            + _state._supply[variantId];

        // update variant supply
        _state.addSupply(variantId, count);

        // mint token
        for (uint256 i = 0; i < count; ++i) {
            _safeMint(msg.sender, tokenId + i);
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

}