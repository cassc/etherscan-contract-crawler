// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "./TransactionFee.sol";

/**
 * @title Boundless World (BLB) Token
 */
contract BLBToken is ERC20, ERC20Capped, ERC20Burnable, ERC20Permit, TransactionFee {

    constructor(address initialAdmin) 
        ERC20("Boundless World", "BLB") 
        ERC20Capped((3.69 * 10 ** 9) * 10 ** decimals())
        ERC20Permit("Boundless World") 
    {
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(MINTER_ROLE, initialAdmin);
        _grantRole(FEE_SETTER_ROLE, initialAdmin);
        _grantRole(FEE_FREE_ROLE, initialAdmin);
    }

    /**
     * Creates amount tokens and assigns them to account, increasing the total supply.
     * 
     * Emits a transfer event with from set to the zero address.
     * 
     * Requirements:
     * 
     * account cannot be the zero address.
     * only role MINTER_ROLE can call this function.
     */
    function mint(address account, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(account, amount);
    }

    /**
     * Mint amount of token to every member in accounts.
     * 
     * Emits some transfer events with from set to the zero address to every account.
     * 
     * Requirements:
     * 
     * accounts cannot be the zero address.
     * only role MINTER_ROLE can call this function.
     */
    function mintBatch(
        address[] calldata accounts, 
        uint256 amount
    ) public onlyRole(MINTER_ROLE) {
        for(uint16 i; i < accounts.length; i++){
            _mint(accounts[i], amount);
        }
    }


    // The following functions are overrides required by Solidity.

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Capped)
    {
        super._mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, TransactionFee)
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}