// contracts/TokenPresale.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TokenPresale
 */
contract TokenPresaleTest is Ownable {

    using SafeERC20 for IERC20;


    IERC20 immutable private liquidityToken;
    address private masterWallet;

    constructor(
        address liquidityToken_,
        address masterWallet_
        ) {
        require(liquidityToken_ != address(0x0));
        liquidityToken = IERC20(liquidityToken_);
        masterWallet = masterWallet_;
    }

    function getLiquidityToken()
    external
    view
    returns(address){
        return address(liquidityToken);
    }

    function buyTest() public {
        require(
            liquidityToken.transferFrom(msg.sender, masterWallet, 10000000000000000) // pay 0.01 USDT
        );
    }
}