// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

// token
import "./swap/BEB20Token.sol";
import "./swap/TetherUSDToken.sol";
import "./swap/BUSDCoinToken.sol";
import "./helpers/Withdraw.sol";


contract Vendor is
    BEB20Token,
    TetherUSDToken,
    BUSDCoinToken,
    Withdraw
{
    constructor(
        address _TokenAddress,
        address _usdtTokenAddress,
        address _busdTokenAddress
    )
        BEB20Token(_TokenAddress)
        TetherUSDToken(_usdtTokenAddress, _TokenAddress)
        BUSDCoinToken(_busdTokenAddress, _TokenAddress)
    {}

    // This fallback/receive function
    // will keep all the Ether
    fallback() external payable {
        // Do nothing
    }

    receive() external payable {
        // Do nothing
    }
}