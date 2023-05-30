// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

contract Sender {
    struct Recipient {
        address payable recipient;
        uint amount;
    }

    // Event emitted on successful transfer to a recipient
    event Sent(address recipient, uint amount);

    // Function to send ETH to multiple recipients with a fixed amount
    function sendWithFixedAmount(uint _amount, address payable[] calldata _to) external payable {
        require(_to.length > 0, "No recipients specified");
        require(msg.value == _amount * _to.length, "Insufficient funds");
        
        for (uint i = 0; i < _to.length; i++) {
            require(_to[i] != address(0), "Invalid recipient address");
            _to[i].transfer(_amount);
            emit Sent(_to[i], _amount);
        }
    }

    // Function to send ETH to multiple recipients with specific amounts
    function sendWithSpecificAmount(Recipient[] calldata _recipients) external payable {
        require(_recipients.length > 0, "No recipients specified");
        uint totalAmount;
        
        for (uint i = 0; i < _recipients.length; i++) {
            address payable recipient = _recipients[i].recipient;
            uint amount = _recipients[i].amount;
            require(recipient != address(0), "Invalid recipient address");
            require(amount > 0, "Invalid amount");
            
            totalAmount += amount;
            emit Sent(recipient, amount);
        }
        
        require(msg.value == totalAmount, "Insufficient funds");
        
        for (uint i = 0; i < _recipients.length; i++) {
            _recipients[i].recipient.transfer(_recipients[i].amount);
        }
    }
}