// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IConvexBooster {
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

    function poolLength() external view returns (uint256);

    function depositAll(uint256 _pid, bool _stake) external returns (bool);

    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

    function withdrawTo(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external returns (bool);
}