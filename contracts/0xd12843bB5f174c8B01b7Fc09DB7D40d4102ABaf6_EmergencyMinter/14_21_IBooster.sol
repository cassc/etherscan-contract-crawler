// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IBooster {
    function poolInfo(uint256 pid)
        external
        view
        returns (
            address lpToken,
            address token,
            address gauge,
            address crvRewards,
            address stash,
            bool shutdown
        );

    function poolLength() external view returns (uint256);

    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

    function withdrawAll(uint256 _pid) external returns (bool);

    function depositAll(uint256 _pid, bool _stake) external returns (bool);

    function earmarkRewards(uint256 _pid) external returns (bool);

    function isShutdown() external view returns (bool);
}