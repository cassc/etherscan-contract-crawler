// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/presets/ERC1155PresetMinterPauser.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IRegistry.sol";


/**
 * @dev {ERC1155} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *
 * Differs from OZ contract:
 *  - pausing removed
 *  - uri per token id
 *  - max supply enforced
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract BaseTokenERC1155 is
    Initializable,
    ContextUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC1155BurnableUpgradeable,
    OwnableUpgradeable
{

    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant URI_RESETTER_ROLE = keccak256("URI_RESETTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address public registry;

    mapping (uint256 => uint256) public minted;    // Cumulative minted per id.
    mapping (uint256 => uint256) public maxSupply; // Max supply per id.
    mapping (uint256 => string) public uris;       // Max supply per id.


    // Token name
    string public name;
    // Token symbol
    string public symbol;


    /* -------------------------------- Modifiers ------------------------------- */

    /**
     * @dev Throws if called by any account other than the admin or URI setter.
     */
    modifier onlyAdminOrURISetter() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) ||
            hasRole(URI_SETTER_ROLE, _msgSender()) ||
            hasRole(URI_RESETTER_ROLE, _msgSender()),
            "onlyAdminOrURISetter: caller is not authorized"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "onlyAdminOrURISetter: caller is not authorized"
        );
        _;
    }


    /* ------------------------------- Constructor ------------------------------ */

    function initialize(string memory name_, string memory symbol_) public virtual initializer {

        // Meta
        name = name_;
        symbol = symbol_;

        // General
        __Context_init_unchained();
        __ERC165_init_unchained();

        // Access
        __Ownable_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        
        // Token
        __ERC1155Burnable_init_unchained();
        
        registry = _msgSender();

        // Roles
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(URI_RESETTER_ROLE, _msgSender());
    }


    /* --------------------------------- Getters -------------------------------- */

    function uri(uint256 id) public view override returns (string memory) {
        return uris[id];
    }


    /* ------------------------------ Admin Methods ----------------------------- */

    function setTokenURI(uint256 id, string memory newuri)
        external
        onlyAdminOrURISetter
    {

        string memory base = uri(id);

        // Modifier gates function. Extra restriction if not ADMIN.
        require(
            !(hasRole(URI_SETTER_ROLE, _msgSender())) || bytes(base).length == 0,
            "setBaseURI: only admin can reset URI"
        );

        uris[id] = newuri;
    }


    function setMax(uint256 id, uint256 newmax)
        external
        onlyAdmin
    {
        maxSupply[id] = newmax;
    }

    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have minter role to mint");

        // Update totals
        minted[id] += amount;

        // Enforce max
        require(minted[id] <= maxSupply[id], "BaseTokenERC1155: maxSupply exceeded");

        _mint(to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have minter role to mint");

        for (uint256 i = 0; i < ids.length; i++) {

            // Update totals
            minted[ids[i]] += amounts[i];

            // Enforce max
            require(minted[ids[i]] <= maxSupply[ids[i]], "BaseTokenERC1155: maxSupply exceeded");

        }

        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerableUpgradeable, ERC1155Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Upgradeable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
    uint256[50] private __gap;
}