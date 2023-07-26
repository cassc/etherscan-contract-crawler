// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./IFeralfileSaleData.sol";
import "./ECDSASigner.sol";

interface IFeralfileVault is IFeralfileSaleData {
    function payForSale(
        bytes32 r_,
        bytes32 s_,
        uint8 v_,
        SaleData calldata saleData_
    ) external;

    function withdrawFund(uint256 weiAmount) external;

    receive() external payable;
}