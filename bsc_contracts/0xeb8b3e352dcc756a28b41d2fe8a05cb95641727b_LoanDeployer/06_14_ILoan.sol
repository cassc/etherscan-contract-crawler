// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILoan {
    
    function owner() external view returns (address);
    function accept(address _borrower, uint256 _borrowAmount) external;
    function token() external view returns (address);
    function tokenAmount() external view returns (uint256);
    function duration() external view returns (uint8);
    function paymentPeriod() external view returns (uint8);
    function aPRInerestRate() external view returns (uint8);
    function status() external view returns (uint8);
    function getAcceptLoanMapLengthOf(address _borrower) external view returns (uint256);
    function initialize(
        address _governance, 
        address _owner, 
        address _token,
        uint256 _tokenAmount, 
        uint64 _duration, 
        uint64 _paymentPeriod, 
        uint8 _APRinterestRate,
        address _teamWallet
    ) external;

}