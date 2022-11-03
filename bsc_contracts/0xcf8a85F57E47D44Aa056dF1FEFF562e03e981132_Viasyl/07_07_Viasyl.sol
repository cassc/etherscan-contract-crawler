/*
 *		VIASYL (PYKA)
 *
 *		Total Supply: 700,000,000
 * 
 * 
 * 
 *		Viasyl Website
 *
 *		https://viasyl.io/
 *
 *
 *
 *		Social Profiles
 *
 *		https://t.me/Viasylio
 *		https://twitter.com/ViaSylio
 *		https://viasyl.io/SocialProfiles
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact [email protected]
contract Viasyl is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Viasyl", "PYKA") {
        _mint(msg.sender, 700000000 * 10 ** decimals());
    }
}