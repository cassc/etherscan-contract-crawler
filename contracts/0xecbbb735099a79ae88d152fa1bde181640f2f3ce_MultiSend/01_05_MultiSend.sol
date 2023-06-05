// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./lib/openzeppelin-contracts/token/ERC20/ERC20.sol";

/// @notice `MultiSend` is a contract for sending ERC20 Tokens to multiple addresses.
contract MultiSend {

    event MultiERC20Transfer(
        address indexed _from,
        address _to,
        uint _amount,
        ERC20 _token
    );

    /// @notice Send ERC20 tokens to multiple contracts
    ///  using two arrays which includes the address and the amount.
    /// @param _token The token to send
    /// @param _addresses Array of addresses to send to
    /// @param _amounts Array of token amounts to send
    function multiERC20Transfer(
        address _token,
        address[] memory _addresses,
        uint[] memory _amounts
    ) public {
        require(_addresses.length == _amounts.length, "Input length mismatch");

        ERC20 token = ERC20(_token);
        uint totalAmount = 0;
        for (uint i = 0; i < _amounts.length; i++) {
            totalAmount += _amounts[i];
        }

        require(token.allowance(msg.sender, address(this)) >= totalAmount, "Insufficient allowance");
        require(token.balanceOf(msg.sender) >= totalAmount, "Insufficient balance");

        for (uint i = 0; i < _addresses.length; i++) {
            _safeERC20Transfer(token, _addresses[i], _amounts[i]);
            emit MultiERC20Transfer(
                msg.sender,
                _addresses[i],
                _amounts[i],
                token
            );
        }
    }

    /// @notice `_safeERC20Transfer` is used internally to
    ///  transfer a quantity of ERC20 tokens safely.
    function _safeERC20Transfer(ERC20 _token, address _to, uint _amount) internal {
        require(_token.balanceOf(msg.sender) >= _amount, "Insufficient balance");
        _token.transferFrom(msg.sender, _to, _amount);
    }

    /// @dev Default payable function to not allow sending to contract
    ///  Remember this does not necessarily prevent the contract
    ///  from accumulating funds.
    fallback() external payable {
        revert("Fallback method");
    }
    receive() external payable {
        revert("Sending ETH not allowed");
    }
}