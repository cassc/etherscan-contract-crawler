// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPIDController{
    function bucket1() external view returns (bool);
    function bucket2() external view returns (bool);
    function bucket3() external view returns (bool);
    function diff1() external view returns (uint);
    function diff2() external view returns (uint);
    function diff3() external view returns (uint);
    function amountpaid1() external view returns (uint);
    function amountpaid2() external view returns (uint);
    function amountpaid3() external view returns (uint);
    function bankx_arbi_limit() external view returns (uint);
    function xsd_arbi_limit() external view returns (uint);
    function bankx_burnable_limit() external view returns (uint);
    function xsd_burnable_limit() external view returns (uint);
    function amountPaidBankXWETH(uint ethvalue) external;
    function amountPaidXSDWETH(uint ethvalue) external;
    function amountPaidCollateralPool(uint ethvalue) external;
}