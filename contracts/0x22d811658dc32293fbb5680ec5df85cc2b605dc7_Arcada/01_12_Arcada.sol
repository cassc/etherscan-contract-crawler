// SPDX-License-Identifier: MIT 

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract Arcada is ERC20Capped, AccessControl, ReentrancyGuard {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("Arcada", "ARCADA") ERC20Capped(10**(8 + 18)) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function proxyMint(address to, uint256 amount) external onlyRole(MINTER_ROLE) nonReentrant {
        _mintWithValidation(to, amount);
    }

    function devMint(address to, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        _mintWithValidation(to, amount);
    }

    function _mintWithValidation(address _to, uint256 _amount) internal {
        uint256 mintAmount = _amount;
        if (totalSupply() + mintAmount >= cap()) {
            mintAmount = cap() - totalSupply();
        }
        _mint(_to, mintAmount);
    }
}