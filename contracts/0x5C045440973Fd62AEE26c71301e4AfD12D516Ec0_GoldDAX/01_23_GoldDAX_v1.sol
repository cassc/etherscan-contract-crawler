// SPDX-License-Identifier: MIT
// Implementation: v1.0
pragma solidity ^0.8.16;

import "./contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import "./contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "./contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "./contracts-upgradeable/proxy/utils/Initializable.sol";

/// @custom:security-contact [email protected]
contract GoldDAX is Initializable, ERC20Upgradeable, ERC20SnapshotUpgradeable, AccessControlUpgradeable, ERC20PermitUpgradeable, ERC20VotesUpgradeable {
    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC20_init("GoldDAX", "GDAX");
        __ERC20Snapshot_init();
        __AccessControl_init();
        __ERC20Permit_init("GoldDAX");
        __ERC20Votes_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SNAPSHOT_ROLE, msg.sender);
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    function snapshot() public onlyRole(SNAPSHOT_ROLE) {
        _snapshot();
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20SnapshotUpgradeable)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

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