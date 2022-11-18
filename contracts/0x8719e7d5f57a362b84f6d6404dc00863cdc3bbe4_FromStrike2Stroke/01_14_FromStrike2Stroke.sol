// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";

/**
 * @notice Implementation of "From Strike to Stroke" FIFA World Cup Qatar 2022 NFT collection
 */
contract FromStrike2Stroke is
    AccessControlUpgradeable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable
{
    /**
    * @notice The base uri
    */
    string private _uri;
    
    /**
    * @notice The role that allows minting new tokens
    */
    bytes32 private constant _MINTER_ROLE = keccak256("MINTER_ROLE");

    /********************************
     *  PRIVATE / INTERNAL METHODS  *
     ********************************/

    /**
     * @notice Returns the current base uri
     */
    function _baseURI()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return _uri;
    }

    /**
     * @notice Sets the base uri
     */
    function _setBaseURI(
        string memory uri
    )
        internal
    {
        _uri = uri;
    }

    /**
     * @notice See {ERC721URIStorageUpgradeable-_burn}.
     */
    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        ERC721URIStorageUpgradeable._burn(tokenId);
    }

    /*******************************
     *  PUBLIC / EXTERNAL METHODS  *
     *******************************/

    /**
     * @notice Sets the base uri
     * @dev The caller must have the `MINTER_ROLE`
     * @param uri The new base uri
     */
    function setBaseURI(string memory uri)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setBaseURI(uri);
    }

    /**
     * @notice Initializes the contract
     * @dev Only callable once
     * @param name_ The name of the token
     * @param symbol_ The symbol of the token
     * @param uri The base uri of the token
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory uri
    )
        public
        initializer
    {
        __ERC721_init(name_, symbol_);
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(_MINTER_ROLE, msg.sender);
        _setBaseURI(uri);
    }

    /**
     * @notice Mints a new token
     * @dev The caller must have the `MINTER_ROLE`.
     * @param account The address to mint the token to
     * @param id The id of the token
     */
    function mint(
        address account,
        uint256 id
    )
        public
        onlyRole(_MINTER_ROLE)
    {
        _mint(account, id);
    }

    /**
     * @notice Mints new tokens
     * @dev The caller must have the `MINTER_ROLE`.
     * @param accounts The addresses to mint the tokens respectively to
     * @param ids The ids of the tokens
     */
    function mintBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        onlyRole(_MINTER_ROLE)
    {   
        require(accounts.length == ids.length, "IthraFIFAWC2022: accounts and ids length mismatch");
        for (uint i = 0; i < accounts.length; i++) {
            _mint(accounts[i], ids[i]);
        }
    }

    /**
     * @notice Burns a token
     * @dev Only callable by the owner of the token or approved address
     * @param id The id of the token
     */
    function burn(
        uint256 id
    )
        public
    {
        require(_isApprovedOrOwner(msg.sender, id), "IthraFIFAWC2022: caller is not owner nor approved");
        _burn(id);
    }

    /**
     * @notice See {ERC721Upgradeable-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return ERC721Upgradeable.supportsInterface(interfaceId);
    }

    /**
     * @notice See {ERC721URIStorageUpgradeable-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return ERC721URIStorageUpgradeable.tokenURI(tokenId);
    }
}