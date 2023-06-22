// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IPermissionlessPool {
    function preDepositOnBeaconChain(
        bytes[] calldata _pubkey,
        bytes[] calldata _preDepositSignature,
        uint256 _operatorId,
        uint256 _operatorTotalKeys
    ) external payable;

    function receiveRemainingCollateralETH() external payable;

    function getAllSocializingPoolOptOutOperators(uint256 _pageNumber, uint256 _pageSize)
        external
        view
        returns (address[] memory);
}