// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "lib/solmate/src/auth/Owned.sol";
import "lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";


abstract contract Receivable is Owned {

    receive() external payable {}

    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawERC20(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

}