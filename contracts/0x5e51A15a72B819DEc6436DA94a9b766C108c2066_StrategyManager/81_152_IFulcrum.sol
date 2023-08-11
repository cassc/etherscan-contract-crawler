// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IFulcrum {
    function mint(address receiver, uint256 depositAmount) external;

    function burn(address receiver, uint256 burnAmount) external;

    function tokenPrice() external view returns (uint256);

    function loanTokenAddress() external view returns (address);

    function decimals() external view returns (uint256);

    function assetBalanceOf(address holder) external view returns (uint256);

    function marketLiquidity() external view returns (uint256);

    function balanceOf(address _holder) external view returns (uint256);
}