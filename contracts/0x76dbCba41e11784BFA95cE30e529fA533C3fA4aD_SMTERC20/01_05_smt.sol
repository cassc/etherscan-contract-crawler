/* SPDX-License-Identifier: MIT
    Smart Marketing Token is a STC-based project developed to create the marketing agency of the future.
    Check more details about $SMT at smartmarketingtoken.com/
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SMTERC20 is ERC20 {
    // 18 decimals
    constructor() ERC20("Smart Marketing Token", "SMT") {
        _mint(_msgSender(), 10_000_000 * (10 ** uint256(decimals())));
    }

    function batchTransfer(address[] calldata destinations, uint256[] calldata amounts) public {
        uint256 n = destinations.length;
        address sender = _msgSender();
        require(n == amounts.length, "SMTERC20: Invalid BatchTransfer");
        for(uint256 i = 0; i < n; i++)
            _transfer(sender, destinations[i], amounts[i]);
    }
}