// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract BRSToken is AccessControlEnumerable, ERC20Burnable {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // constructor
    constructor(string memory name, string memory symbol, uint256 amount) ERC20(name, symbol) {

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());

        _mint(_msgSender(), amount);
    }

    // mint function
    function mint(address to, uint256 amount) public virtual {

        require(hasRole(MINTER_ROLE, _msgSender()), "BRS: must have minter role");
        _mint(to, amount);
    }
}