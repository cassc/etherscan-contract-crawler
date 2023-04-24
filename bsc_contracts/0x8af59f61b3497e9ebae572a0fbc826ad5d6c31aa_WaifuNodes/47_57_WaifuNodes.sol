// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../ERC1155/extensions/ERC1155TempBalanceHistoryUpgradeable.sol";
import "../ERC1155/extensions/ERC1155AggregateSupplyUpgradeable.sol";
import "./WaifuCashier.sol";

/*
 * ERC1155 tokens that produce rewards that can be claimed as UwU tokens. It
 * keeps track of account balances for each snapshot. Snapshots happen every
 * day at the time of the contract deployment. All the tokens have the same ID.
 * Tokens are minted and burned by the WaifuManager contract.
 */
contract WaifuNodes is
    Initializable,
    ERC1155Upgradeable,
    ERC1155PausableUpgradeable,
    ERC1155TempBalanceHistoryUpgradeable,
    ERC1155AggregateSupplyUpgradeable,
    AccessControlEnumerableUpgradeable,
    UUPSUpgradeable
{
    /* ===== CONSTANTS ===== */

    uint256 public constant SNAPSHOT_FREQUENCY = 1 days;
    uint256 public constant NODE_ID = 0;

    // MANAGER_ROLE should be granted to WaifuManager after deployment
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant LIMITS_ADMIN_ROLE = keccak256("LIMITS_ADMIN_ROLE");
    bytes32 public constant ADDRESS_ADMIN_ROLE =
        keccak256("ADDRESS_ADMIN_ROLE");
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /* ===== GENERAL ===== */

    uint256 public totalNodeLimit;
    uint256 public deployTime;

    bool public transfersEnabled;
    bool public burningEnabled;

    WaifuCashier public waifuCashier;

    /* ===== EVENTS ===== */

    event NewTotalNodeLimit(uint256 limit);
    event WaifuCashierSet(address waifuCashier);
    event TransferEnabledSet(bool enabled);
    event BurningEnabledSet(bool enabled);

    /* ===== CONSTRUCTOR ===== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory _uri,
        uint256 _totalNodeLimit,
        address admin
    ) public initializer {
        __ERC1155_init(_uri);
        __ERC1155Pausable_init();
        __ERC1155TempBalanceHistory_init();
        __ERC1155AggregateSupply_init();
        __AccessControlEnumerable_init();
        __UUPSUpgradeable_init();

        totalNodeLimit = _totalNodeLimit;
        deployTime = block.timestamp;

        _pause();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(LIMITS_ADMIN_ROLE, admin);
        _grantRole(ADDRESS_ADMIN_ROLE, admin);
        _grantRole(URI_SETTER_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);

        if (admin != _msgSender()) {
            _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
            _grantRole(ADDRESS_ADMIN_ROLE, _msgSender());
        }
    }

    /* ===== VIEWABLE ===== */

    function getCurrentSnapshotId() public view override returns (uint256) {
        return (block.timestamp - deployTime) / SNAPSHOT_FREQUENCY;
    }

    function getNodeBalanceHistoryOf(
        address account,
        uint256 fromSnapshot,
        uint256 toSnapshot
    ) public view returns (BalanceRecord[] memory) {
        return getBalanceHistoryOf(account, NODE_ID, fromSnapshot, toSnapshot);
    }

    function nodeBalanceOf(address account) public view returns (uint256) {
        return balanceOf(account, NODE_ID);
    }

    /* ===== FUNCTIONALITY ===== */

    function mint(
        address account,
        uint256 amount
    ) external whenNotPaused onlyRole(MANAGER_ROLE) {
        _mint(account, NODE_ID, amount, "");
    }

    function burn(
        address account,
        uint256 amount
    ) external whenNotPaused onlyRole(MANAGER_ROLE) {
        require(burningEnabled, "WaifuNodes: buring disabled");

        _burn(account, NODE_ID, amount);
    }

    function clearHistoryFor(address account)
        external
        whenNotPaused
        onlyRole(MANAGER_ROLE)
    {
        _clearHistoryFor(account);
    }

    /* ===== MUTATIVE ===== */

    function setWaifuCashier(address _waifuCashier)
        external
        onlyRole(ADDRESS_ADMIN_ROLE)
    {
        waifuCashier = WaifuCashier(_waifuCashier);

        emit WaifuCashierSet(_waifuCashier);
    }

    function setURI(string memory newuri) external onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    function setTotalNodeLimit(uint256 newTotalNodeLimit)
        external
        onlyRole(LIMITS_ADMIN_ROLE)
    {
        require(
            newTotalNodeLimit >= aggregateSupply(),
            "WaifuNodes: current supply is higher"
        );

        totalNodeLimit = newTotalNodeLimit;

        emit NewTotalNodeLimit(newTotalNodeLimit);
    }

    function setTransfersEnabled(bool enabled)
        external
        onlyRole(LIMITS_ADMIN_ROLE)
    {
        transfersEnabled = enabled;

        emit TransferEnabledSet(enabled);
    }

    function setBurningEnabled(bool enabled)
        external
        onlyRole(LIMITS_ADMIN_ROLE)
    {
        burningEnabled = enabled;

        emit BurningEnabledSet(enabled);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /* ===== INTERNAL ===== */

    function _getLastTokenId() internal virtual override returns (uint256) {
        return NODE_ID;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
        override(
            ERC1155Upgradeable,
            ERC1155PausableUpgradeable,
            ERC1155AggregateSupplyUpgradeable,
            ERC1155TempBalanceHistoryUpgradeable
        )
    {
        require(
            transfersEnabled || from == address(0) || to == address(0),
            "WaifuNodes: transfers disabled"
        );

        if (to != address(0) && address(waifuCashier) != address(0)) {
            waifuCashier.tryInitializeClaimTaxReductionFor(to);
        }

        super._beforeTokenTransfer(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    function _afterTokenTransfer(
        address,
        address from,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) internal virtual override {
        if (from == address(0)) {
            // minting
            require(
                aggregateSupply() <= totalNodeLimit,
                "WaifuNodes: exceeds node limit"
            );
        }
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}