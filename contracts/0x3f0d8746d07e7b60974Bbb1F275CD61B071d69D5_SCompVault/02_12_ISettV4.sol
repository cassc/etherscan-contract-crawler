// SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

interface ISettV4 {
    function token() external view returns (address);

    function keeper() external view returns (address);

    function deposit(uint256) external;

    function depositFor(address, uint256) external;

    function depositAll() external;

    function withdraw(uint256) external;

    function withdrawAll() external;

    function earn() external;

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balance() external view returns (uint256);

    function claimInsurance() external; // NOTE: Only yDelegatedVault implements this

    function getPricePerFullShare() external view returns (uint256);
}