// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IERC2612Verifier {
    event OperatorUpdate(
        address account,
        address operator,
        bytes32 approvalType
    );

    function approve(
        address account,
        address operator,
        bytes32 approvalType,
        uint256 deadline
    ) external;

    function permit(
        address account,
        address operator,
        bytes32 approvalType,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function isTxPermitted(
        address account,
        address operator,
        address adapter
    ) external view returns (bool);

    function isTxPermitted(
        address account,
        address operator,
        uint256 operation
    ) external view returns (bool);
}