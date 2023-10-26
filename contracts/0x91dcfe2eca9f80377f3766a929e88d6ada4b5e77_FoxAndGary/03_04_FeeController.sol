// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract FeeController {

    address[4] public feeRecipients;
    mapping(address => uint256) public feePools;
    
    constructor(address[4] memory feeRecipients_){
        feeRecipients = feeRecipients_;
    }

    function claimFees() public {
        uint amount = feePools[msg.sender];
        feePools[msg.sender] = 0;
        (bool sent,) = (msg.sender).call{value: amount}("");
        require(sent);
    }

    function transferFeeRecipient(uint256 index, address newRecipient) public {
        address recipient = feeRecipients[index];
        require(msg.sender == recipient, "unauthorized");
        feePools[newRecipient] = feePools[recipient];
        feePools[recipient] = 0;
        feeRecipients[index] = newRecipient;
    }

    function _distributeFees(uint256 amount) internal {
        uint256 amountPerRecipient = 100 * amount / 400;
        for (uint256 i = 0; i < 4; i++) {
            feePools[feeRecipients[i]] += amountPerRecipient;
        }
    }
}