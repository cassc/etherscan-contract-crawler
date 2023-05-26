// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author Andrew Parker
/// @title Ghost Busters: Afterlife Traps NFT contract partial interface
/// @notice For viewer func, and also for MSP because Traps relies on OpenZepp and MSP uses pure 721 implementation.
interface IGBATrapsPartial{
    enum State { Paused, Whitelist, Public, Final}

    function useTrap(address owner) external;

    function tokensClaimed() external view returns(uint);
    function hasMinted(address minter) external view returns(bool);
    function saleStarted() external view returns(bool);
    function whitelistEndTime() external view returns(uint);
    function balanceOf(address _owner) external view returns (uint256);
    function mintState() external view returns(State);
    function countdown() external view returns(uint);
    function totalSupply() external view returns (uint256);
}