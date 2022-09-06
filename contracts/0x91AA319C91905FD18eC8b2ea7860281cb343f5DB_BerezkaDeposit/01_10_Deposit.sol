// SPDX-License-Identifier: Unlicense
// Developed by EasyChain Blockchain Development Team (easychain.tech)
//
pragma solidity ^0.8.4;

import "./api/IAgent.sol";
import "./api/ITokens.sol";
import "./common/BerezkaOracleClient.sol";
import "./common/BerezkaDaoManager.sol";
import "./common/BerezkaStableCoinManager.sol";

// This contract provides Deposit function for Berezka DAO
// Basic flow is:
//  1. User obtains signed price data from trusted off-chain Oracle
//  2. Exchange rate is computed
//  3. User's stable coins are transferred to agent
//  4. DAO tokens are minted to user
//
contract BerezkaDeposit is
    BerezkaOracleClient,
    BerezkaDaoManager,
    BerezkaStableCoinManager
{
    // Events
    event DepositSuccessEvent(
        address indexed daoToken,
        uint256 daoTokenAmount,
        address indexed stableToken,
        uint256 stableTokenAmount,
        address indexed sender,
        uint256 price,
        uint256 timestamp,
        string ref
    );

    struct DepositData {
        uint256 amount;
        address token;
        address targetToken;
        uint256 optimisticPrice;
        uint256 optimisticPriceTimestamp;
        bytes signature;
        string ref;
        address sender;
    }

    // Main function. Allows user (msg.sender) to deposit funds to DAO.
    // _amount - amount of DAO tokens to recieve
    // _token - token of DAO to exchange
    // _targetToken - token to receive in exchange
    // _optimisticPrice - an optimistic price of DAO token. Used to check if DAO Agent
    //                    have enough funds on it's balance. Is not used to calculare
    //                    use returns
    function deposit(
        uint256 _amount,
        address _token,
        address _targetToken,
        uint256 _optimisticPrice,
        uint256 _optimisticPriceTimestamp,
        bytes memory _signature,
        string memory _ref
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

        DepositData memory data = DepositData({
            amount: _amount,
            token: _token,
            targetToken: _targetToken,
            optimisticPrice: _optimisticPrice,
            optimisticPriceTimestamp: _optimisticPriceTimestamp,
            signature: _signature,
            ref: _ref,
            sender: msg.sender
        });

        _deposit(data);
    }

    function _deposit(DepositData memory _data) internal {
        // Require that user have funds to fullfill request (optimisitcally)
        // And that this contract can receive neccesary amount of funds from user
        //
        uint256 optimisticAmount = computeExchange(
            _data.amount,
            _data.optimisticPrice,
            _data.targetToken
        );

        _doDeposit(
            _data.amount, 
            _data.token, 
            _data.targetToken, 
            _data.sender, 
            optimisticAmount
        );

        // Emit deposit success event
        //
        emit DepositSuccessEvent(
            _data.token,
            _data.amount,
            _data.targetToken,
            optimisticAmount,
            _data.sender,
            _data.optimisticPrice,
            _data.optimisticPriceTimestamp,
            _data.ref
        );
    }

    function _doDeposit(
        uint256 _amount,
        address _token,
        address _targetToken,
        address _user,
        uint256 _optimisticAmount
    ) internal {
        address agentAddress = _agentAddress(_token);

        IERC20 targetToken = IERC20(_targetToken);
        
        // Perform actual exchange
        //
        targetToken.transferFrom(_user, agentAddress, _optimisticAmount);

        // Mint tokens
        //
        ITokens tokens = ITokens(daoConfig[_token].tokens);
        tokens.mint(_user, _amount);
    }
}