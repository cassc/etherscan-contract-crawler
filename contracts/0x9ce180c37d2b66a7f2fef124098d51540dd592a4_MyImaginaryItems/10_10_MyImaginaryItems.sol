// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//-----------------------------------------------------------------------------
// Author: papaver (@papaver42)
//-----------------------------------------------------------------------------

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

//------------------------------------------------------------------------------
// My Imaginary Items by Kai
//------------------------------------------------------------------------------

/**
 * @title My Imaginary Items by Kai
 */
contract MyImaginaryItems is ERC1155,
    Ownable
{

    //-------------------------------------------------------------------------
    // structs
    //-------------------------------------------------------------------------

    struct Token {
        uint128 totalSupply;
        int128 createdTS;
    }

    //-------------------------------------------------------------------------
    // events
    //-------------------------------------------------------------------------

    /**
     * Emited when a new token is created.
     */
    event TokenCreated(uint256 tokenId, int128 createdTS);

    /**
     * Emited when a token is burned.
     */
    event Burn(address indexed owner, uint256 tokenId, uint256 amount);

    /**
     * Emited when a token is burned in batch.
     */
    event BurnBatch(address indexed owner, uint256[] tokenIds, uint256[] amounts);

    //-------------------------------------------------------------------------
    // constants
    //-------------------------------------------------------------------------

    // token name/symbol
    string constant private _name   = "My Imaginary Items by Kai";
    string constant private _symbol = "IFITEM";

    // contract info
    string public _contractUri;

    //-------------------------------------------------------------------------
    // fields
    //-------------------------------------------------------------------------

    // track tokens
    Token[] private _tokens;

    // handle token uri overrides
    mapping (uint256 => string) private _ipfsHash;

    // roles
    mapping (address => bool) private _minterAddress;

    //-------------------------------------------------------------------------
    // ctor
    //-------------------------------------------------------------------------

    constructor(
        string memory baseUri,
        string memory contractUri)
        ERC1155(baseUri)
    {
        // start token index at 1
        _tokens.push();

        // save contract uri
        _contractUri = contractUri;
    }

    //-------------------------------------------------------------------------
    // modifiers
    //-------------------------------------------------------------------------

    modifier validTokenId(uint256 tokenId) {
        require(_created(tokenId), "invalid token");
        _;
    }

    //-------------------------------------------------------------------------

	/**
     * Verify caller is authorized minter.
     */
    modifier isMinter() {
        require(_minterAddress[_msgSender()] || owner() == _msgSender(), "caller not minter");
        _;
    }

    //-------------------------------------------------------------------------
    // internal
    //-------------------------------------------------------------------------

    /**
     * @dev Returns whether the specified token was created.
     */
    function _created(uint256 id)
        internal view
        returns (bool)
    {
        return id < _tokens.length && _tokens[id].createdTS > 0;
    }

    //-------------------------------------------------------------------------
    // ERC1155
    //-------------------------------------------------------------------------

    /**
     * @dev See {ERC1155-_mint}.
     */
    function _mint(
            address account, uint256 id, uint256 amount, bytes memory data)
        internal virtual override validTokenId(id)
    {
        super._mint(account, id, amount, data);
        _tokens[id].totalSupply += uint64(amount);
    }

    //-------------------------------------------------------------------------

    /**
     * @dev See {ERC1155-_burn}.
     */
    function _burn(address account, uint256 id, uint256 amount)
        internal virtual override
        validTokenId(id)
    {
        super._burn(account, id, amount);

        unchecked {
            _tokens[id].totalSupply -= uint64(amount);
        }

        // emit event
        emit Burn(account, id, amount);
    }

    //-------------------------------------------------------------------------

    /**
     * @dev See {ERC1155-_burnBatch}.
     */
    function _burnBatch(
            address account, uint256[] memory ids, uint256[] memory amounts)
        internal virtual override
    {
        super._burnBatch(account, ids, amounts);

        unchecked {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                _tokens[id].totalSupply -= uint64(amounts[i]);
            }
        }

        // emit event
        emit BurnBatch(account, ids, amounts);
    }

    //-------------------------------------------------------------------------

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     *  Each token should have it's own override.
     */
    function uri(uint256 id)
        public view override
        validTokenId(id)
        returns (string memory)
    {
        // append hash or use base
        return bytes(_ipfsHash[id]).length == 0
            ? super.uri(id)
            : string(abi.encodePacked(super.uri(id), "/", _ipfsHash[id]));
    }

    //-------------------------------------------------------------------------
    // admin
    //-------------------------------------------------------------------------

    /**
     * @dev Authorize minter address.
     *
     * @param minter address Address to authorize.
     */
    function registerMinterAddress(address minter)
        public
        onlyOwner
    {
        require(!_minterAddress[minter], "address already registered");
        _minterAddress[minter] = true;
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Remove minter address.
     *
     * @param minter address Address to revoke.
     */
    function revokeMinterAddress(address minter)
        public
        onlyOwner
    {
        require(_minterAddress[minter], "address not registered");
        delete _minterAddress[minter];
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Update default tokenUri used for all tokens.
     *
     * Should use the `\{id\}` replace mechanism to load the token id.
     */
    function setURI(string memory tokenUri)
        public
        onlyOwner
    {
        _setURI(tokenUri);
        emit URI(tokenUri, 0);
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Override token's ipfs hash.
     *
     * @param id uint256 Id of token to update.
     * @param ipfsHash string Ipfs hash to set for token.
     */
    function setTokenIpfsHash(uint256 id, string memory ipfsHash)
        public
        onlyOwner
        validTokenId(id)
    {
        _ipfsHash[id] = ipfsHash;
        emit URI(uri(id), id);
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Create a new token.
     *
     * @param amount uint256 Mint amount tokens to caller.
     * @param ipfsHash string Override ipfsHash for newly created token.
     */
    function create(uint256 amount, string memory ipfsHash)
        public onlyOwner
    {
        require(amount > 0, 'invalid amount');
        require(bytes(ipfsHash).length > 0, 'invalid ipfshash');

        // grab token id
        uint256 tokenId = _tokens.length;

        // add token
        int128 createdAt   = int128(int256(block.timestamp));
        Token memory token = Token(0, createdAt);
        _tokens.push(token);

        // override token's ipfsHash
        _ipfsHash[tokenId] = ipfsHash;
        emit URI(uri(tokenId), tokenId);

        // mint a single token
        _mint(msg.sender, tokenId, amount, "");

        // created event
        emit TokenCreated(tokenId, createdAt);
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Mint tokens to a wallet.
     *
     * @param to address Wallet to send balance to.
     * @param id uint256 Token id to mint.
     * @param amount uint256 Quantity of tokens (balance) to mint.
     */
    function mint(address to, uint256 id, uint256 amount)
        public isMinter
    {
        require(amount > 0, 'invalid amount');
        _mint(to, id, amount, "");
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Batch mint tokens to several wallets.
     *
     * Allows minting different tokens to different wallets. Easy way to
     *  airdrop multiple tokens at once in a single transaction.
     *
     * @param tos address[] Wallet to send balance to.
     * @param ids uint256[] Token id to mint.
     * @param amounts uint256[] Quantity of tokens (balance) to mint.
     */
    function mintBatch(address[] calldata tos,
            uint256[] calldata ids, uint256[] calldata amounts)
        external isMinter
    {
        require(tos.length == amounts.length && tos.length == ids.length, "data mismatch");
        for (uint256 i = 0; i < tos.length; ++i) {
            _mint(tos[i], ids[i], amounts[i], "");
        }
    }

    //-------------------------------------------------------------------------
    // accessors
    //-------------------------------------------------------------------------

    /**
     * @dev Conform to {IERC721Metadata-name}.
     */
    function name()
        public pure
        returns (string memory)
    {
        return _name;
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Conform to {IERC721Metadata-symbol}.
     */
    function symbol()
        public pure
        returns (string memory)
    {
        return _symbol;
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id)
        public view
        returns (uint256)
    {
        return id < _tokens.length
            ? _tokens[id].totalSupply
            : 0;
    }

    //-------------------------------------------------------------------------
    // interface
    //-------------------------------------------------------------------------

    /**
     * @dev Burn a single token balance.
     *
     * @param id uint256 Token id to burn.
     * @param amount uint256 Quantity of tokens burn.
     */
    function burn(uint256 id, uint256 amount)
        external
    {
        require(amount > 0, 'invalid amount');
        _burn(msg.sender, id, amount);
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Burn multiple token balances in a single transaction.
     *
     * @param ids uint256[] Token ids to burn.
     * @param amounts uint256[] Quantity of tokens burn.
     */
    function burnBatch(uint256[] calldata ids, uint256[] calldata amounts)
        external
    {
        _burnBatch(msg.sender, ids, amounts);
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Return token info.
     */
    function getToken(uint256 id)
        public view
        validTokenId(id)
        returns (Token memory, string memory)
    {
        return (_tokens[id], _ipfsHash[id]);
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Return list of all tokens.
     */
    function allTokens()
        public view
        returns (Token[] memory)
    {
        // return empty so all token indicies line up
        return _tokens;
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