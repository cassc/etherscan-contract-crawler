// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../perks/WaifuPerks.sol";
import "../universal/ILiquidityManagerSupportedToken.sol";

/*
 * The main ERC20 token of the WaifuClan. Minted with WaifuNodes, used as a
 * currency to buy WaifuNodes tokens. pUwU tokens can be converted into UwU
 * tokens.
 */
contract WaifuToken is
    Initializable,
    ERC20Upgradeable,
    ERC20PausableUpgradeable,
    AccessControlEnumerableUpgradeable,
    UUPSUpgradeable,
    ILiquidityManagerSupportedToken
{
    /* ===== CONSTANTS ===== */

    // MINTER_ROLE should be granted to WaifuCashier and PreLaunchToken
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADDRESS_ADMIN_ROLE =
        keccak256("ADDRESS_ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /* ===== GENERAL ===== */

    address public liquidityManager;

    /* ===== EVENTS ===== */

    event LiquiqityManagerSet(address manager);

    /* ===== CONSTRUCTOR ===== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address admin
    ) public initializer {
        __ERC20_init("UwU Token", "UwU");
        __ERC20Pausable_init();
        __AccessControlEnumerable_init();
        __UUPSUpgradeable_init();

        _pause();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(ADDRESS_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);

        if (admin != _msgSender()) {
            _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
            _grantRole(ADDRESS_ADMIN_ROLE, _msgSender());
        }
    }

    /* ===== FUNCTIONALITY ===== */

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function approveForLiquidityManger(address _liquidityPair, uint256 amount)
        external
        override
    {
        require(
            _msgSender() == liquidityManager,
            "WaifuToken: sender is not LiquidityManager"
        );
        _approve(_liquidityPair, liquidityManager, amount);
    }

    /* ===== MUTATIVE ===== */
    
    function setLiquidityManager(address _liquidityManager)
        external
        onlyRole(ADDRESS_ADMIN_ROLE)
    {
        liquidityManager = _liquidityManager;

        emit LiquiqityManagerSet(_liquidityManager);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /* ===== INTERNAL ===== */

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable, ERC20PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}
}