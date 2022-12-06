/*
 *		VIASYLSWAP (PYKA)
 *
 *		Total Supply: 100,000,000
 * 
 * 
 *		ViasylSwap Website
 *
 *		https://viasylswap.org/
 *		https://viasyl.io
 *
 *
 *		Social Profiles
 *
 *		https://t.me/ViasylSwap
 *		https://t.me/ViasylSwapAnn
 *		https://twitter.com/ViasylSwap
 *		https://viasylswap.org/SocialProfiles
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact [email protected]
contract ViasylSwap is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("ViasylSwap", "PYKA") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}