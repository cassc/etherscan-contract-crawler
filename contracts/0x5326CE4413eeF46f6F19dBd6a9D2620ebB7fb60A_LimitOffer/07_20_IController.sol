// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IController {
    function admins(address) external view returns(bool);
    function ttl() external view returns(uint256);
    function lockTime() external view returns(uint256);
    function minCollateralRatio() external view returns(uint16);
    function maxCollateralRatio() external view returns(uint16);
    function calculationDecimal() external pure returns(uint16);
    function discountRates(address) external view returns(uint16);
    function acceptedCollateral(address) external view returns(bool);
    function mintContract() external view returns(address);
    function lockContract() external view returns(address);
    function limitOfferContract() external view returns(address);
    function router() external view returns(address);
    function oracles(address) external view returns(address);
    function pools(address) external view returns(address);
    function collateralForToken(address) external view returns(address);
    function tokenForOracle(address) external view returns(address);
    function royaltyFeeRatio() external view returns(uint256);
    function recieverAddress() external view returns(address);
}