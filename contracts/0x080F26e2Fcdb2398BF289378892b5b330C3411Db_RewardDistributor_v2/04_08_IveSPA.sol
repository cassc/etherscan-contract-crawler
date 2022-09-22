pragma solidity 0.8.7;

interface IveSPA {
    function getLastUserSlope(address addr) external view returns (int128);

    function getUserPointHistoryTS(address addr, uint256 idx)
        external
        view
        returns (uint256);

    function userPointEpoch(address addr) external view returns (uint256);

    function checkpoint() external;

    function lockedEnd(address addr) external view returns (uint256);

    function depositFor(address addr, uint128 value) external;

    function createLock(
        uint128 value,
        uint256 unlockTime,
        bool autoCooldown
    ) external;

    function increaseAmount(uint128 value) external;

    function increaseUnlockTime(uint256 unlockTime) external;

    function initiateCooldown() external;

    function withdraw() external;

    function balanceOf(address addr, uint256 ts)
        external
        view
        returns (uint256);

    function balanceOf(address addr) external view returns (uint256);

    function balanceOfAt(address, uint256 blockNumber)
        external
        view
        returns (uint256);

    function totalSupply(uint256 ts) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalSupplyAt(uint256 blockNumber) external view returns (uint256);
}
