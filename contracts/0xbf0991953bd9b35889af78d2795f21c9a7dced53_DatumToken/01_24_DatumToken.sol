// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract DatumToken is ERC20Burnable, ERC20Permit, AccessControlEnumerable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string private constant _NAME = "DATUM Token";
    string private constant _SYMBOL = "DATUM";

    constructor() ERC20(_NAME, _SYMBOL) ERC20Permit(_NAME) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
}