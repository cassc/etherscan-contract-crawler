// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * @title Invest proxy contract
 * @author Pino development team
 * @notice Interacts with Lido and SavingsDai
 */
interface IInvest {
    /**
     * @notice Emitted when a token is deposited
     * @param _caller Address of the caller of the transaction
     * @param _recipient The recipient that received the tokens
     * @param _fromToken Address of the token that was sent
     * @param _toToken Address of the token that was received
     * @param _amount Amount of the sent token
     */
    event Deposit(address _caller, address _recipient, address _fromToken, address _toToken, uint256 _amount);

    /**
     * @notice Sends ETH to the Lido protocol and transfers ST_ETH to the recipient
     * @param _proxyFeeInWei Fee of the proxy contract
     * @param _recipient The destination address that will receive ST_ETH
     * @return steth Amount of ST_ETH token that is being transferred to the recipient
     */
    function ethToStETH(address _recipient, uint256 _proxyFeeInWei) external payable returns (uint256 steth);

    /**
     * @notice Converts ETH to WST_ETH and transfers WST_ETH to the recipient
     * @param _proxyFeeInWei Fee of the proxy contract
     * @param _recipient The destination address that will receive WST_ETH
     */
    function ethToWstETH(address _recipient, uint256 _proxyFeeInWei) external payable;

    /**
     * @notice Submits WETH to Lido protocol and transfers ST_ETH to the recipient
     * @param _amount Amount of WETH to submit to ST_ETH contract
     * @param _recipient The destination address that will receive ST_ETH
     * @dev For security reasons, it is not possible to run functions
     * inside of this function separately through a multicall
     * @return stethAmount Amount of ST_ETH token that is being transferred to msg.sender
     */
    function wethToStETH(uint256 _amount, address _recipient) external payable returns (uint256 stethAmount);

    /**
     * @notice Submits WETH to Lido protocol and transfers WST_ETH to msg.sender
     * @param _amount Amount of WETH to submit to get WST_ETH
     * @param _recipient The destination address that will receive WST_ETH
     */
    function wethToWstETH(uint256 _amount, address _recipient) external payable;

    /**
     * @notice Wraps ST_ETH to WST_ETH and transfers it to msg.sender
     * @param _amount Amount to convert to WST_ETH
     * @param _recipient The destination address that will receive WST_ETH
     * @return wrapped The amount of wrapped WstETH token
     */
    function stETHToWstETH(uint256 _amount, address _recipient) external payable returns (uint256 wrapped);

    /**
     * @notice Unwraps WST_ETH to ST_ETH and transfers it to the recipient
     * @param _amount Amount of WstETH to unwrap
     * @param _recipient The destination address that will receive StETH
     * @return unwrapped The amount of StETH unwrapped
     */
    function wstETHToStETH(uint256 _amount, address _recipient) external payable returns (uint256 unwrapped);

    /**
     * @notice Transfers DAI to SavingsDai and transfers SDai to the recipient
     * @param _amount Amount of DAI to invest
     * @param _recipient The destination address that will receive StETH
     * @return deposited Returns the amount of shares that recipient received after deposit
     */
    function daiToSDai(uint256 _amount, address _recipient) external payable returns (uint256 deposited);

    /**
     * @notice Transfers SDAI to SavingsDai and transfers Dai to the recipient
     * @param _amount Amount of SDAI to withdraw
     * @param _recipient The destination address that will receive DAI
     * @return withdrew Returns the amount of shares that were burned
     */
    function sDaiToDai(uint256 _amount, address _recipient) external payable returns (uint256 withdrew);
}