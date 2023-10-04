// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IVEGoMiningToken {

    function MAX_TIME() external view returns (uint256);

    function MULTIPLIER() external view returns (uint256);

    function WEEK() external view returns (uint256);

    function balanceOf(address addr, uint256 _t)
    external
    view
    returns (uint256);

    function balanceOf(address addr)
    external
    view
    returns (uint256);

    function balanceOfAt(address addr, uint256 _block)
    external
    view
    returns (uint256);

    function checkpoint() external;

    function createLock(uint256 value, uint256 _unlockTime) external;

    function decimals() external view returns (uint8);

    function depositFor(address addr, uint256 value) external;

    function epoch() external view returns (uint256);

    function getLastUserSlope(address addr) external view returns (int128);

    function increaseAmount(uint256 value) external;

    function increaseUnlockTime(uint256 _unlockTime) external;

    function locked(address) external view returns (int128 amount, uint256 end);

    function lockedEnd(address addr) external view returns (uint256);

    function name() external view returns (string memory);

    function pointHistory(uint256)
    external
    view
    returns (
        int128 bias,
        int128 slope,
        uint256 ts,
        uint256 blk
    );

    function slopeChanges(uint256) external view returns (int128);

    function supply() external view returns (uint256);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function totalSupply(uint256 t) external view returns (uint256);

    function totalSupplyAt(uint256 _block) external view returns (uint256);

    function futureTotalSupply() external view returns (uint256, int128[] memory);

    function userPointEpoch(address) external view returns (uint256);

    function userPointHistory(address, uint256)
    external
    view
    returns (
        int128 bias,
        int128 slope,
        uint256 ts,
        uint256 blk
    );

    function userPointHistoryAt(address addr, uint256 idx)
    external
    view
    returns (uint256);

    function version() external view returns (string memory);

    function withdraw() external;
}