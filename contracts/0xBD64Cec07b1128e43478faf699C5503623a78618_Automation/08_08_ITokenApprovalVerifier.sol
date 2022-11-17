// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface ITokenApprovalVerifier {
    event ApprovalUpdate(address account, address[] spenders, bool isAllowed);

    function approve(
        address account,
        address[] memory spenders,
        bool enable,
        uint256 deadline
    ) external;

    function permit(
        address account,
        address[] memory spenders,
        bool enable,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function isWhitelisted(address account, address operator)
        external
        view
        returns (bool);
}