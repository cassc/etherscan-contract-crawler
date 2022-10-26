// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

abstract contract ComptrollerExInterface {
    function liquidateCalculateSeizeTokensEx(
        address cTokenBorrowed,
        address cTokenExCollateral,
        uint repayAmount) external virtual returns (uint, uint, uint);

    function getLiquidationSeizeIndexes() external view virtual returns (uint[] memory) {}
}
 
interface ILiquidationProxy {
    function isNFTLiquidation() external view virtual returns(bool);
    function extraRepayAmount() external view virtual returns(uint);
    function seizeIndexes() external view virtual returns(uint[] memory);
}