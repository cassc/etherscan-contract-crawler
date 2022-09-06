//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IWithdrawable.sol";

abstract contract Withdrawable is IWithdrawable, Ownable {
    event Withdraw(uint amount);
    event WithdrawAll();

    function pendingWithdrawal() external view override returns (uint) {
        return address(this).balance;
    }

    function withdraw(uint _amount) external override onlyOwner {
        _withdraw(_amount);

        emit Withdraw(_amount);
    }

    function withdrawAll() external override onlyOwner {
        _withdraw(address(this).balance);

        emit WithdrawAll();
    }

    function _withdraw(uint _amount) internal {
        require(_amount > 0, "Withdrawable: Amount has to be greater than 0");
        require(
            _amount <= address(this).balance,
            "Withdrawable: Not enough funds"
        );
        payable(msg.sender).transfer(_amount);
    }
}