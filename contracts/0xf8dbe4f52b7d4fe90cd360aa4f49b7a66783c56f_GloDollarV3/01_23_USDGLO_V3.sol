// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../v2/ERC20Upgradeable_V2.sol";
import "./ERC20PermitUpgradeable_V3.sol";

/// @custom:security-contact Garm Lucassen <[email protected]>
contract GloDollarV3 is
    Initializable,
    ERC20UpgradeableV2,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ERC20PermitUpgradeableV3
{
    event Mint(address indexed minter, address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 amount);

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant DENYLISTER_ROLE = keccak256("DENYLISTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address admin) public initializer {
        __ERC20_init("Glo Dollar", "USDGLO");
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function initializeV3() public reinitializer(2) {
        __ERC20Permit_init("Glo Dollar");
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function denylist(address denylistee) external onlyRole(DENYLISTER_ROLE) {
        _denylist(denylistee);
    }

    function undenylist(address denylistee) external onlyRole(DENYLISTER_ROLE) {
        _undenylist(denylistee);
    }

    function destroyDenylistedFunds(address denylistee)
        external
        onlyRole(DENYLISTER_ROLE)
    {
        _destroyDenylistedFunds(denylistee);
    }

    function mint(address to, uint256 amount)
        external
        onlyRole(MINTER_ROLE)
        whenNotDenylisted(_msgSender())
    {
        _mint(to, amount);
        emit Mint({minter: _msgSender(), to: to, amount: amount});
    }

    function burn(uint256 amount) external onlyRole(MINTER_ROLE) {
        _burn(_msgSender(), amount);
        emit Burn({burner: _msgSender(), amount: amount});
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}
}