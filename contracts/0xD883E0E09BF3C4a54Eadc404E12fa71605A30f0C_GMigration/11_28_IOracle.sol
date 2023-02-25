// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

interface IOracle {
    function getSwappingPrice(
        uint256 _i,
        uint256 _j,
        uint256 _amount,
        bool _deposit
    ) external view returns (uint256);

    function getSinglePrice(
        uint256 _i,
        uint256 _amount,
        bool _deposit
    ) external view returns (uint256);

    function getTokenAmount(
        uint256 _i,
        uint256 _amount,
        bool _deposit
    ) external view returns (uint256);

    function getTotalValue(uint256[] memory _amount)
        external
        view
        returns (uint256);
}