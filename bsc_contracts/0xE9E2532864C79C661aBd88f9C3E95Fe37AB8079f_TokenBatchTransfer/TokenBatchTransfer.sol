/**
 *Submitted for verification at BscScan.com on 2023-02-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract TokenBatchTransfer {
    address[] public recipients;
    uint256 public totalAmount;
    address public owner;

    constructor(address[] memory _recipients, address _owner) {
        require(_recipients.length > 0, "Recipient list is empty");
        require(_owner != address(0), "Invalid owner address");
        
        recipients = _recipients;
        owner = _owner;
    }

    function transferTokens(address token, uint256 amount) public {
        IERC20 tokenContract = IERC20(token);
        require(tokenContract.balanceOf(address(this)) >= amount, "Insufficient balance");
        require(tokenContract.approve(msg.sender, amount), "Approval failed");

        uint256 remainingAmount = amount;
        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 transferAmount = getRandomAmount(i, remainingAmount);
            remainingAmount -= transferAmount;

            tokenContract.transfer(recipients[i], transferAmount);
        }
    }

    function getRandomAmount(uint256 index, uint256 remainingAmount) private view returns (uint256) {
        uint256 maxAmount = remainingAmount / (recipients.length - index);
        return (uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, index))) % (maxAmount + 1));
    }

    function withdrawToken(address token) public {
        require(msg.sender == owner, "Only the contract owner can call this function");

        IERC20 tokenContract = IERC20(token);
        uint256 balance = tokenContract.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");

        tokenContract.transfer(owner, balance);
    }

    function withdrawBNB() public {
        require(msg.sender == owner, "Only the contract owner can call this function");

        uint256 balance = address(this).balance;
        require(balance > 0, "No BNB to withdraw");

        payable(owner).transfer(balance);
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    receive() external payable {}

}