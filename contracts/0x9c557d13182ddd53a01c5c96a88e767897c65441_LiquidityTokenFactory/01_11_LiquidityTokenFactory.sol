// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./StandardToken.sol";
import "./LiquidityToken.sol";

contract LiquidityTokenFactory {
    function deploy(
        address router_address,
        address creator_,
        address reciever,
        string memory name_,
        string memory symbol_,
        uint8 decimal_,
        uint256 supply
    ) external returns (LiquidityToken) {
        return
            new LiquidityToken(
                creator_,
                router_address,
                reciever,
                decimal_,
                supply,
                name_,
                symbol_
            );
    }
}