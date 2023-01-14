// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract PeaceClaim is Ownable {
    address public signer;
    IERC20 public peace;
    mapping(address => uint256) public lastClaimed;
    mapping(address => uint256) public blockClaimed;
    mapping(bytes32 => bool) public processed;

    using ECDSA for bytes32;

    event Claim(address indexed recipient, uint256 amount);

    constructor(address initialSigner, address peaceAddress) {
        signer = initialSigner;
        peace = IERC20(peaceAddress);
    }

    function claimPeace(
        address recipient,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(block.timestamp < deadline, "Signature expired");
        require(
            isValidSignature(recipient, amount, deadline, v, r, s),
            "Invalid signature"
        );
        require(
            lastClaimed[recipient] < deadline - 12 hours,
            "Not enough time between claims"
        );
        require(processed[keccak256(abi.encode(v,r,s))] == false, "Signature already processed");

        lastClaimed[recipient] = block.timestamp;
        blockClaimed[recipient] = block.number;

        processed[keccak256(abi.encode(v,r,s))] = true;
        bool result = peace.transfer(recipient, amount * 10 ** 18);
        require(result, "Transfer failed");

        emit Claim(recipient, amount);
    }

    function isValidSignature(
        address recipient,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private view returns (bool) {
        bytes32 message = keccak256(abi.encode(recipient, amount, deadline));
        return message.recover(v, r, s) == signer;
    }

    function withdrawPeace(uint256 amount) external onlyOwner {
        bool result = peace.transfer(msg.sender, amount);
        require(result, "Transfer failed");
    }

    function updateSigner(address newSigner) external onlyOwner {
        require(newSigner != address(0), "no address zero");
        signer = newSigner;
    }

    function updateToken(address newToken) external onlyOwner {
        require(newToken != address(0), "no address zero");
        peace = IERC20(newToken);
    }
}