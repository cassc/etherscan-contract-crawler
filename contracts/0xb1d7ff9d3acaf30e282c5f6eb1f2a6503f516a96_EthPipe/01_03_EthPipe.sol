// SPDX-License-Identifier: MIT
pragma solidity ^0.7.2;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";

contract EthPipe {
    using SafeMath for uint;

    uint64 m_localMsgCounter;
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

    constructor(address relayerAddress)
    {
        m_relayerAddress = relayerAddress;
    }

    receive() external payable {
    }

    function processRemoteMessage(uint64 msgId, uint relayerFee, uint amount, address receiver)
        external
    {
        require(msg.sender == m_relayerAddress, "Invalid msg sender.");
        require(!m_processedRemoteMsgs[msgId], "Msg already processed.");
        m_processedRemoteMsgs[msgId] = true;

        (bool success, ) = payable(m_relayerAddress).call{value: relayerFee}("");
        require(success, "Transfer failed.");

        (success, ) = payable(receiver).call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function sendFunds(uint value, uint relayerFee, bytes memory receiverBeamPubkey)
        external
        payable
    {
        require(receiverBeamPubkey.length == 33, "unexpected size of the receiverBeamPubkey.");
        uint total = value + relayerFee;
        require(msg.value == total, "Invalid sent fund");

        emit NewLocalMessage(m_localMsgCounter++, value, relayerFee, receiverBeamPubkey);
    }  
}