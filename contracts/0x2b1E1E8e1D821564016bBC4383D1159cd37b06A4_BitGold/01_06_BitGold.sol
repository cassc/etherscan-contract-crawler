// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
 *  @title Wildland's Token
 *  Copyright @ Wildlands
 *  App: https://wildlands.me
 */

contract BitGold is ERC20("Bitgold", "BTG"), Ownable {

    event EmitMint(address to, uint256 amount);

    constructor(address treasury) {
        _mint(treasury, 1e6 * 10 ** decimals());
        _mint(treasury, 145000 * 10 ** decimals());
    }

    /**
     * @dev Creates `_amount` token to `_to`. Must only be called by the owner (Mine Master).
     * @param _to destination address
     * @param _amount token amount to be minted to address _to
     */
    function  mint(address _to, uint256 _amount) public onlyOwner{
        _mint(_to, _amount);
        emit EmitMint(_to, _amount);
    }
}