// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract YeyeVault is AccessControl {
    /* =============================================================
    * CONSTANTS
    ============================================================= */

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    /* =============================================================
    * STATES
    ============================================================= */

    // keep track of vault balances
    mapping(uint256 => mapping(address => uint256)) private _baseBalances;
    mapping(uint256 => mapping(address => uint256)) private _traitBalances;

    /* =============================================================
    * EVENTS
    ============================================================= */

    /**
     * @dev Emitted when `value` tokens of token type `id` are stored from `from` to `to` by `operator`.
     */
    event BaseTrasfer(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /**
     * @dev Emitted when multiple `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TraitTransfer(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /* =============================================================
    * CONSTRUCTOR
    ============================================================= */

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OWNER_ROLE, msg.sender);
    }

    /* =============================================================
    * GETTERS
    ============================================================= */

    /*
     * @dev check for balance of base token in the vault
     */
    function baseBalance(uint256 id, address _address)
        public
        view
        returns (uint256)
    {
        return _baseBalances[id][_address];
    }

    /*
     * @dev check for balance of trait token in the vault
     */
    function traitBalance(uint256 id, address _address)
        public
        view
        returns (uint256)
    {
        return _traitBalances[id][_address];
    }
    
    /* =============================================================
    * MAIN FUNCTION
    ============================================================= */

    /*
     * @dev store base of equipped token to vault
     */
    function storeBase(address owner, uint256 id)
        external
        onlyRole(OWNER_ROLE)
    {
        require(owner != address(0), "VAULT ERROR: store from zero address");
        _baseBalances[id][owner] += 1;

        emit BaseTrasfer(_msgSender(), address(0), owner, id, 1);
    }

    /*
     * @dev store traits of equipped token to vault
     */
    function storeTraits(address owner, uint256[] memory ids)
        external
        onlyRole(OWNER_ROLE)
    {
        require(owner != address(0), "VAULT ERROR: store to zero address");
        uint256[] memory values = getRange(ids.length, 1);
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            _traitBalances[id][owner] += 1;
        }

        emit TraitTransfer(_msgSender(), address(0), owner, ids, values);
    }

    /*
     * @dev withdraw traits of assembled token from vault
     */
    function withdrawBase(address owner, uint256 id)
        external
        onlyRole(OWNER_ROLE)
    {
        require(owner != address(0), "VAULT ERROR: withdraw from zero address");
        uint fromBalance = baseBalance(id, owner);
        require(fromBalance >= 1, "VAULT ERROR: withdraw amount exceeds balance");
        unchecked {
            _baseBalances[id][owner] = fromBalance - 1;
        }

        emit BaseTrasfer(_msgSender(), owner, address(0), id, 1);
    }

    /*
     * @dev withdraw traits of assembled token from vault
     */
    function withdrawTraits(address owner, uint256[] memory ids)
        external
        onlyRole(OWNER_ROLE)
    {
        require(owner != address(0), "VAULT ERROR: withdraw from zero address");
        uint256[] memory values = getRange(ids.length, 1);
        for (uint256 i = 0; i < ids.length; i++) {
            uint fromBalance = traitBalance(ids[i], owner);
            require(fromBalance >= 1, "VAULT ERROR: withdraw amount exceeds balance");
            _traitBalances[ids[i]][owner] = fromBalance - 1;
        }

        emit TraitTransfer(_msgSender(), owner, address(0), ids, values);
    }

    /*
     * @dev transfer stored base to another address
     */
    function transferBase(
        address from,
        address to,
        uint256 id
    ) external onlyRole(OWNER_ROLE) {
        require(from != address(0), "VAULT ERROR: transfer from zero address");
        require(
            baseBalance(id, from) >= 1,
            "VAULT ERROR: transfer amount exceeds balance"
        );
        unchecked {
            _baseBalances[id][from] -= 1;
        }
        _baseBalances[id][to] += 1;

        emit BaseTrasfer(_msgSender(), from, to, id, 1);
    }

    /*
     * @dev transfer stored traits to another address
     */
    function transferTraits(
        address from,
        address to,
        uint256[] memory ids
    ) external onlyRole(OWNER_ROLE) {
        require(from != address(0), "VAULT ERROR: transfer from zero address");
        uint256[] memory values = getRange(ids.length, 1);
        for (uint256 i = 0; i < ids.length; i++) {
            require(
                traitBalance(ids[i], from) >= 1,
                "VAULT ERROR: withdraw amount exceeds balance"
            );
            unchecked {
                _traitBalances[ids[i]][from] -= 1;
            }
            _traitBalances[ids[i]][to] += 1;
        }

        emit TraitTransfer(_msgSender(), from, to, ids, values);
    }

    /* =============================================================
    * MISC
    ============================================================= */

    /*
    @dev function to create array with default value
    */
    function getRange(uint256 n, uint256 value)
        public
        pure
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](n);
        for (uint256 i = 0; i < n; i++) result[i] = value;
        return result;
    }
}