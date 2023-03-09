// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface IHedgepieInvestorBsc {
    function ybnft() external view returns (address);

    function treasury() external view returns (address);

    function adapterManager() external view returns (address);

    function adapterInfo() external view returns (address);

    function updateFunds(uint256 _tokenId) external;
}