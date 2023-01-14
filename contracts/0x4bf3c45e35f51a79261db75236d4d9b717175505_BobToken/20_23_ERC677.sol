// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

import "../interfaces/IERC677.sol";
import "../interfaces/IERC677Receiver.sol";
import "./BaseERC20.sol";

/**
 * @title ERC677
 */
abstract contract ERC677 is IERC677, BaseERC20 {
    /**
     * @dev ERC677 extension to ERC20 transfer. Will notify receiver after transfer completion.
     * @param _to address of the tokens receiver.
     * @param _amount amount of tokens to mint.
     * @param _data extra data to pass in the notification callback.
     */
    function transferAndCall(address _to, uint256 _amount, bytes calldata _data) external override {
        _transfer(msg.sender, _to, _amount);
        require(IERC677Receiver(_to).onTokenTransfer(msg.sender, _amount, _data), "ERC677: callback failed");
    }
}