pragma solidity ^0.8.4;

interface ILidoFinance {
    function submit(address _referral) external payable returns (uint256);
}