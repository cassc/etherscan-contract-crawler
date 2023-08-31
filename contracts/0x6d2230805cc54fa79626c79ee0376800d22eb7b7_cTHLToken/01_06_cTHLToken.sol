// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title Community Thalon (cTHL) ERC20 token
 *
 * @notice Community Thalon is a temporary token ahead of the official token (THL) release.
 * Following the official THL Token Generation Event, cTHL will be 1:1 redeemable for THL.
  *
 * @dev Token Summary:
 *      - Symbol: cTHL
 *      - Name: Community Thalon
 *      - Decimals: 18
 *      - Initial token supply: 1 billion cTHL
 *      - Maximum token supply: 1 billion cTHL
 * 
 */
contract cTHLToken is ERC20Burnable {
      
    // Keep the (10**18) unchanged as it multiplies the number we want as our supply to have 18 decimal
    uint constant _initial_supply = 1000000000 * (10**18);
    
    constructor() ERC20("Community Thalon", "cTHL") { 
        _mint(0x84ac045B15b268227667961925b688b0527BeBba, _initial_supply);
    }
}