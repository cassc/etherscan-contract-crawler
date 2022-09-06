// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

interface ILendingMarket {
    struct PoolInfo {
        uint256 convexPid;
    }

    struct UserLending {
        bytes32 lendingId;
        uint256 token0;
        uint256 token0Price;
        uint256 lendingAmount;
        uint256 borrowAmount;
        uint256 borrowInterest;
        uint256 supportPid;
        int128 curveCoinId;
        uint256 borrowNumbers;
    }

    function deposit(uint256 _pid, uint256 _token0) external;

    function supplyBooster() external view returns (address);

    function convexBooster() external view returns (address);

    function borrowForDeposit(
        uint256 _pid,
        uint256 _token0,
        uint256 _borrowBlock,
        uint256 _supportPid
    ) external payable returns (bytes32);

    function borrow(
        uint256 _pid,
        uint256 _token0,
        uint256 _borrowBlock,
        uint256 _supportPid
    ) external payable;

    function getUserLastLending(address _user)
        external
        view
        returns (UserLending memory);

    function repayBorrow(bytes32 _lendingId) external payable;

    function repayBorrowERC20(bytes32 _lendingId, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _token0) external;

    function poolInfo(uint256 _pid) external view returns (PoolInfo memory);

    function getPoolSupportPid(uint256 _pid, uint256 _supportPid)
        external
        view
        returns (uint256);

    function getPoolSupportPids(uint256 _pid)
        external
        view
        returns (uint256[] memory);

    function getCurveCoinId(uint256 _pid, uint256 _supportPid)
        external
        view
        returns (int128);
}