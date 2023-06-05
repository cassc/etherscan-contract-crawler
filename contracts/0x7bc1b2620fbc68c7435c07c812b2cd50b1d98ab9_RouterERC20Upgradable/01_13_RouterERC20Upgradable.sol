// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract RouterERC20Upgradable is
    Initializable,
    ContextUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ERC20Upgradeable
{
    using AddressUpgradeable for address;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint8 private _decimals;

    // Upgradable Functions

    // function initialize(
    //     string memory name_,
    //     string memory symbol_,
    //     uint8 decimals_
    // ) external initializer {
    //     __RouterERC20Upgradable_init(name_, symbol_, decimals_);
    // }

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        __RouterERC20Upgradable_init(name_, symbol_, decimals_);
    }

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __RouterERC20Upgradable_init(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) internal initializer {
        __Context_init_unchained();
        __AccessControl_init();
        __Pausable_init();
        __ERC20_init_unchained(name_, symbol_);
        __RouterERC20Upgradable_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setDecimals(decimals_);

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(BURNER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    function __RouterERC20Upgradable_init_unchained() internal initializer {}

    // Upgradable Functions

    //Core Contract Functions

    function _setDecimals(uint8 decimal) internal virtual {
        _decimals = decimal;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function pauseToken() public virtual onlyRole(PAUSER_ROLE) returns (bool) {
        _pause();
        return true;
    }

    function unpauseToken() public virtual onlyRole(PAUSER_ROLE) returns (bool) {
        _unpause();
        return true;
    }

    function mint(address _to, uint256 _value) public virtual onlyRole(MINTER_ROLE) returns (bool) {
        _mint(_to, _value);
        return true;
    }

    function burn(address _from, uint256 _value) public virtual onlyRole(BURNER_ROLE) returns (bool) {
        _burn(_from, _value);
        return true;
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
    //Core Contract Functions
}