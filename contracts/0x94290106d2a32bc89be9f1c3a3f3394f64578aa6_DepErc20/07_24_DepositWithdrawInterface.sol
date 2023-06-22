// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./EIP20NonStandardInterface.sol";

interface ICompoundV2 {
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function balanceOf(address owner) external view returns (uint256);
    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function exchangeRateStored() external view returns (uint);
}

interface INNERIERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

interface DepositWithdrawInterface {

    //function setAddresses(address depoAddr_, address leveAddr_) external;
    //function getCUSDTNumber() external view returns (uint);
    //function getCmpUSDTBalance() external view returns (uint);
    //function getCUSDCNumber() external view returns (uint);
    //function getCmpUSDCBalance() external view returns (uint);
    //function supplyUSDC(uint amount) external;
    //function withdrawcUSDC(uint amount) external;
    //function supplyUSDT2Cmp(uint amount) external;
    //function withdrawcUSDT(uint amount) external;
    //function withdrawUSDTfromCmp(uint amount) external;
    //function getCmpUSDTBorrowRate() external view returns (uint);
    //function getUSDTSupplyRate() external view returns (uint);
}