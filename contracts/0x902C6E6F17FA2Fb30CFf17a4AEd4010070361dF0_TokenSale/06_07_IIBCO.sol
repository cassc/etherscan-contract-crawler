// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IIBCO {

    function softCapStatus() external view returns(bool);
    function closed() external view returns(bool);    
    function purchase(uint blxAmount, uint maxUsdc, address referrer, address sender, bool collectFee) external;
    function ibcoEnd() external returns (uint);
    function started() external returns (bool);
}