// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract PiFiToken is ERC20Capped, AccessControl {
    uint256 public constant MAX_SUPPLY = 25 * 10**27;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    constructor() ERC20("PiFi Token", "PiFi") ERC20Capped(MAX_SUPPLY) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
    }

    function isMinter(address account) public view virtual returns (bool) {
        return hasRole(MINTER_ROLE, account);
    }

    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Restricted to admins");
        _;
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "Restricted to minters.");
        _;
    }

    function mint(address account, uint256 amount) public virtual onlyMinter {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public virtual onlyMinter {
        _burn(account, amount);
    }

    function addMinter(address account) public virtual onlyAdmin {
        grantRole(MINTER_ROLE, account);
    }

    function renounceAdmin() public virtual {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}