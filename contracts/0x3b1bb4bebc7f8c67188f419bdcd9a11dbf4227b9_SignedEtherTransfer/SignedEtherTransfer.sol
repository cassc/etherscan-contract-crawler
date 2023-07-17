/**
 *Submitted for verification at Etherscan.io on 2023-06-25
*/

pragma solidity ^0.8.0;

contract SignedEtherTransfer {
    address private owner;
    mapping(address => uint256) public balances;

    constructor() {
        owner = msg.sender;
    }

    function transferEther() external payable {
        require(msg.value > 0, "Invalid transfer amount");

        // Update the sender's balance
        balances[msg.sender] += msg.value;
    }

    function withdrawTo(address payable _withdrawalWallet, uint256 _amount) external {
        require(msg.sender == owner, "Only the owner can withdraw");
        require(_amount > 0, "Invalid withdrawal amount");
        require(address(this).balance >= _amount, "Insufficient balance");

        // Transfer funds to the specified withdrawal wallet
        (bool success, ) = _withdrawalWallet.call{value: _amount}("");
        require(success, "Failed to transfer funds");
    }
}