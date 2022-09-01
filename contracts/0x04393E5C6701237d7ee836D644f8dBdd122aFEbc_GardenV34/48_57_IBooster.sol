// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IBooster {
    function depositAll(uint256 _pid, bool _stake) external returns (bool);

    function poolInfo(uint256)
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address,
            bool
        );

    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

    function withdrawAll(uint256 _pid) external returns (bool);

    function poolLength() external view returns (uint256);
}