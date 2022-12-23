// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IMultisender.sol";

contract Multisender is IMultisender {

    event EthSentEvent(address indexed _receiver, uint256 _amount);
    event TokenSentEvent(address indexed _token, address indexed _receiver, uint256 _amount);

    function transferEth(address[] calldata _receivers, uint256 _amount) payable external override {
        for (uint256 i = 0; i < _receivers.length; i++) {
            payable(_receivers[i]).transfer(_amount);
            emit EthSentEvent(_receivers[i], _amount);
        }
    }

    function transferEth(address[] calldata _receivers, uint256[] calldata _amounts) payable external override {
        for (uint256 i = 0; i < _receivers.length; i++) {
            payable(_receivers[i]).transfer(_amounts[i]);
            emit EthSentEvent(_receivers[i], _amounts[i]);
        }
    }

    function transferToken(IERC20 _token, address[] calldata _receivers, uint256 _amount) external override {
        for (uint256 i = 0; i < _receivers.length; i++) {
            _token.transferFrom(msg.sender, _receivers[i], _amount);
            emit TokenSentEvent(address(_token), _receivers[i], _amount);
        }
    }

    function transferToken(IERC20 _token, address[] calldata _receivers, uint256[] calldata _amounts) external override {
        for (uint256 i = 0; i < _receivers.length; i++) {
            _token.transferFrom(msg.sender, _receivers[i], _amounts[i]);
            emit TokenSentEvent(address(_token), _receivers[i], _amounts[i]);
        }
    }

}