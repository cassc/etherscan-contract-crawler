// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../token/ERC20/IERC20.sol";
import "../../utils/Context.sol";

contract TokenRecipient is Context {
    event ReceivedEther(address indexed sender, uint256 amount);
    event ReceivedTokens(
        address indexed from,
        uint256 value,
        address indexed token,
        bytes extraData
    );

    /**
     * @dev Receive tokens and generate a log event
     * @param from Address from which to transfer tokens
     * @param value Amount of tokens to transfer
     * @param token Address of token
     * @param extraData Additional data to log
     */
    function receiveApproval(
        address from,
        uint256 value,
        address token,
        bytes memory extraData
    ) public {
        IERC20 t = IERC20(token);
        require(t.transferFrom(from, address(this), value));
        emit ReceivedTokens(from, value, token, extraData);
    }

    /**
     * @dev Receive Ether and generate a log event
     */
    receive() external payable {
        emit ReceivedEther(_msgSender(), msg.value);
    }

    /**
     * @dev Receive Ether and generate a log event
     */
    fallback() external payable {
        emit ReceivedEther(_msgSender(), msg.value);
    }
}