//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IStorageView {

    /**
     * Storage variable view functions
     */
    function isFeeTokenAllowed(address tokens) external view returns (bool);
    function discountBps() external view returns(uint32);
    function dailyVolumeUSD() external view returns(uint);
    function paused() external view returns (bool);
    function adminMultiSig() external view returns (address);
    function dxblToken() external view returns (address);
    function dexibleContract() external view returns (address);
    function wrappedNativeToken() external view returns (address);
    function timelockSeconds() external view returns (uint32);
    function baseMintThreshold() external view returns (uint);
}