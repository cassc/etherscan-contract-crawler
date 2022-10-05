//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./IBEP20.sol";

contract BalancesRequest {
    function getBalances(address _address, address[] calldata tokens) public view returns (uint256[256] memory) {
        require (tokens.length <= 256, "Too many tokens. Maximum is 256");
        uint256[256] memory balances;
        for (uint i = 0; i < tokens.length; i++) {
            balances[i] = IBEP20(tokens[i]).balanceOf(_address);
        }
        return balances;
    }
}