// SPDX-License-Identifier: UNLICENSED
// Author: Kai Aldag <[email protected]>
// Date: June 13th, 2022
// Purpose: Tokens earned as part of the Atari GFT's phase 2

pragma solidity ^0.8.0;

// ─────────────────────────────────────────────────────────────────────────────────────────────────────┐
//                                                                                                      │
// Imports                                                                                              │
//   └─ OpenZepplin Upgradeable Contracts (V4.5.2)                                                      │
//        ├─ ERC-1155                                                                                   │
//        │    ├─► Burnable ── Allowing Token Holders to burn.                                          │
//        │    └─► Supply ── For tracking supply of tokens.                                             │
//        └─ Access Control                                                                             │
//             ├─► Access Control Enumerable ── Admin authority permitted to: transfer and burn tokens, │
//             │                                mint additional supply of existing token ID.            │
//             └─► Ownable ── Responsible for managing Admin authorized members and                     │
//                            minting further token ID. Cannot be renounced.                            │
//                                                                                                      │
// ─────────────────────────────────────────────────────────────────────────────────────────────────────┘

import {IAccessPass} from "./IAccessPass.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";
import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {ERC1155BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import {ERC1155SupplyUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import {AccessControlEnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {StringsUpgradeable as Strings} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

/**
 * @title AccessPass
 *
 * @author Kai Aldag <[email protected]>
 *
 * @notice 
 *
 * @dev AccessPass utilizes OpenZepplin's Upgradeable Contracts library. Please refer to the docs in order to correctly interact with the proxy.
 * Contract Ownership is non-renounceable; the contract owner is the sole governor of the contract's admin role members - who are permitted to transfer
 * and burn tokens. The contract owner is the sole actor permitted to create new tokenIds; both admins and the owner are permitted to mint additional
 * tokens from an existing tokenId.
 *
 * @custom:security-contact [email protected]
 */
contract AccessPass is
    Initializable,
    OwnableUpgradeable,
    AccessControlEnumerableUpgradeable,
    IAccessPass,
    ERC1155BurnableUpgradeable,
    ERC1155SupplyUpgradeable
{

    // ────────────────────────────────────────────────────────────────────────────────
    // Events
    // ────────────────────────────────────────────────────────────────────────────────


    // ────────────────────────────────────────────────────────────────────────────────
    // Types
    // ────────────────────────────────────────────────────────────────────────────────


    // ────────────────────────────────────────────────────────────────────────────────
    // Fields
    // ────────────────────────────────────────────────────────────────────────────────

    /// @dev Contract name
    string public name;

    /// @dev Contract symbol
    string public symbol;

    //  ──────────────────────────────────────────────────────────────────────────────┐
    //                                                                                │
    //  Setup                                                                         │
    //  ¯¯¯¯¯                                                                         │
    //                                                                                │
    //      NOTE: As AccessPass makes use of upgradeable contracts, the constructor   │
    //      is empty and initial URI is set in the `initialize` function.             │
    //                                                                                │
    // ───────────────────────────────────────────────────────────────────────────────┘

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev Creates Admin role (as `DEFAULT_ADMIN_ROLE`) and assigns to the account that
     * deployed the contract.
     *
     * @param uri IPFS CID to directory containing tokens' metadata, at path extension `tokenId`.
     */
    function initialize(string memory uri, string memory _name, string memory _symbol) public initializer {
        __ERC1155_init_unchained(uri);
        __ERC1155Burnable_init();
        __Ownable_init();
        __AccessControlEnumerable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        name = _name;
        symbol = _symbol;
    }


    //  ──────────────────────────────────────────────────────────────────────────────┐
    //                                                                                │
    //  Admin Functionality                                                           │
    //  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯                                                           │
    //                                                                                │
    //      NOTE: RenounceOwnership is deliberately disabled so that a contract owner │
    //      will always exist. As the contract owner is responsible for minting new   │
    //      token IDs and managing the Admin role, it is important a contract owner   │
    //      is guarenteed to exist. Additionally, the contract owner is the sole      │
    //      actor permitted to add token IDs to the `nonTransferableTokenSet`,        │
    //      explicitly included when minting a new token ID. Contract owner is also   │
    //      permitted to add existing token IDs to the `nonTransferableTokenSet`      │
    //      via the `makeTokenNonTransferable` and remove them with                   │
    //      `makeTokenTransferable`. The Admin role is permitted to mint further      │
    //      tokens, but the token IDs must already exist.                             │
    //                                                                                │
    //  ──────────────────────────────────────────────────────────────────────────────┘

    //  ────────────────────────────  Token Minting  ──────────────────────────────  \\

    /**
     * @dev mints an `amount` of additional tokens with `id` and deposits `to` account.
     *
     * Emits a {TransferSingle} event.
     *
     * @param to the addresss that will receive the new token(s).
     * @param id the token ID to mint from.
     * @param amount the number of tokens to mint.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and
     * return the acceptance magic value.
     * - the caller must have admin privileges.
     * - Token `id` must already exist. Use `mintNew` to create tokens with new `id`.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external override onlyAdminRole {
        _mint(to, id, amount, data);
    }


    /**
     * @dev mints `amounts` of tokens with `ids` and deposits them into the `to` account.
     *
     * Emits a {TransferBatch} event.
     *
     * @param to the addresss that will receive the new tokens.
     * @param ids the new token ID to mint.
     * @param amounts the number of tokens to mint.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and
     * return the acceptance magic value.
     * - The caller must have Admin or Owner role.
     * - If caller has Admin role, but not owner, all `ids` must have existing supply.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external onlyAdminRole {
        _mintBatch(to, ids, amounts, data);
    }


    //  ──────────────────────────────  Transfering  ──────────────────────────────  \\

    /**
     * @dev Override required due to conflicting inheritance
     *
     * @inheritdoc ERC1155Upgradeable
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155SupplyUpgradeable, ERC1155Upgradeable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }


    //  ──────────────────────  Ownable and Access Control  ───────────────────────  \\

    /// @dev RenounceOwnership is deliberately disabled.
    function renounceOwnership() public view override onlyOwner {
        revert("AccessPass: renouncing contract ownership is unsupported.");
    }

    /**
     * @dev grantAdminRole allows the contract owner to create a new admin.
     *
     * Requirements:
     *
     * - the caller must be contract's `owner`.
     *
     */
    function grantAdminRole(address account) 
        public 
        onlyOwner {
        _grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
     * @dev revokeAdminRole allows the contract owner to remove an admin.
     *
     * Requirements:
     *
     * - the caller must be contract's `owner`.
     *
     */
    function revokeAdminRole(address account) 
        public
        onlyOwner {
        _revokeRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
     * @dev Throws if called by any account without admin or owner role.
     */
    modifier onlyAdminRole() {
        require(
            hasAdminRole(_msgSender()),
            "AccessPass: caller is not an Admin or contract owner."
        );
        _;
    }

    /**
     * @dev Checks if address has owner or Admin privileges.
     *
     * @param account address whose privileges will be checked.
     *
     * @return `true` if account is owner or Admin, `false` otherwise.
     */
    function hasAdminRole(address account) public view returns (bool) {
        if (account == owner() || hasRole(DEFAULT_ADMIN_ROLE, account)) {
            return true;
        } else {
            return false;
        }
    }


    //  ───────────────────────────────  Metadata  ────────────────────────────────  \\

    /**
     * @dev Permits owner to set a new metadata URI
     *
     * Requirements:
     *
     * - the caller must be contract's `owner`.
     *
     */
    function updateUri(string memory uri) public onlyOwner {
        _setURI(uri);
    }


    // ──────────────────────  Supports Interface {ERC165}  ──────────────────────   \\

    /**
     * @dev Override required due to conflicting inheritance
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlEnumerableUpgradeable, ERC1155Upgradeable, IERC165Upgradeable)
        returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}