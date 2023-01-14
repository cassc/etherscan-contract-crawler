// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHWRegistry {
    struct Whitelist {
        address token;
        uint256 maxAllowed;
    }

    function isWhitelisted(address _address) external view returns (bool);

    function isAllowedAmount(
        address _address,
        uint256 _amount
    ) external view returns (bool);

    function allWhitelisted() external view returns (Whitelist[] memory);

    function counter() external view returns (uint256);
}