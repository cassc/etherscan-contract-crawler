//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleVesting is Ownable {
    bytes32 public merkleRoot;
    mapping(address => bool) public claimAddresses;
    address public tokenAddress;
    uint256 public unlockTime = 0;

    event Claim(address indexed claimer, uint256 amount);
    event Vest(bytes32 indexed merkleProof);

    function setTokenAddress(address addressOfToken) external onlyOwner {
        require(tokenAddress == address(0), "Address already assigned");
        tokenAddress = addressOfToken;
    }

    function setUnlockTime(uint256 time) external onlyOwner {
        require(unlockTime == 0, "Unlock time already assigned");
        unlockTime = block.timestamp + time;
    }

    function vestTokens(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        emit Vest(merkleRoot);
    }

    function claimTokens(uint256 amount, bytes32[] calldata merkleProof)
        external
    {
        require(tokenAddress != address(0), "No token address provided");
        require(unlockTime != 0, "Unlock time not set");
        require(block.timestamp > unlockTime, "Vesting not unlocked yet");
        require(canClaimTokens(amount, merkleProof), "Vesting: cannot claim");

        claimAddresses[msg.sender] = true;
        IERC20(tokenAddress).transfer(msg.sender, amount);
        emit Claim(msg.sender, amount);
    }

    function canClaimTokens(uint256 amount, bytes32[] calldata merkleProof)
        public
        view
        returns (bool)
    {
        return
            claimAddresses[msg.sender] == false &&
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender, amount))
            );
    }
}