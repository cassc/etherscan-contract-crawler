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
import "openzeppelin-solidity/contracts/utils/Strings.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";
import "./geneticchain/ERC721SequentialB.sol";
import "./geneticchain/ERC721SeqEnumerableB.sol";
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

/**
 * Burn baby burn.
 */
interface IBurnable {
  function burn(uint256 tokenId) external;
}

//------------------------------------------------------------------------------
// GeneticChain721
//------------------------------------------------------------------------------

/**
 * @title GeneticChain721
 *
 * ERC721 contract with various features:
 *  - lower-gas implmentation
 *  - low-gas generative token hash
 *  - opensea proxy setup
 *  - simple funds withdrawl
 */
abstract contract GeneticChain721 is
    ContextMixin,
    ERC721SeqEnumerableB,
    NativeMetaTransaction,
    Ownable
{
    using State for State.Data;

    //-------------------------------------------------------------------------
    // events
    //-------------------------------------------------------------------------

    // track original pass ids
    event MidnightAssemble(address indexed owner,
        uint256 tokenId, uint256 foundersId, uint256 chaingangId, uint256 geneticistsId);

    //-------------------------------------------------------------------------
    // fields
    //-------------------------------------------------------------------------

    // token data
    uint256 private immutable _seed;

    // opensea proxy
    address private immutable _proxyRegistryAddress;

    // card addresses
    address private immutable _founders;
    address private immutable _chaingang;
    address private immutable _geneticists;

    // contract state
    State.Data private _state;

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

    modifier isLive() {
        require(_state._live == 1, "minting not live");
        _;
    }

    //-------------------------------------------------------------------------

    modifier notLocked() {
        require(_state._locked == 0, "contract is locked");
        _;
    }

    //-------------------------------------------------------------------------

    modifier ownsPass(address pass, uint256 tokenId) {
        require(IERC721(pass).ownerOf(tokenId) == msg.sender, "invalid pass");
        _;
    }

    //-------------------------------------------------------------------------
    // ctor
    //-------------------------------------------------------------------------

    constructor(
        address[3] memory cards,
        uint256 seed,
        address proxyRegistryAddress)
        ERC721SequentialB("Midnight Runner Pass", "GCP7")
    {
        _founders             = cards[0];
        _chaingang            = cards[1];
        _geneticists          = cards[2];
        _seed                 = seed;
        _proxyRegistryAddress = proxyRegistryAddress;
        _initializeEIP712("Midnight Runner Pass");

        // start tokens at 1 index
        _owners.push();
    }

    //-------------------------------------------------------------------------
    // accessors
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
     * Check if public minting is live.
     */
    function publicLive()
        public view returns (bool)
    {
        return _state._live == 1;
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
    // minting
    //-------------------------------------------------------------------------

    /**
     * Upgrade Standard 3 passes to Elite.  Admin call.
     */
    function galleryMint(address to,
            uint256 foundersId, uint256 chaingangId, uint256 geneticistsId)
        external
        onlyOwner
        ownsPass(_founders, foundersId)
        ownsPass(_chaingang, chaingangId)
        ownsPass(_geneticists, geneticistsId)
    {
        // burn
        IBurnable(_founders).burn(foundersId);
        IBurnable(_chaingang).burn(chaingangId);
        IBurnable(_geneticists).burn(geneticistsId);

        // mint
        uint256 tokenId = _safeMint(to);

        // track original pass ids
        emit MidnightAssemble(to, tokenId,
            foundersId, chaingangId, geneticistsId);
    }

    //-------------------------------------------------------------------------

    /**
     * Upgrade Standard 3 passes to Elite.
     */
    function mint(uint256 foundersId, uint256 chaingangId, uint256 geneticistsId)
        external
        isLive
        notLocked
        ownsPass(_founders, foundersId)
        ownsPass(_chaingang, chaingangId)
        ownsPass(_geneticists, geneticistsId)
    {
        // burn
        IBurnable(_founders).burn(foundersId);
        IBurnable(_chaingang).burn(chaingangId);
        IBurnable(_geneticists).burn(geneticistsId);

        // mint
        uint256 tokenId = _safeMint(msg.sender);

        // track original pass ids
        emit MidnightAssemble(msg.sender, tokenId,
            foundersId, chaingangId, geneticistsId);
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