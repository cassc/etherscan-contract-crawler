// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../interfaces/IRangoMessageReceiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


/// @title Sample dApp contract
/// @author George
/// @notice This sample contract just receives tokens and transfers it to user.
contract SampleDApp is IRangoMessageReceiver {
    struct SimpleTokenMessage {
        address token;
        address receiver;
    }

    function handleRangoMessage(
        address token,
        uint amount,
        ProcessStatus status,
        bytes memory message
    ) external {
        SimpleTokenMessage memory m = abi.decode((message), (SimpleTokenMessage));
        require(token == m.token, "Not the same token");
        if (token == address(0)) {
            (bool sent,) = m.receiver.call{value : amount}("");
            require(sent, "failed to send native");
        } else {
            SafeERC20.safeTransfer(IERC20(token), m.receiver, amount);
        }
    }
}