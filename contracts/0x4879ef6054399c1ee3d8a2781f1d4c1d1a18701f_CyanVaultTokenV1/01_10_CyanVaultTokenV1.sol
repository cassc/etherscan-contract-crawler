// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CyanVaultTokenV1 is AccessControl, ERC20 {
    bytes32 public constant CYAN_VAULT_ROLE = keccak256("CYAN_VAULT_ROLE");
    event BurnedAdminToken(uint256 amount);

    constructor(
        string memory _name,
        string memory _symbol,
        address cyanSuperAdmin
    ) ERC20(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, cyanSuperAdmin);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) external onlyRole(CYAN_VAULT_ROLE) {
        require(to != address(0), "Mint to the zero address");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyRole(CYAN_VAULT_ROLE) {
        require(balanceOf(from) >= amount, "Balance not enough");
        _burn(from, amount);
    }

    function burnAdminToken(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(balanceOf(msg.sender) >= amount, "Balance not enough");
        _burn(msg.sender, amount);

        emit BurnedAdminToken(amount);
    }

    function decimals() public view override returns (uint8) {
        return 6;
    }
}