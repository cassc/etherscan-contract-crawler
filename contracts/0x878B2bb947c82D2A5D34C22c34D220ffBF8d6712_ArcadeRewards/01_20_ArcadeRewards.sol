// SPDX-License-Identifier: UNLICENSED
// Author: Kai Aldag <[email protected]>
// Date: May 12th, 2022
// Purpose: ERC-1155 token rewards for Atari Arcade

pragma solidity ^0.8.0;

// ─────────────────────────────────────────────────────────────────────────────────────────────────────┐
//                                                                                                      │
// Imports                                                                                              │
//   └─ OpenZepplin Contracts (V4.5.2)                                                                  │
//        ├─ ERC-1155                                                                                   │
//        │    ├─► Burnable ── Allowing Token Holders to burn.                                          │
//        │    └─► Supply ── For tracking supply of tokens.                                             │
//        ├─ Access Control                                                                             │
//        │    ├─► Access Control Enumerable ── Admin authority permitted to: transfer and burn tokens, │
//        │    │                                mint additional supply of existing token ID.            │
//        │    └─► Ownable ── Responsible for managing Admin authorized members and                     │
//        │                   minting further token ID. Cannot be renounced.                            │
//        ├─► ERC2981 ── Implementation for token royalties                                             │
//        └─► Strings ── Used for token URI encoding                                                    │
//                                                                                                      │
// ─────────────────────────────────────────────────────────────────────────────────────────────────────┘

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Burnable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import {ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title ArcadeRewards
 *
 * @author Kai Aldag <[email protected]>
 *
 * @notice This contract is used to isssue rewards earned through the Atari Arcade. Tokens are airdropped
 * to recipients, free of charge, courtesy of EveryRealm.
 *
 * @dev ArcadeRewards implements the multi-token standard (ERC-1155) and conforms to the metadata URI, supply,
 * and burnable extensions. ArcadeRewards additionally implements the NFT Royalty Standard (ERC-2981). Tokens
 * can have a fixed supply that cannot be overwritten by the owner or admin.
 *
 * @custom:security-contact [email protected]
 */
contract ArcadeRewards is
    ERC1155Burnable,
    ERC1155Supply,
    ERC2981,
    Ownable,
    AccessControlEnumerable
{
    // ────────────────────────────────────────────────────────────────────────────────
    // Events
    // ────────────────────────────────────────────────────────────────────────────────

    /** 
     * @dev emitted once a tokenId has reached the maximum permitted supply - at which
     * point, no further tokens may be issued.
     */
    event maxSupplyReached(uint256 indexed tokenId);


    // ────────────────────────────────────────────────────────────────────────────────
    // Types
    // ────────────────────────────────────────────────────────────────────────────────

    using Strings for uint256;


    // ────────────────────────────────────────────────────────────────────────────────
    // Fields
    // ────────────────────────────────────────────────────────────────────────────────

    /// @dev Contract name
    string public name;

    /// @dev Contract symbol
    string public symbol;

    /// @dev Used to track maximum permitted supply per token.
    mapping(uint256 => uint256) private _maxSupply;


    // ────────────────────────────────────────────────────────────────────────────────
    // Setup
    // ────────────────────────────────────────────────────────────────────────────────

    /**
     * @dev Creates Admin role (as `DEFAULT_ADMIN_ROLE`) and assigns to the account that
     * deployed the contract. Sets a royalty rate of 5% to the deployer.
     *
     * @param _uri IPFS CID to directory containing tokens' metadata, at path extension `tokenId`.
     * @param _name the contract's permanent name.
     * @param _symbol the contract's permanent abbreviation symbol.
     *
     */
    constructor(
        string memory _uri,
        string memory _name,
        string memory _symbol
    ) ERC1155(_uri) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setDefaultRoyalty(_msgSender(), 500);
        name = _name;
        symbol = _symbol;
    }


    //  ──────────────────────────────────────────────────────────────────────────────┐
    //                                                                                │
    //  User Functionality                                                            │
    //  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯                                                            │
    //                                                                                │
    //      NOTE: Token transfers and burns are overwritten to allow the owner or     │
    //      admin. This is in the interest of correcting any issues or incorrect      │
    //      addresses while AirDrops are occurring.                                   │
    //                                                                                │
    //  ──────────────────────────────────────────────────────────────────────────────┘

    //  ──────────────────────────────  Transfering  ──────────────────────────────  \\

    /**
     * @notice transfers tokens `from` an account `to` another.
     * @dev if any of the ids are non transferable, the entire transaction reverts.
     *
     * @param from address to transfer tokens out of.
     * @param to address of the receiver of all tokens.
     * @param ids list of token id that will be transferred.
     * @param amounts list containing amount of tokens to transfer.
     *
     * Requirements:
     *
     * - length of `ids` and `amounts` must match.
     * - the caller must be the `from` address provided or be approved by the `from` address
     *     - unless caller has admin role
     *
     * @inheritdoc ERC1155
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        // 1. Ensure _msgSender is holder, approved to transfer, or admin
        require(
            from == _msgSender() ||
                isApprovedForAll(from, _msgSender()) ||
                hasAdminRole(_msgSender()),
            "ArcadeRewards: caller is not token holder, on approved list, or admin privileged."
        );

        // 2. Authorize batch transfer
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @notice transfer `amount` of a token with `id` `from` an account `to` another.
     *
     * @param from address to transfer tokens out of.
     * @param to address that will receive tokens.
     * @param id token id that will be transferred.
     * @param amount number of tokens of the id to transfer.
     *
     * Requirements:
     *
     * - the caller must be the `from` address provided or be approved by the `from` address
     *     - unless caller has admin role
     *
     * @inheritdoc ERC1155
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {
        // 1. Ensure _msgSender is holder, approved to transfer, or admin
        require(
            from == _msgSender() ||
                isApprovedForAll(from, _msgSender()) ||
                hasAdminRole(_msgSender()),
            "ArcadeRewards: caller is not token holder, on approved list, or admin privileged."
        );

        // 2. Authorize transfer
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev Override required due to conflicting inheritance
     *
     * @inheritdoc ERC1155
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Supply, ERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }


    //  ────────────────────────────────  Burning  ────────────────────────────────  \\

    /**
     * @notice Burns token from `account` with given `id`.
     *
     * Requirements:
     *
     * - the caller must be the `account` provided or be approved by the `account`
     *     - unless caller has admin role
     *
     * @inheritdoc ERC1155Burnable
     */
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public override {
        // 1. Ensure _msgSender is holder, approved to burn, or admin
        require(
            account == _msgSender() ||
                isApprovedForAll(account, _msgSender()) ||
                hasAdminRole(_msgSender()),
            "ArcadeRewards: caller is not token holder, on approved list, or admin privileged."
        );

        // 2. If above check succeeds, authorize burn
        _burn(account, id, value);
    }

    /**
     * @notice Burns tokens from `account` with given `ids`.
     *
     * Requirements:
     *
     * - the caller must be the `account` provided or be approved by the `account`
     * - unless caller has admin role
     *
     * @inheritdoc ERC1155Burnable
     */
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public override {
        // 1. Ensure _msgSender is holder, approved to burn, or admin
        require(
            account == _msgSender() ||
                isApprovedForAll(account, _msgSender()) ||
                hasAdminRole(_msgSender()),
            "ArcadeRewards: caller is not token holder, on approved list, or admin privileged."
        );

        // 2. If above check succeeds, authorize burn
        _burnBatch(account, ids, values);
    }


    //  ──────────────────────────────────────────────────────────────────────────────┐
    //                                                                                │
    //  Admin Functionality                                                           │
    //  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯                                                           │
    //                                                                                │
    //      NOTE: RenounceOwnership is deliberately disabled so that a contract owner │
    //      will always exist. As the contract owner is responsible for minting new   │
    //      token IDs, managing the Admin role updating token URI, and managing       │
    //      royalties, it is important a contract owner is guarenteed to exist.       │
    //      Additionally, the contract owner is the sole actor permitted to set a     │
    //      a token's max supply which is either set when minting a new token ID, or  │
    //      may be set once afterwards. The Admin role is permitted to mint further   │
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
     * - If caller is admin, token `id` must already exist or have maxSupply set. Use `mintNew` to create
     * tokens with new `id`.
     *
     */
    function mintSupply(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external onlyAdminRole {
        // 1. Require max supply not reached.
        require(
            totalSupply(id) + amount <= _maxSupply[id] || _maxSupply[id] == 0,
            "ArcadeRewards: amount exceeds permitted maximum."
        );
        // 2. If caller is not owner, ensure tokens either have existing supply
        // or have a maxSupply set.
        if (_msgSender() != owner()) {
            require(
                totalSupply(id) != 0 || _maxSupply[id] != 0,
                "ArcadeRewards: Admin not authorized to mint tokens of novel ID."
            );
        }
        // 3. Authorize mint
        _mint(to, id, amount, data);

        // 4. Post mint call
        _postMint(id);
    }

    /**
     * @dev mints an `amount` of new tokens with `id` and deposits `to` account.
     *
     * Emits a {TransferSingle} event.
     *
     * @param to the addresss that will receive the new token(s).
     * @param id the new token ID to mint.
     * @param amount the number of tokens to mint.
     * @param maxSupply the maximum supply for the token. Once set, cannot be modified. If 0, no maximum.
     * @param newuri the contract's new metadata uri.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and
     * return the acceptance magic value.
     * - the caller must be contract's `owner`.
     *
     */
    function mintNew(
        address to,
        uint256 id,
        uint256 amount,
        uint256 maxSupply,
        string memory newuri,
        bytes memory data
    ) external onlyOwner {
        // 1. Ensure max supply not reached
        require(
            totalSupply(id) + amount <= _maxSupply[id] || _maxSupply[id] == 0,
            "ArcadeRewards: amoung exceeds permitted maximum."
        );

        // 2. Set max supply and mint token
        _maxSupply[id] = maxSupply;
        _mint(to, id, amount, data);

        // 3. If new uri is not empty, update
        if (bytes(newuri).length > 0) {
            _setURI(newuri);
        }

        // 4. Post mint call
        _postMint(id);
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
     *
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external onlyAdminRole {
        // 1. Ensure all new tokens do now exceed max and if caller is admin, check tokens authorized to mint
        if (_msgSender() == owner()) { // Owner case
            for (uint256 i = 0; i < ids.length; i++) {
                require(
                    totalSupply(ids[i]) + amounts[i] <= _maxSupply[ids[i]] ||
                        _maxSupply[ids[i]] == 0,
                    "ArcadeRewards: amoung exceeds permitted maximum."
                );
            }
        } else { // Admin case. Only Admin authorization can get to this point so admin is assumed.
            for (uint256 i = 0; i < ids.length; i++) {
                require(
                    totalSupply(ids[i]) + amounts[i] <= _maxSupply[ids[i]] ||
                        _maxSupply[ids[i]] == 0,
                    "ArcadeRewards: amoung exceeds permitted maximum."
                );
                require(
                    totalSupply(ids[i]) != 0 || _maxSupply[ids[i]] != 0,
                    "ArcadeRewards: Admin not authorized to mint tokens of novel ID."
                );
            }
        }

        // 2. Authorize mint
        _mintBatch(to, ids, amounts, data);

        //3. Post batch mint call
        _postMintBatch(ids);
    }

    /**
     * @dev mints one token to each recipient.
     *
     * Emits many {TransferSingle} events.
     *
     * @param recipients the addresses that will receive the new tokens.
     * @param id the token ID to mint.
     *
     * Requirements:
     *
     * - All `recipients` must be valid receivers.
     * - If caller is admin, token must be eligible for minting.
     *
     */
    function mintAirdrop(
        address[] memory recipients,
        uint256 id,
        bytes memory data
    ) external onlyAdminRole {
        require(
            totalSupply(id) + recipients.length <= _maxSupply[id] ||
                _maxSupply[id] == 0,
            "ArcadeRewards: amoung exceeds permitted maximum."
        );
        if (_msgSender() != owner()) {
            require(
                totalSupply(id) != 0 || _maxSupply[id] != 0,
                "ArcadeRewards: Admin not authorized to mint tokens of novel ID."
            );
        }
        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            _mint(recipient, id, 1, data);
        }
        
        _postMint(id);
    }

    /** 
     * @dev called after any mint occurs to emit an event if max supply reached.
     */
    function _postMint(uint256 id) private {
        // 1. If token has reached its max supply - and max supply is not 0 - emit max reached.
        if (totalSupply(id) == _maxSupply[id] && _maxSupply[id] != 0) {
            emit maxSupplyReached(id);
        }
    }

    /** 
     * @dev called after any batch mint occurs to emit an event if max supply reached.
     */
    function _postMintBatch(uint256[] memory ids) private {
        // 1. Iterate over all ids and forward to _postMint
        for (uint256 i = 0; i < ids.length; i++) {
            _postMint(ids[i]);
        }
    }


    //  ───────────────────────────  Supply Management  ───────────────────────────  \\

    /**
     * @dev Sets to maximum number of tokens that may be minted of a given ID.
     * NOTE: Can only be set once by owner and is permanently immutable. Excercise caution.
     * 
     * @param tokenId the token to set the max supply on
     * @param maxSupply the maximum number of tokens that may be issued
     *
     * Requirements:
     *
     * - The caller must have Owner role.
     * - The token must not have an existing max supply set.
     *
     */
    function setMaxSupply(uint256 tokenId, uint256 maxSupply)
        external
        virtual
        onlyOwner
    {
        require(
            _maxSupply[tokenId] == 0,
            "ArcadeRewards: max supply already set."
        );
        _maxSupply[tokenId] = maxSupply;
    }


    //  ──────────────────────────  Royalty Management  ───────────────────────────  \\

    /**
     * @dev updates the royalty receiver address and rate.
     * 
     * @param receiver the address to receive resale commissions
     * @param feeNumerator the commission rate expressed feeNumerator / 10,000
     *
     * Requirements:
     *
     * - The caller must have Admin or Owner role.
     *
     */
    function updateDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        virtual
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }


    //  ──────────────────────  Ownable and Access Control  ───────────────────────  \\

    /**
     * @dev RenounceOwnership is deliberately disabled.
     */
    function renounceOwnership() public view override onlyOwner {
        revert("ArcadeRewards: renouncing contract ownership is unsupported.");
    }

    /**
     * @dev grantAdminRole allows the contract owner to create a new admin.
     *
     * Requirements:
     *
     * - the caller must be contract's `owner`.
     *
     */
    function grantAdminRole(address account) public onlyOwner {
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
    function revokeAdminRole(address account) public onlyOwner {
        _revokeRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
     * @dev Throws if called by any account without admin or owner role.
     */
    modifier onlyAdminRole() {
        require(
            hasAdminRole(_msgSender()),
            "ArcadeRewards: caller is not an Admin or contract owner."
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

    /// @inheritdoc ERC1155
    function uri(uint256 tokenId)
        public
        view
        virtual
        override(ERC1155)
        returns (string memory)
    {
        return
            bytes(super.uri(tokenId)).length > 0
                ? string(
                    abi.encodePacked(super.uri(tokenId), tokenId.toString())
                )
                : "";
    }

    /**
     * @dev Permits owner to set a new metadata URI
     *
     * Requirements:
     *
     * - the caller must be contract's `owner`.
     *
     */
    function updateUri(string memory _uri) external onlyOwner {
        _setURI(_uri);
    }


    // ──────────────────────  Supports Interface {ERC165}  ──────────────────────   \\

    /**
     * @dev Override required due to conflicting inheritance
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlEnumerable, ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}