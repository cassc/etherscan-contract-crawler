// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

library Sender {
    event SentMoney(address target, uint256 amount);
    event TransferFailed(address target, uint256 amount);

    function sendBalancePercentage(
        address targetAddress,
        uint16 basisPoint,
        uint256 amount
    ) internal returns (bool){
        uint256 amountToTransfer = (amount * basisPoint) / 10000;
        (bool success,) = payable(targetAddress).call{value: amountToTransfer}("");
        if(!success){
            emit TransferFailed(targetAddress, amountToTransfer);
        } else {
            emit SentMoney(targetAddress, amountToTransfer);
        }
        return success;
    }
}