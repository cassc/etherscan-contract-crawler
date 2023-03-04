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
    function isNFTLiquidation() external view returns(bool);
    function extraRepayAmount() external view returns(uint);
    function seizeIndexes() external view returns(uint[] memory);
}