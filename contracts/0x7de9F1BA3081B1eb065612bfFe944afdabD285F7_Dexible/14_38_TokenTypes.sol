//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;



import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library TokenTypes {

    /**
     * Wrapper structure for token and an amount
     */
    struct TokenAmount {
        uint112 amount;
        IERC20 token;
    }
    
}