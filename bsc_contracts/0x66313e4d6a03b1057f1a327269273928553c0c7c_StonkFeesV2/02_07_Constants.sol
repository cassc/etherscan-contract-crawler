// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Pancakeswap.sol";

library Constants {

    IPancakeRouter02 private constant _pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address private constant _WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private constant _BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address private constant _STONK = address(0xC2973496E7c568D6EEcBF1d4234A24aa2FD71bd8);

    function pancakeRouter() internal pure returns (IPancakeRouter02) {
        return _pancakeRouter;
    }

    function WBNB() internal pure returns (address) {
        return _WBNB;
    }

    function BUSD() internal pure returns (address) {
        return _BUSD;
    }

    function STONK() internal pure returns (address) {
        return _STONK;
    }

}
