// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/[email protected]/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/[email protected]/access/AccessControlUpgradeable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/[email protected]/proxy/utils/Initializable.sol";
import "@openzeppelin/[email protected]/proxy/utils/UUPSUpgradeable.sol";

/// @custom:security-contact [email protected]
contract Candle is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, AccessControlUpgradeable, ERC20PermitUpgradeable, ERC20VotesUpgradeable, UUPSUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC20_init("Candle", "CNDL");
        __ERC20Burnable_init();
        __AccessControl_init();
        __ERC20Permit_init("Candle");
        __ERC20Votes_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._burn(account, amount);
    }
}