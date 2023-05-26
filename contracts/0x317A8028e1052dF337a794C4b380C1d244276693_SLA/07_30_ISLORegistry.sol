// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

interface ISLORegistry {
    function getDeviation(
        uint256 _sli,
        address _slaAddress,
        uint256[] calldata _severity,
        uint256[] calldata _penalty
    ) external view returns (uint256);

    function isRespected(uint256 _value, address _slaAddress)
        external
        view
        returns (bool);
}