// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface SwapRouterV2 {
    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}

contract PriceContract is Initializable {
    address swapRouterV2Address;
    address[] tokenAddresses;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        swapRouterV2Address = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        tokenAddresses = [
            0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c, // BNB
            0x55d398326f99059fF775485246999027B3197955 // USDT
        ];
    }
    
    function getPrice() public view returns (uint256) {
        return
            SwapRouterV2(swapRouterV2Address).getAmountsOut(
                1 ether,
                tokenAddresses
            )[1];
    }
}