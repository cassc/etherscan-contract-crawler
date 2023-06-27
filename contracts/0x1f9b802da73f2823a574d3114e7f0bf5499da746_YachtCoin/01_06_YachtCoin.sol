// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract YachtCoin is ERC20, ReentrancyGuard {
    constructor() ERC20("Yacht Coin", "YACHT") {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
    }

    function airdrop(address[] calldata recipients, uint256[] calldata quantity) external nonReentrant {
        require(recipients.length == quantity.length, "UNEQUAL_ARRAY: length of recipients and quantity not equal!");

        uint256 cumulativeQuantity = 0;
        for( uint256 i = 0; i < recipients.length; ++i ){
            cumulativeQuantity += quantity[i];
        }
        uint256 existingTokenBalance = this.balanceOf(msg.sender);

        require(cumulativeQuantity <= existingTokenBalance, "NOT_ENOUGH_TOKEN_BALANCE: Not enough token held!");

        for( uint256 i = 0; i < recipients.length; ++i ){
            this.transferFrom(msg.sender, recipients[i], quantity[i]);
        }
    }
}