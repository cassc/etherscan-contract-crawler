// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

interface IBabyBaseRouter {

    function factory() external view returns (address);
    function WETH() external view returns (address);
    function swapMining() external view returns (address);
    function routerFeeReceiver() external view returns(address);

}