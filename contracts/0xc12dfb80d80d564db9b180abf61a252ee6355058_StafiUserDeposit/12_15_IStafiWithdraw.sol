pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

interface IStafiWithdraw {
    // user

    function unstake(uint256 _rEthAmount) external;

    function withdraw(uint256[] calldata _withdrawIndexList) external;

    // ejector
    function notifyValidatorExit(
        uint256 _withdrawCycle,
        uint256 _ejectedStartWithdrawCycle,
        uint256[] calldata _validatorIndex
    ) external;

    // voter
    function distributeWithdrawals(
        uint256 _dealedHeight,
        uint256 _userAmount,
        uint256 _nodeAmount,
        uint256 _platformAmount,
        uint256 _maxClaimableWithdrawIndex
    ) external;

    function reserveEthForWithdraw(uint256 _withdrawCycle) external;

    function depositEth() external payable;

    function getUnclaimedWithdrawalsOfUser(address user) external view returns (uint256[] memory);

    function getEjectedValidatorsAtCycle(uint256 cycle) external view returns (uint256[] memory);
}