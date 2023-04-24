// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./WaifuToken.sol";

/*
 * Early distribution ERC20 token, that can be later converted to UwU token 1:1.
 * Can be used as a currency to buy WaifuNodes tokens. earlyLimit amount of
 * tokens is minted by admin with MINTER_ROLE, and then the tokens can be minted
 * by PresaleHelper.
 */
contract PreLaunchToken is
    Initializable,
    ERC20Upgradeable,
    ERC20CappedUpgradeable,
    AccessControlEnumerableUpgradeable,
    UUPSUpgradeable
{
    /* ===== CONSTANTS ===== */

    // PRESALE_HELPER_ROLE should be granted to presale helper
    bytes32 public constant PRESALE_HELPER_ROLE =
        keccak256("PRESALE_HELPER_ROLE");
    // CASHIER_ROLE should be granted to Waifu cashier
    bytes32 public constant CASHIER_ROLE = keccak256("CASHIER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADDRESS_ADMIN_ROLE =
        keccak256("ADDRESS_ADMIN_ROLE");
    bytes32 public constant LIMITS_ADMIN_ROLE = keccak256("LIMITS_ADMIN_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /* ===== GENERAL ===== */

    WaifuToken public mainToken;

    uint256 public earlyLimit;

    address public revenueDistributor;

    bool public transfersDisabled;
    bool public withdrawalsEnabled;

     /* ===== EVENTS ===== */
    
    event MainTokenSet(address mainToken);
    event RevenueDistributorSet(address revenueDistributor);
    event TransfersDisabledSet(bool disabled);
    event WithdrawalsEnabledSet(bool enabled);

    /* ===== CONSTRUCTOR ===== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        uint256 cap,
        uint256 _earlyLimit,
        address admin
    ) public initializer {
        __ERC20_init("PreLaunch UwU Token", "pUwU");
        __AccessControlEnumerable_init();
        __ERC20Capped_init(cap);
        __UUPSUpgradeable_init();

        earlyLimit = _earlyLimit;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(ADDRESS_ADMIN_ROLE, admin);
        _grantRole(LIMITS_ADMIN_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);

        if (admin != _msgSender()) {
            _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
            _grantRole(ADDRESS_ADMIN_ROLE, _msgSender());
        }
    }

    /* ===== FUNCTIONALITY ===== */

    function mint(address to, uint256 amount) public {
        bytes32 authorizedRole;
        if (totalSupply() < earlyLimit) {
            require(
                totalSupply() + amount <= earlyLimit,
                "PreLaunchToken: early limit violated"
            );
            authorizedRole = MINTER_ROLE;
        } else {
            authorizedRole = PRESALE_HELPER_ROLE;
        }
        
        require(
            hasRole(authorizedRole, _msgSender()),
            "PreLaunchToken: unauthorized"
        );

        _mint(to, amount);
    }

    function withdraw(uint256 amount) public {
        require(withdrawalsEnabled, "PreLaunchToken: withdrawals disabled");

        address msgSender = _msgSender();
        _withdraw(msgSender, msgSender, amount);
    }

    function withdrawFromTo(
        address from,
        address to,
        uint256 amount
    ) public onlyRole(CASHIER_ROLE) {
        _withdraw(from, to, amount);
    }

    /* ===== MUTATIVE ===== */

    function setMainToken(address _mainToken)
        external
        onlyRole(ADDRESS_ADMIN_ROLE)
    {
        mainToken = WaifuToken(_mainToken);

        emit MainTokenSet(_mainToken);
    }

    function setRevenueDistributor(address _revenueDistributor)
        external
        onlyRole(ADDRESS_ADMIN_ROLE)
    {
        revenueDistributor = _revenueDistributor;

        emit RevenueDistributorSet(_revenueDistributor);
    }

    function setTransfersDisabled(bool disabled)
        external
        onlyRole(LIMITS_ADMIN_ROLE)
    {
        transfersDisabled = disabled;

        emit TransfersDisabledSet(disabled);
    }

    function setWithdrawalsEnabled(bool enabled)
        external
        onlyRole(LIMITS_ADMIN_ROLE)
    {
        withdrawalsEnabled = enabled;

        emit WithdrawalsEnabledSet(enabled);
    }

    /* ===== INTERNAL ===== */

    function _withdraw(address from, address to, uint256 amount) private {
        require(
            address(mainToken) != address(0),
            "PreLaunchToken: no main token"
        );
        require(
            totalSupply() == cap() ,
            "PreLaunchToken: supply cap not reached"
        );

        _burn(from, amount);
        mainToken.mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal view override {
        if (transfersDisabled) {
            require(
                from == address(0) ||
                    to == address(0) ||
                    from == revenueDistributor ||
                    to == revenueDistributor,
                "PreLaunchToken: transfers disabled"
            );
        }
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    // The following functions are overrides required by Solidity.

    function _mint(address account, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20CappedUpgradeable)
    {
        return super._mint(account, amount);
    }
}