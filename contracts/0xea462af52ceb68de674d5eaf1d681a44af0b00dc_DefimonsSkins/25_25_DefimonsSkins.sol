// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

import { IONFT1155 } from "../Omnichain/token/onft/IONFT1155.sol";
import { ONFT1155 } from "../Omnichain/token/onft/ONFT1155.sol";

contract DefimonsSkins is AccessControl, ONFT1155 {
    //
    // Events
    //

    event SkinMinterSet(address skinMinterAddress);
    event SkinMinterRevoked(address revokedAddress);
    event URISet(string newURI);

    //
    // Constants
    //

    bytes32 public constant SKIN_MINTER_ROLE = keccak256("SKIN_MINTER_ROLE");

    //
    // State
    //

    // Immutable
    string private _name;
    string private _symbol;

    //  Total supply of tokens with given ID
    mapping(uint256 => uint256) public totalSupply;

    //
    // Constructor
    //

    /**
     * @param name_         Name for this collection.
     * @param symbol_       Symbol for this collection.
     * @param uri_          Initial uri to be set for this collection.
     * @param lzEndpoint_   Adddress of the LayerZero endpoint contract.
     * @param adminAddress_ Address to be granted the DEFAULT_ADMIN_ROLE to.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_,
        address lzEndpoint_,
        address adminAddress_
    ) ONFT1155(uri_, lzEndpoint_) {
        require(lzEndpoint_ != address(0), "Layer Zero endpoint can't be zero address");
        require(adminAddress_ != address(0), "Admin address can't be zero address");

        _name = name_;
        _symbol = symbol_;

        _grantRole(DEFAULT_ADMIN_ROLE, adminAddress_);

        emit URISet(uri_);
    }

    //
    // Admin API
    //

    /**
     * @dev Grants SKIN_MINTER_ROLE to minterAddress_.
     * Required to call mint() and mintBatch() functions.
     */
    function setSkinMinterRole(address minterAddress_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(SKIN_MINTER_ROLE, minterAddress_);

        emit SkinMinterSet(minterAddress_);
    }

    /**
     * @dev Revokes SKIN_MINTER_ROLE from minterAddres_.
     */
    function revokeSkinMinterRole(address minterAddress_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(SKIN_MINTER_ROLE, minterAddress_);

        emit SkinMinterRevoked(minterAddress_);
    }

    /**
     * @dev Sets the URI for *ALL* tokens.
     * See {ERC1155 - uri}
     */
    function setURI(string memory newURI_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newURI_);

        emit URISet(newURI_);
    }

    //
    // Skin Minter API
    //

    /**
     * @dev Exposes the _mint() function.
     * Can only be called by an address with SKIN_MINTER_ROLE.
     * @param to_      The address to mint the tokens to.
     * @param tokenId_ The tokenId of the tokens to be minted.
     * @param amount_  The amount of token to be minted.
     * @param data_    Arbitrary data to be sent to _mint() function.
     */
    function mint(
        address to_,
        uint256 tokenId_,
        uint256 amount_,
        bytes memory data_
    ) external onlyRole(SKIN_MINTER_ROLE) {
        _mint(to_, tokenId_, amount_, data_);
    }

    /**
     * @notice Mints a batch of Skins to each address present in the list.
     * @dev This function calls the '_mintBatch()' function inside a recursive loop. Beware of gas spending!
     * @param addrs_    The list of addresses to mint to.
     * @param ids_      The IDs of the Skins to mint per address.
     * @param amounts_  The amount of each token ID to mint per address.
     */
    function mintBatch(
        address[] memory addrs_,
        uint256[][] memory ids_,
        uint256[][] memory amounts_
    ) external onlyRole(SKIN_MINTER_ROLE) {
        for (uint256 i = 0; i < addrs_.length; ) {
            _mintBatch(addrs_[i], ids_[i], amounts_[i], "");

            unchecked {
                ++i;
            }
        }
    }

    //
    // Public Read API
    //

    /**
     * @dev Getter for this collection's name
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Getter for this collection's symbol
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    //
    // ERC1155
    //

    function _beforeTokenTransfer(
        // solhint-disable-next-line no-unused-vars
        address,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        // solhint-disable-next-line no-unused-vars
        bytes memory
    ) internal virtual override {
        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ) {
                totalSupply[ids[i]] += amounts[i];

                unchecked {
                    ++i;
                }
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = totalSupply[id];
                require(supply >= amount, "ERC1155: Burn amount exceeds totalSupply");
                unchecked {
                    totalSupply[id] = supply - amount;
                }

                unchecked {
                    ++i;
                }
            }
        }
    }

    //
    // ERC165
    //

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ONFT1155)
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            interfaceId == type(IONFT1155).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}