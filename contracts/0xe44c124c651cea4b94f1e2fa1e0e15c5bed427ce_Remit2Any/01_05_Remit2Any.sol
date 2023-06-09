// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Remit2Any {
    using SafeERC20 for IERC20;

    // @dev TransferAssetEvent
    event TransferAssetEvent(address _from, address _to, uint256 _amount, address _asset, string _transactionId);

    mapping(string => bool) public txDone;

    // errors
    error ZeroAddress();
    error ZeroAmount();

    constructor() {}

    /// @dev Transfer asset from user
    /// @notice asset transfers from msg.sender to _to address
    /// @param _to Address to which tokens will be transferred
    /// @param _token Address of token
    /// @param _amount Amount of token
    /// @param _transactionId Id of transaction
    /// @return true if transfer successful
    function transferAsset(
        address _to,
        address _token,
        uint256 _amount,
        string memory _transactionId
    ) external returns (bool) {
        if (_to == address(0)) revert ZeroAddress();
        if (_amount == 0) revert ZeroAmount();

        // Perform ERC20 transfer
        IERC20(_token).safeTransferFrom(msg.sender, _to, _amount);

        txDone[_transactionId] = true;

        // emit event
        emit TransferAssetEvent(msg.sender, _to, _amount, _token, _transactionId);

        return true;
    }

    /// @notice Gets information about transfer using transactionId
    /// @param _transactionId Id of transaction
    /// @return _transaction Information about transfer
    function getTransaction(string memory _transactionId) external view returns (bool) {
        return txDone[_transactionId];
    }

    /// @notice Gets users token balance
    /// @param _owner Address of user
    /// @param _token Address of token
    /// @return Amount of tokens
    function balanceOf(address _owner, address _token) external view returns (uint256) {
        return IERC20(_token).balanceOf(_owner);
    }
}