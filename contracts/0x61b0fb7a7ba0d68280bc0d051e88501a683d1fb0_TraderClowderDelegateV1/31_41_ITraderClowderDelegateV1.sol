// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.13;

interface ITraderClowderDelegateV1 {
    function createNewClone(
        address[] memory accounts,
        uint256[] memory contributions,
        uint256 totalContributions
    ) external returns (address);
}