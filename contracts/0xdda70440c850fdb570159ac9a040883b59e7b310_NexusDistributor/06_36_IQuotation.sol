// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IQuotation {
    function verifyCoverDetails(
        address payable from,
        address scAddress,
        bytes4 coverCurr,
        uint256[] calldata coverDetails,
        uint16 coverPeriod,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function createCover(
        address payable from,
        address scAddress,
        bytes4 currency,
        uint256[] calldata coverDetails,
        uint16 coverPeriod,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function makeCoverUsingNXMTokens(
        uint256[] calldata coverDetails,
        uint16 coverPeriod,
        bytes4 coverCurr,
        address smartCAdd,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;
}