// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

interface IZaynVaultV2 {
    function totalSupply() external view returns (uint256);
    function depositZap(uint256 amount, address _user, address _referrer) external;
    function withdrawZap(uint256 shares, address _user) external;
    function want() external pure returns (address);
    function balance() external pure returns (uint256);
    function strategy() external pure returns (address);
}