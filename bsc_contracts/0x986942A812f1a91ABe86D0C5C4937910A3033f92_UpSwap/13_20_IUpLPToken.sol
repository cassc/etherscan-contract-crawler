// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "contracts/interfaces/IUpSwapPair.sol";

interface IUpLPToken {
    /** `underlying` backing asset for upToken */
    function underlying() external returns (IUpSwapPair);

    /** Approves `spender` to transfer `amount` tokens from caller */
    function approve(address spender, uint256 amount) external returns (bool);

    /** Transfer Function */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /** 
        Mint Tokens For `recipient` By Depositing Underlying Into The Contract
        Requirements: Approval from the Underlying prior to purchase
        
        @param numTokens number of Underlying tokens to mint UP Token with
        @param recipient Account to receive minted UP tokens
        @return tokensMinted number of UP tokens minted
    */
    function mintWithBacking(uint256 numTokens, address recipient) external returns (uint256);

    /**
        Mint Tokens With The Native Token
        This will purchase Underlying with BNB received
        It will then mint tokens to `recipient` based on the number of stable coins received
        `minOut` should be set to avoid the Transaction being front runned

        @param recipient Account to receive minted UP Tokens
        @param minOut minimum amount out from BNB -> Underlying - prevents front run attacks
        @return received number of UP tokens received
    */
    function mintWithNative(address recipient, uint256 minOut) external payable returns (uint256);

    /** 
        Burns Sender's UP Tokens and redeems their value in Underlying Asset
        @param tokenAmount Number of UP Tokens To Redeem, Must be greater than 0
    */
    function sell(uint256 tokenAmount) external returns (uint256);

    /** 
        Burns Sender's UP Tokens and redeems their value in Underlying for `recipient`
        @param tokenAmount Number of UP Tokens To Redeem, Must be greater than 0
        @param recipient Recipient Of Underlying transfer, Must not be address(0)
    */
    function sellTo(uint256 tokenAmount, address recipient) external returns (uint256);
}