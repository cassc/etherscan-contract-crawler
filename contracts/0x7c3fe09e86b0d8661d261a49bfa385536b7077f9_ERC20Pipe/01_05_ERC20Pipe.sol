// SPDX-License-Identifier: MIT
pragma solidity ^0.7.2;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

contract ERC20Pipe {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    uint64 m_localMsgCounter;
    address m_tokenAddress;
    address m_relayerAddress;

    mapping (uint64 => bool) m_processedRemoteMsgs;

    // LocalMessage {
    //     // header:
    //     uint64 msgId;
    //     uint relayerFee;

    //     // msg body
    //     uint amount;
    //     bytes receiver; // beam pubKey - 33 bytes
    // }
    event NewLocalMessage(uint64 msgId, uint amount, uint relayerFee, bytes receiver);

    constructor(address tokenAddress, address relayerAddress)
    {
        m_tokenAddress = tokenAddress;
        m_relayerAddress = relayerAddress;
    }

    function processRemoteMessage(uint64 msgId, uint relayerFee, uint amount, address receiver)
        external
    {
        require(msg.sender == m_relayerAddress, "Invalid msg sender.");
        require(!m_processedRemoteMsgs[msgId], "Msg already processed.");
        m_processedRemoteMsgs[msgId] = true;

        IERC20(m_tokenAddress).safeTransfer(m_relayerAddress, relayerFee);
        IERC20(m_tokenAddress).safeTransfer(receiver, amount);
    }

    function sendFunds(uint value, uint relayerFee, bytes memory receiverBeamPubkey)
        external
    {
        require(receiverBeamPubkey.length == 33, "unexpected size of the receiverBeamPubkey.");

        uint total = value + relayerFee;
        IERC20(m_tokenAddress).safeTransferFrom(msg.sender, address(this), total);

        emit NewLocalMessage(m_localMsgCounter++, value, relayerFee, receiverBeamPubkey);
    }  
}