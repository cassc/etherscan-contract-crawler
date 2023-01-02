//https://etherscan.io/address/0xcfd14c4f5a67da95fb9509124449842be482f707#code
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// import "./IFeeReceiver.sol";

// abstract contract FeeProcessor {
//     constructor(address payable receiver, bytes32 serviceId) payable {
//         IFeeReceiver(receiver).processFee{value: msg.value}(serviceId);
//     }
// }

abstract contract FeeProcessor {
    constructor(address payable receiver) payable {
        // IFeeReceiver(receiver).processFee{value: msg.value}(serviceId);
        require(msg.value >= 0* 10**18, 'Need 0 for fee');
        receiver.transfer(0* 10**18);
    }
}