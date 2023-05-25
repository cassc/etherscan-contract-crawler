/* SPDX-License-Identifier: MIT
    Lean Management Token is a STC-based project developed to create the platform and marketplace for the Lean community. 
    Check more details about $LEAN at https://leancommunity.org
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LEANERC20 is ERC20 {
    // 18 decimals
    constructor() ERC20("Lean Management Token", "LEAN") {
        _mint(_msgSender(), 3_000_000 * (10 ** uint256(decimals())));
    }

    function batchTransfer(address[] calldata destinations, uint256[] calldata amounts) public {
        uint256 n = destinations.length;
        address sender = _msgSender();
        require(n == amounts.length, "LEANERC20: Invalid BatchTransfer");
        for(uint256 i = 0; i < n; i++)
            _transfer(sender, destinations[i], amounts[i]);
    }
}