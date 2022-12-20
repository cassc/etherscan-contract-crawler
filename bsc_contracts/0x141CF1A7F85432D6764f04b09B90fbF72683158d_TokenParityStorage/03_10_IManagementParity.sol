// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "../main/libraries/SafeBEP20.sol";
import "./libraries/ParityData.sol"; 

interface IManagementParity {
    function sendTokenFee(ParityData.Amount memory _fee) external;
    function sendStableFee(address _account, uint256 _amount,  uint256 _fee) external;
    function indexEvent() external view returns (uint256);
    function sendBackWithdrawalFee(ParityData.Amount memory) external;
    function getStableBalance() external view returns (uint256) ;
    function getDepositFee(uint256 _amount) external view  returns (uint256);
    function getMinAmountDeposit() external view returns (uint256);
    function getTreasury() external view returns (address);
    function isManager(address _address) external view returns (bool);
    function getToken() external view returns (IBEP20, IBEP20, IBEP20);
    function getStableToken() external view returns(IBEP20);
    function amountScaleDecimals() external view returns(uint256);
    function getPrice() external view returns(uint256[3] memory);
    
}