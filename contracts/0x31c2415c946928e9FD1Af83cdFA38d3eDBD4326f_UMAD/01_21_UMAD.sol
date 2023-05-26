// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";

import "erc-payable-token/contracts/token/ERC1363/ERC1363.sol";
import "eth-token-recover/contracts/TokenRecover.sol";

import "./behaviours/ERC20Mintable.sol";
import "../../access/Roles.sol";

/**
 * @title UMAD
 * @dev Implementation of the UMAD
 */
contract UMAD is ERC20Capped, ERC20Mintable, ERC20Burnable, ERC1363, TokenRecover, Roles {

    string  private NAME = "UMAD";
    string  private SYMBOL = "UMAD";
    uint8   private DECIMALS = 8;
    uint256 private CAP = 10000000000 * 1E8;

    constructor (
        address[] memory holders,
        uint256[] memory amounts
    )
        ERC1363(NAME, SYMBOL)
        ERC20Capped(CAP)
    {
        require(holders.length == amounts.length, "UMAD: wrong arguments");
        _setupDecimals(DECIMALS);

        for (uint256 i = 0; i < holders.length; ++i) {
            _mint(holders[i], amounts[i]);
        }
    }

    /**
     * @dev Function to mint tokens.
     *
     * NOTE: restricting access to addresses with MINTER role. See {ERC20Mintable-mint}.
     *
     * @param account The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function _mint(address account, uint256 amount) internal override onlyMinter {
        super._mint(account, amount);
    }

    /**
     * @dev Function to stop minting new tokens.
     *
     * NOTE: restricting access to owner only. See {ERC20Mintable-finishMinting}.
     */
    function _finishMinting() internal override onlyOwner {
        super._finishMinting();
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}. See {ERC20Capped-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Capped) {
        super._beforeTokenTransfer(from, to, amount);
    }
}