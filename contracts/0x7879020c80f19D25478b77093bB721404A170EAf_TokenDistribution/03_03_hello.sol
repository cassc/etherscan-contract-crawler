// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenDistribution is Ownable {
    

    receive() external payable {
    }

    function distributeTokens(address[] calldata recipients) public onlyOwner {
        require(
            recipients.length > 0,
            "At least one recipient must be provided"
        );

        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "Contract has no token balance");

        uint256 randomIndex = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.prevrandao))
        ) % recipients.length;
        address randomRecipient = recipients[randomIndex];

        (bool success, ) = randomRecipient.call{value: contractBalance}("");
        require(success, "Failed to transfer native tokens to random recipient");
    }

    function withdraw() public onlyOwner {
    uint256 contractBalance = address(this).balance;
    require(contractBalance > 0, "Contract balance is zero");
    
    (bool success, ) = payable(owner()).call{value: contractBalance}("");
    require(success, "Failed to transfer native tokens to owner");
}

}