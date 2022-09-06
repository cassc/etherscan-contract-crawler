// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IEthBridge {
    event ERC20DepositInitiated(
        address indexed _l1Token,
        address indexed _l2Token,
        address indexed _from,
        address _to,
        uint256 _amount,
        bytes _data
    );

    event ERC20WithdrawalFinalized(
        address indexed _l1Token,
        address indexed _l2Token,
        address indexed _from,
        address _to,
        uint256 _amount,
        bytes _data
    );

    function depositERC20(
        address _l1Token,
        address _l2Token,
        uint256 _amount,
        address _zroPaymentAddress,
        bytes memory _adapterParams,
        bytes calldata _data
    ) external payable;

    function depositERC20To(
        address _l1Token,
        address _l2Token,
        address _to,
        uint256 _amount,
        address _zroPaymentAddress,
        bytes memory _adapterParams,
        bytes calldata _data
    ) external payable;
}