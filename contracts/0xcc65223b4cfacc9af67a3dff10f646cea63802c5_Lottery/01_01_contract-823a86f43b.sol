// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract Lottery {
    address payable public owner;
    address payable[] public players;
    uint256 public ticketPrice = 0.05 ether;
    bool public isActive = false;

    mapping(address => uint256) public balanceOf;

    constructor() {
        owner = payable(msg.sender);
    }

    function toggleActive() public {
        require(msg.sender == owner, "Only the owner can toggle the lottery");
        isActive = !isActive;
    }

    function enter() public payable {
        require(isActive == true, "Lottery is not active");
        require(msg.value == ticketPrice, "Must send exactly 0.05 Ether");
        require(balanceOf[msg.sender] == 0, "Cant enter more than once");

        balanceOf[msg.sender] += msg.value;
        players.push(payable(msg.sender));
    }

    function endLottery() public {
        require(msg.sender == owner, "Only the owner can end the lottery");
        require(players.length > 4, "Not enough players joined");

        uint256 ownerPool = address(this).balance / 4;
        uint256 winningPool = address(this).balance - ownerPool;

        // Transfer 25% to the owner
        (bool success, ) = owner.call{value: ownerPool}("");
        require(success, "Failed to transfer Ether");

        // Select winners and distribute remaining 75%
        for (uint i = 0; i < players.length / 5; i++) {
            uint256 index = (uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) + i) % players.length;
            (success, ) = players[index].call{value: winningPool / (players.length / 5)}("");
            require(success, "Failed to transfer Ether");
        }

        // Reset
        delete players;
    }
}