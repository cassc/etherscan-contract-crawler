// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;



interface IOps {
    function createTaskNoPrepayment(
        address _execAddr,
        bytes4 _execSelector,
        address _resolverAddr,
        bytes calldata _resolverData,
        address _feeToken
    ) external returns(bytes32 task);

    function getFeeDetails() external view returns (uint256, address);

    function gelato() external view returns (address payable);

    function getResolverHash(
        address _resolverAddress,
        bytes memory _resolverData
    ) external pure returns (bytes32);

    function exec(
        uint256 _txFee,
        address _feeToken,
        address _taskCreator,
        bool _useTaskTreasuryFunds,
        bool _revertOnFailure,
        bytes32 _resolverHash,
        address _execAddress,
        bytes calldata _execData
    ) external;

    function taskCreator(bytes32 taskId) external view returns(address);
}