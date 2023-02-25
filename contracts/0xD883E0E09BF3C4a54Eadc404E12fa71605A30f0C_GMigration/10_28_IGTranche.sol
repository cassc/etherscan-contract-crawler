// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

interface IGTranche {
    function deposit(
        uint256 _amount,
        uint256 _index,
        bool _tranche,
        address recipient
    ) external returns (uint256, uint256);

    function withdraw(
        uint256 _amount,
        uint256 _index,
        bool _tranche,
        address recipient
    ) external returns (uint256, uint256);

    function finalizeMigration() external;

    function utilisationThreshold() external view returns (uint256);
}