//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract WithdrawExtension is Ownable {
    
    function pendingWithdrawal() external view returns (uint256) {
        return address(this).balance;
    }

    function withdraw(uint256 _amount) external onlyOwner {
        _withdraw(_amount);
    }

    function withdrawAll() external onlyOwner {
        _withdraw(address(this).balance);
    }

    function _withdraw(uint256 _amount) internal {
        require(_amount > 0, "WithdrawExtension: amount < 0");
        require(
            _amount <= address(this).balance,
            "WithdrawExtension: not enough funds"
        );
        payable(msg.sender).transfer(_amount);
    }
}