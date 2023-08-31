/**
 *Submitted for verification at Etherscan.io on 2023-07-22
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

contract MonetaryPolicy {
    address public owner;
    address public tokenAddress;
    uint256 public lastRebaseTimestamp;
    uint256 public epochNumber;
    int256 public supplyDelta; //can be removed to save GAS

    event ExecuteRebase(uint256 epochNumber, uint256 newTotalSupply);

    // can be removed - from here
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }
    
    // Function to change the token address
    function changeTokenAddress(address _tokenAddress) external onlyOwner {
        tokenAddress = _tokenAddress;
    }
    // can be removed - till here

    constructor(address _tokenAddress) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
        lastRebaseTimestamp = block.timestamp;
        epochNumber = 1;
    }

    // Function to execute the rebase
    function executeRebase() external returns (uint256, uint256) {
        require(block.timestamp >= lastRebaseTimestamp + 1 days, "Not enough time has passed since the last rebase");

        // create random Number between 1 and 100 for supplyDelta magnitude
        uint256 randomNumberMagnitude = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % 100 + 1;

        // create random Number between 1 and 100 for supplyDelta sign
        uint256 randomNumberSign = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, randomNumberMagnitude))) % 100 + 1;
        
        // Call totalSupply from tokenAddress
        (bool success1, bytes memory result) = address(tokenAddress).call(abi.encodeWithSignature("totalSupply()"));
        require(success1, "Failed to call totalSupply function");
        uint256 totalSupply = abi.decode(result, (uint256));

        // calculate new supplyDelta
        int256 sign = randomNumberSign > 45 ? int256(-1) : int256(1); // 55% chance of becoming negative
        supplyDelta = sign * int256(randomNumberMagnitude) * int256(totalSupply) / 100;

        // Call the rebase function of the token contract with the current epochNumber and supplyDelta
        (bool success2, ) = tokenAddress.call(abi.encodeWithSignature("rebase(uint256,int256)", epochNumber, supplyDelta));
        require(success2, "Failed to call the rebase function");

        lastRebaseTimestamp = block.timestamp;
        epochNumber++;

        uint256 newTotalSupply;
        if (supplyDelta >= 0) {
            newTotalSupply = totalSupply + uint256(supplyDelta);
        } else {
            newTotalSupply = totalSupply - uint256(-supplyDelta);
        }

        // Emit the event
        emit ExecuteRebase(epochNumber, newTotalSupply);

        return (epochNumber, newTotalSupply);
    }
}