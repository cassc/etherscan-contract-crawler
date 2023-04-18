// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Oracle {
    address public pairAddress;
    address public stableToken;
    address public token;

    constructor(address _pairAddress, address _stableToken, address _token) {
        pairAddress = _pairAddress;
        stableToken = _stableToken;
        token = _token;
    }

    function getInfoOfPair() public view returns (uint256, uint256) {
        uint256 balanceStableToken = ERC20(stableToken).balanceOf(pairAddress);
        uint256 balanceToken = ERC20(token).balanceOf(pairAddress);
        return (balanceStableToken, balanceToken);
    }

    //function to convert amount in usd to token amount
    function convertUsdBalanceDecimalToTokenDecimal(
        uint256 _balanceUsdDecimal
    ) public view returns (uint256) {
        uint256 amountTokenDecimal = 0;
        //get price token in pair
        (uint256 balanceStableToken, uint256 balanceToken) = getInfoOfPair();
        amountTokenDecimal = (_balanceUsdDecimal * balanceToken) / balanceStableToken;
        return amountTokenDecimal;
    }
}