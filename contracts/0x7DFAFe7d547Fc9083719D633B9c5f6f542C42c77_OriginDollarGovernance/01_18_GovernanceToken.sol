// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC20Upgradeable.sol";
import "OwnableUpgradeable.sol";
import "AccessControlUpgradeable.sol";
import "Initializable.sol";
import "UUPSUpgradeable.sol";

/// @custom:security-contact [email protected]
contract OriginDollarGovernance is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    AccessControlUpgradeable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __ERC20_init("Origin Dollar Governance", "OGV");
        __Ownable_init();
        __UUPSUpgradeable_init();

        _mint(msg.sender, 1000000000 * 10**decimals());
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    function grantMinterRole(address _account) public onlyOwner {
        _grantRole(MINTER_ROLE, _account);
    }

    function grantAdminRole(address _account) public onlyOwner {
        _grantRole(DEFAULT_ADMIN_ROLE, _account);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}