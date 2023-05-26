// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3; 

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - Preminted initial supply
 *  - Ability for holders to burn (destroy) their tokens
 *  - No access control mechanism (for minting/pausing) and hence no governance
 *
 * This contract uses {ERC20Burnable} to include burn capabilities - head to
 * its documentation for details.
 *
 * _Available since v3.4._
 */

contract FontERC20 is ERC20Burnable { 

    /**
     *
     * See {ERC20-constructor}.
     */
    constructor() ERC20("Font", "FONT") {
        _mint(_msgSender(), 2000000 * 10**18);
    }

}