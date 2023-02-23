// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

interface IShell {
    function originSwap(
        address _origin,
        address _target,
        uint256 _originAmount,
        uint256 _minTargetAmount,
        uint256 _deadline
    ) external returns (uint256 targetAmount_);

    function targetSwap(
        address _origin,
        address _target,
        uint256 _maxOriginAmount,
        uint256 _targetAmount,
        uint256 _deadline
    ) external returns (uint256 originAmount_);
}