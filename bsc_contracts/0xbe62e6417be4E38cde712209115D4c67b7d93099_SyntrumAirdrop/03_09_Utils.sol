// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
import './TransferHelper.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract Utils is ReentrancyGuard {
    function _takeAsset (
        address tokenAddress, address fromAddress, uint256 amount
    ) internal returns (bool) {
        require(tokenAddress != address(0), 'Token address should not be zero');
        TransferHelper.safeTransferFrom(
            tokenAddress, fromAddress, address(this), amount
        );
        return true;
    }

    function _sendAsset (
        address tokenAddress, address toAddress, uint256 amount
    ) internal nonReentrant returns (bool) {
        if (tokenAddress == address(0)) {
            require(address(this).balance >= amount,
                'Not enough contract balance');
            payable(toAddress).transfer(amount);
        } else {
            TransferHelper.safeTransfer(
                tokenAddress, toAddress, amount
            );
        }
        return true;
    }
}