// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenAirdrop {
    
    using SafeERC20 for IERC20;

    function transferTokens(IERC20 token, address from, address[] calldata tos, uint256[] calldata amounts) public returns(bool) {        
        require(tos.length > 0 && tos.length == amounts.length, "Invalid inputs");
        for(uint i=0; i < tos.length; i ++) {
            token.safeTransferFrom(from, tos[i], amounts[i]);
        }
        return true;
    }
}