// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IITEM {
    function mint(
        address _to,
        uint256 _dnaId,
        bool _isASZ
    ) external returns (uint256);
}