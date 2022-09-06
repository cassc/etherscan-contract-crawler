// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// Openzeppelin imports
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Implementation of the PVTToken.
 *
 */
contract LiquidityToken is AccessControl, ERC20 {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor()
        ERC20("LiquidityToken", "LTP") {

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function transferAdminRole(address newAdmin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(DEFAULT_ADMIN_ROLE, newAdmin);
        _revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function transferMinterRole(address newMinter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(MINTER_ROLE, newMinter);
        _revokeRole(MINTER_ROLE, _msgSender());
    }

    function mint(address to_, uint256 amount_) public onlyRole(MINTER_ROLE) virtual {
        require(amount_!=0,"Cant mint 0 tokens");
        _mint(to_, amount_);
    }

    function burn(address from_, uint256 amount_) public onlyRole(MINTER_ROLE) virtual {
        require(amount_!=0,"Cant burn 0 tokens");
        _burn(from_, amount_);
    }
}