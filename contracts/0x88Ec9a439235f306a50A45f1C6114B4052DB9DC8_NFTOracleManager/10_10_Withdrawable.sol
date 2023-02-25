//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Withdrawable is Ownable {
    using SafeERC20 for IERC20;
    address constant ETHER = address(0);

    event LogWithdraw(address indexed from, address indexed asset, uint amount);

    function withdraw(address asset, address receiver) public onlyOwner {
        uint assetBalance;
        if (asset == ETHER) {
            address self = address(this); // workaround for a possible solidity bug
            assetBalance = self.balance;
            payable(receiver).transfer(assetBalance);
        } else {
            assetBalance = IERC20(asset).balanceOf(address(this));
            IERC20(asset).safeTransfer(receiver, assetBalance);
        }
        emit LogWithdraw(receiver, asset, assetBalance);
    }
}