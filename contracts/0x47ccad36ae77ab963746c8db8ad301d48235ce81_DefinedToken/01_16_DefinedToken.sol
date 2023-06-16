// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "openzeppelin-solidity/contracts/access/AccessControl.sol";

/**
 * @title DefinedToken
 * DefinedToken - an OpenSea-tradable contract with owner-defined token IDs that
 * also (a) allows setting of the baseTokenURI; and (b) supports a minter role.
 */
contract DefinedToken is AccessControl, ERC721Tradable {
    string private _baseTokenURI;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(string memory name, string memory symbol, string memory baseTokenURI_, address proxyRegistryAddress)
        ERC721Tradable(name, symbol, proxyRegistryAddress)
    {
        setBaseTokenURI(baseTokenURI_);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    /*
     * @dev Mints `tokenId` and safely transfers it to `to`.
     */
    function safeMint(address to, uint256 tokenId) public onlyRole(MINTER_ROLE) {
        _safeMint(to, tokenId, "");
    }

    function baseTokenURI() override public view returns (string memory) {
        return _baseTokenURI;
    }

    /*
     * @dev Sets the value returned by baseTokenURI().
    */
    function setBaseTokenURI(string memory baseTokenURI_) public onlyOwner {
        _baseTokenURI = baseTokenURI_;
    }

     /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}