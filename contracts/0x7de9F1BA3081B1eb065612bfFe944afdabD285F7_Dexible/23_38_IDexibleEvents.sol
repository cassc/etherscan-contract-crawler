//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IDexibleEvents {

    event SwapFailed(address indexed trader, 
                     address feeToken, 
                     uint gasFeePaid);
    event SwapSuccess(address indexed trader,
                        address indexed affiliate,
                        uint inputAmount,
                        uint outputAmount,
                        address feeToken,
                        uint gasFee,
                        uint affiliateFee,
                        uint dexibleFee);
    event AffiliatePaid(address indexed affiliate, address token, uint amount);

    event PaidGasFunds(address indexed relay, uint amount);
    event InsufficientGasFunds(address indexed relay, uint amount);
    event ChangedRevshareVault(address indexed old, address indexed newRevshare);
    event ChangedRevshareSplit(uint8 split);
    event ChangedBpsRates(uint32 stdRate, uint32 minRate);
    
}