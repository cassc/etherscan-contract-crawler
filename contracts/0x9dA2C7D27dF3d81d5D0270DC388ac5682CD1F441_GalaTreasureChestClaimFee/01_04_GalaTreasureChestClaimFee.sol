// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import './MessageValidator.sol';

contract GalaTreasureChestClaimFee is MessageValidator {
    event PaymentExecuted(string refId, uint256 amount, uint256 blockSigned);

    constructor(address _signer) {
        setSignerAddress(_signer);
    }

    function pay(
        string memory refId,
        uint256 amount,
        uint256 blockSigned,
        bytes memory sig
    )
        public
        payable
        isValidMessage(refId, amount, blockSigned, sig, msg.value)
    {
        payable(address(signerAddress)).transfer(msg.value);
        emit PaymentExecuted(refId, msg.value, blockSigned);
    }
}