// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IAltL1Bridge {
    event WithdrawalInitiated(
        address indexed _l1Token,
        address indexed _l2Token,
        address indexed _from,
        address _to,
        uint256 _amount,
        bytes _data
    );

    event DepositFinalized(
        address indexed _l1Token,
        address indexed _l2Token,
        address indexed _from,
        address _to,
        uint256 _amount,
        bytes _data
    );

    function withdraw(
        address _l2Token,
        uint256 _amount,
        address _zroPaymentAddress,
        bytes memory _adapterParams,
        bytes calldata _data
    ) external payable;

    function withdrawTo(
        address _l2Token,
        address _to,
        uint256 _amount,
        address _zroPaymentAddress,
        bytes memory _adapterParams,
        bytes calldata _data
    ) external payable;
}