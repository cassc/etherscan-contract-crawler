//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

interface IRainCollateral {
    function isAdmin(address) external view returns (bool);

    function withdrawAsset(
        address,
        address,
        uint256
    ) external;
}