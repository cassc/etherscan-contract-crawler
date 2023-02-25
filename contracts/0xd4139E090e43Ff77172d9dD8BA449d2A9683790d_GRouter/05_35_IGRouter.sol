// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

interface IGRouter {
    function deposit(
        uint256 _amount,
        uint256 _token_index,
        bool _tranche,
        uint256 _minAmount
    ) external returns (uint256 amount);

    function depositWithPermit(
        uint256 _amount,
        uint256 _token_index,
        bool _tranche,
        uint256 _minAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amount);

    function depositWithAllowedPermit(
        uint256 _amount,
        uint256 _token_index,
        bool _tranche,
        uint256 _minAmount,
        uint256 deadline,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amount);

    function withdraw(
        uint256 _amount,
        uint256 _token_index,
        bool _tranche,
        uint256 _minAmount
    ) external returns (uint256 amount);

    function depositPwrd(
        uint256[3] memory inAmounts,
        uint256 minAmount,
        address _referral
    ) external;

    function depositGvt(
        uint256[3] memory inAmounts,
        uint256 minAmount,
        address _referral
    ) external;

    function withdrawByStablecoin(
        bool pwrd,
        uint256 index,
        uint256 lpAmount,
        uint256 minAmount
    ) external;
}