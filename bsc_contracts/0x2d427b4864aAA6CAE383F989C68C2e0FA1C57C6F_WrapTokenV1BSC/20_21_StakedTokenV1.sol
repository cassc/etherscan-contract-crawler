/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2022 Coinbase, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.6.12;

import { FiatTokenV2_1 } from "centre-tokens/contracts/v2/FiatTokenV2_1.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title StakedTokenV1
 * @notice ERC20 token backed by staked cryptocurrency reserves, version 1
 */
contract StakedTokenV1 is FiatTokenV2_1 {
    /**
     * @dev The unit of exchangeRate
     */
    uint256 private constant _EXCHANGE_RATE_UNIT = 1e18;
    /**
     * @dev Storage slot with the address of the current oracle.
     * This is the keccak-256 hash of "org.binance.stakedToken.exchangeRateOracle"
     */
    bytes32 private constant _EXCHANGE_RATE_ORACLE_POSITION = keccak256(
        "org.binance.stakedToken.exchangeRateOracle"
    );
    /**
     * @dev Storage slot with the current exchange rate.
     * This is the keccak-256 hash of "org.binance.stakedToken.exchangeRate"
     */
    bytes32 private constant _EXCHANGE_RATE_POSITION = keccak256(
        "org.binance.stakedToken.exchangeRate"
    );
    /**
     * @dev Storage slot with the current eth receiver.
     * This is the keccak-256 hash of "org.binance.stakedToken.ethReceiver"
     */
    bytes32 private constant _ETH_RECEIVER_POSITION = keccak256(
        "org.binance.stakedToken.ethReceiver"
    );
    /**
     * @dev Storage slot with the operator.
     * This is the keccak-256 hash of "org.binance.stakedToken.operator"
     */
    bytes32 private constant _OPERATOR_POSITION = keccak256(
        "org.binance.stakedToken.operator"
    );

    /**
     * @dev Emitted when the oracle is updated
     * @param newOracle The address of the new oracle
     */
    event OracleUpdated(address indexed newOracle);

    /**
     * @dev Emitted when the exchange rate is updated
     * @param oracle The address initiating the exchange rate update
     * @param newExchangeRate The new exchange rate
     */
    event ExchangeRateUpdated(address indexed oracle, uint256 newExchangeRate);

    /**
     * @dev Emitted when the ethReceiver is updated
     * @param previousReceiver The previous ethReceiver
     * @param newReceiver The new ethReceiver
     */
    event EthReceiverUpdated(address indexed previousReceiver, address indexed newReceiver);

    /**
     * @dev Emitted when the Operator is updated
     * @param previousOperator The previous Operator
     * @param newOperator The new Operator
     */
    event OperatorUpdated(address indexed previousOperator, address indexed newOperator);

    /**
     * @dev Emitted when the user deposit ETH for wBETH
     * @param user The address depositing ETH
     * @param ethAmount The ETH amount that the user deposited
     * @param wBETHAmount The wBETH amount that the user received
     * @param referral The referral address
     */
    event DepositEth(address indexed user, uint256 ethAmount, uint256 wBETHAmount, address indexed referral);

    /**
     * @dev Emitted when the operator supply ETH to this contract
     * @param supplier The supplier
     * @param ethAmount The ETH amount
     */
    event SuppliedEth(address indexed supplier, uint256 ethAmount);

    /**
     * @dev Emitted when the operator move ETH to the staking address
     * @param ethReceiver The staking address
     * @param ethAmount The ETH amount
     */
    event MovedToStakingAddress(address indexed ethReceiver, uint256 ethAmount);

    /**
     * @dev Throws if called by any account other than the oracle
     */
    modifier onlyOracle() {
        require(
            msg.sender == oracle(),
            "StakedTokenV1: caller is not the oracle"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than the operator
     */
    modifier onlyOperator() {
        require(
            msg.sender == operator(),
            "StakedTokenV1: caller is not the operator"
        );
        _;
    }

    receive() external payable {
        revert("please use deposit function to deposit ETH");
    }

    /**
     * @dev Function to mint tokens to msg.sender
     * @param amount to mint
     */
    function mint(uint256 amount)
        external
        onlyMinters
        returns (bool)
    {
        uint256 mintingAllowedAmount = minterAllowed[msg.sender];
        require(
            amount <= mintingAllowedAmount,
            "StakedTokenV1: mint amount exceeds minterAllowance"
        );

        _mint(msg.sender, amount);

        minterAllowed[msg.sender] = mintingAllowedAmount.sub(amount);
        return true;
    }

    /**
     * @dev Function to update the oracle
     * @param newOracle The new oracle
     */
    function updateOracle(address newOracle) external onlyOwner {
        require(
            newOracle != address(0),
            "StakedTokenV1: oracle is the zero address"
        );
        require(
            newOracle != oracle(),
            "StakedTokenV1: new oracle is already the oracle"
        );
        bytes32 position = _EXCHANGE_RATE_ORACLE_POSITION;
        assembly {
            sstore(position, newOracle)
        }
        emit OracleUpdated(newOracle);
    }

    /**
     * @dev Function to update the exchange rate
     * @param newExchangeRate The new exchange rate
     */
    function updateExchangeRate(uint256 newExchangeRate) external onlyOracle {
        require(
            newExchangeRate >= _EXCHANGE_RATE_UNIT,
            "StakedTokenV1: new exchange rate cannot be less than 1e18"
        );
        bytes32 position = _EXCHANGE_RATE_POSITION;
        assembly {
            sstore(position, newExchangeRate)
        }
        emit ExchangeRateUpdated(msg.sender, newExchangeRate);
    }

    /**
     * @dev Function to update the ethReceiver
     * @param newEthReceiver The new ETH receiver
     */
    function updateEthReceiver(address newEthReceiver) external onlyOwner {
        require(
            newEthReceiver != address(0),
            "StakedTokenV1: newEthReceiver is the zero address"
        );

        address currentReceiver = ethReceiver();
        require(newEthReceiver != currentReceiver, "StakedTokenV1: newEthReceiver is already the ethReceiver");

        bytes32 position = _ETH_RECEIVER_POSITION;
        assembly {
            sstore(position, newEthReceiver)
        }
        emit EthReceiverUpdated(currentReceiver, newEthReceiver);
    }

    /**
     * @dev Function to update the operator
     * @param newOperator The new operator
     */
    function updateOperator(address newOperator) external onlyOwner {
        require(
            newOperator != address(0),
            "StakedTokenV1: newOperator is the zero address"
        );

        address currentOperator = operator();
        require(newOperator != currentOperator, "StakedTokenV1: newOperator is already the operator");

        bytes32 position = _OPERATOR_POSITION;
        assembly {
            sstore(position, newOperator)
        }
        emit OperatorUpdated(currentOperator, newOperator);
    }

    /**
     * @dev Returns the address of the current oracle
     * @return _oracle The address of the oracle
     */
    function oracle() public view returns (address _oracle) {
        bytes32 position = _EXCHANGE_RATE_ORACLE_POSITION;
        assembly {
            _oracle := sload(position)
        }
    }

    /**
     * @dev Returns the current exchange rate scaled by by 10**18
     * @return _exchangeRate The exchange rate
     */
    function exchangeRate() public view returns (uint256 _exchangeRate) {
        bytes32 position = _EXCHANGE_RATE_POSITION;
        assembly {
            _exchangeRate := sload(position)
        }
    }

    /**
     * @dev Returns the current eth receiver
     * @return _ethReceiver The eth receiver
     */
    function ethReceiver() public view returns (address _ethReceiver) {
        bytes32 position = _ETH_RECEIVER_POSITION;
        assembly {
            _ethReceiver := sload(position)
        }
    }
    
    /**
     * @dev Returns the operator
     * @return _operator The operator
     */
    function operator() public view returns (address _operator) {
        bytes32 position = _OPERATOR_POSITION;
        assembly {
            _operator := sload(position)
        }
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint. Must be less than or equal
     * to the minterAllowance of the caller.
     * @return A boolean that indicates if the operation was successful.
     */
    function _mint(address _to, uint256 _amount)
    internal
    whenNotPaused
    notBlacklisted(msg.sender)
    notBlacklisted(_to)
    returns (bool)
    {
        require(_to != address(0), "StakedTokenV1: mint to the zero address");
        require(_amount > 0, "StakedTokenV1: mint amount not greater than 0");

        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);

        emit Mint(msg.sender, _to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }
}