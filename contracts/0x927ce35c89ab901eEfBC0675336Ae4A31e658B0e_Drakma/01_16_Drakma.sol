// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract Drakma is Context, AccessControlEnumerable, ERC20Capped, ERC20Burnable, ReentrancyGuard {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE");

    // creates Drakma ERC20 with a 10B cap
    constructor() ERC20("Drakma", "DK") ERC20Capped(10000000000000000000000000000) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(DEV_ROLE, _msgSender());
    }

    function mintDrakma(address to, uint256 amount) external  nonReentrant {
        require(hasRole(MINTER_ROLE, _msgSender()), "drakma: must have minter role to mint");
        _mint(to, amount);
    }


    function burnDrakma(address from, uint256 amount) external virtual {
        require(hasRole(DEV_ROLE, _msgSender()), "drakma: must have dev role to burn");
        _burn(from, amount);
    }

    function addMinter(address account) external virtual {
        require(hasRole(DEV_ROLE, _msgSender()), "drakma: must have dev role to add role");
        grantRole(MINTER_ROLE, account);
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Capped) {
        super._mint(account, amount);
    }
}