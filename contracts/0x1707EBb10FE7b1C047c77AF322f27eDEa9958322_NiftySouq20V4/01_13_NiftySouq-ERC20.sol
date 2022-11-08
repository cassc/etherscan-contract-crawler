// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract NiftySouq20V4 is
    Initializable,
    ERC20Upgradeable,
    AccessControlUpgradeable
{
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MARKETPLACE_ROLE =
        keccak256("MARKETPLACE_ROLE");

    modifier isAdmin() {
        require(
             hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(ADMIN_ROLE, msg.sender) ||
                hasRole(MARKETPLACE_ROLE, msg.sender),
            "FIAT: 403A"
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address marketplace_) public initializer {
        __ERC20_init("NiftyCrypto", "NSC");
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(MARKETPLACE_ROLE,marketplace_);
        _mint(msg.sender, 1e25);

    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function takeFunds(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual isAdmin {
        _transfer(sender, recipient, amount);
    }
}