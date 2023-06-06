// SPDX-License-Identifier: Unlicense
// Developed by EasyChain Blockchain Development Team (easychain.tech)
//
pragma solidity ^0.8.4;

import "./api/IAgent.sol";
import "./api/ITokens.sol";
import "./common/BerezkaOracleClient.sol";
import "./common/BerezkaDaoManager.sol";
import "./common/BerezkaStableCoinManager.sol";

// This contract provides Withdraw function for Berezka DAO
// Basic flow is:
//  1. User obtains signed price data from trusted off-chain Oracle
//  2. Exchange rate is computed
//  3. User's tokens are burned (no approval need thanks to Aragon)
//  4. Stable coins are transferred to user
//
contract BerezkaWithdraw is
    BerezkaOracleClient,
    BerezkaDaoManager,
    BerezkaStableCoinManager
{
    // Events
    event WithdrawSuccessEvent(
        address indexed daoToken,
        uint256 daoTokenAmount,
        address indexed stableToken,
        uint256 stableTokenAmount,
        address indexed sender,
        uint256 price,
        uint256 timestamp
    );

    // Main function. Allows user (msg.sender) to withdraw funds from DAO.
    // _amount - amount of DAO tokens to exhange
    // _token - token of DAO to exchange
    // _targetToken - token to receive in exchange
    // _optimisticPrice - an optimistic price of DAO token. Used to check if DAO Agent
    //                    have enough funds on it's balance. Is not used to calculare
    //                    use returns
    function withdraw(
        uint256 _amount,
        address _token,
        address _targetToken,
        uint256 _optimisticPrice,
        uint256 _optimisticPriceTimestamp,
        bytes memory _signature
    )
        public
        withValidOracleData(
            _token,
            _optimisticPrice,
            _optimisticPriceTimestamp,
            _signature
        )
        isWhitelisted(_targetToken)
    {
        // Require that amount is positive
        //
        require(_amount > 0, "ZERO_TOKEN_AMOUNT");

        _checkUserBalance(_amount, _token, msg.sender);

        // Require that an agent have funds to fullfill request (optimisitcally)
        // And that this contract can withdraw neccesary amount of funds from agent
        //
        uint256 optimisticAmount = computeExchange(
            _amount,
            _optimisticPrice,
            _targetToken
        );
        
        _doWithdraw(
            _amount,
            _token,
            _targetToken,
            msg.sender,
            optimisticAmount
        );

        // Emit withdraw success event
        //
        emit WithdrawSuccessEvent(
            _token,
            _amount,
            _targetToken,
            optimisticAmount,
            msg.sender,
            _optimisticPrice,
            _optimisticPriceTimestamp
        );
    }

    function _doWithdraw(
        uint256 _amount,
        address _token,
        address _targetToken,
        address _user,
        uint256 _optimisticAmount
    ) internal {
        address agentAddress = _agentAddress(_token);
        
        IERC20 targetToken = IERC20(_targetToken);
        require(
            targetToken.balanceOf(agentAddress) >= _optimisticAmount,
            "INSUFFICIENT_FUNDS_ON_AGENT"
        );

        // Perform actual exchange
        //
        IAgent agent = IAgent(agentAddress);
        agent.transfer(_targetToken, _user, _optimisticAmount);

        // Burn tokens
        //
        ITokens tokens = ITokens(daoConfig[_token].tokens);
        tokens.burn(_user, _amount);
    }

    function _checkUserBalance(
        uint256 _amount,
        address _token,
        address _user
    ) internal view {
        // Check DAO token balance on iuser
        //
        IERC20 token = IERC20(_token);
        require(
            token.balanceOf(_user) >= _amount,
            "NOT_ENOUGH_TOKENS_TO_BURN_ON_BALANCE"
        );
    }
}