// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interface/ID4AERC20Factory.sol";

contract D4AERC20 is Initializable, ERC20PermitUpgradeable, AccessControlUpgradeable {
    bytes32 public constant MINTER = keccak256("MINTER");
    bytes32 public constant BURNER = keccak256("BURNER");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory name, string memory symbol, address _minter) public initializer {
        __ERC20Permit_init(name);
        __ERC20_init(name, symbol);
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER, _minter);
    }

    function mint(address to, uint256 amount) public {
        require(hasRole(MINTER, msg.sender), "only for minter");
        super._mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        require(hasRole(BURNER, msg.sender), "only for burner");
        super._burn(from, amount);
    }

    function changeAdmin(address new_admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(msg.sender != new_admin, "new admin cannot be same as old one");
        _grantRole(DEFAULT_ADMIN_ROLE, new_admin);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}

contract D4AERC20Factory is ID4AERC20Factory {
    using Clones for address;

    D4AERC20 public impl;

    event NewD4AERC20(address addr);

    constructor() {
        impl = new D4AERC20();
    }

    function createD4AERC20(string memory _name, string memory _symbol, address _minter) public returns (address) {
        address t = address(impl).clone();
        D4AERC20(t).initialize(_name, _symbol, _minter);
        D4AERC20(t).changeAdmin(msg.sender);
        emit NewD4AERC20(t);
        return t;
    }
}