// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

import { IERC20  } from "IERC20.sol";
import { MerkleProof  } from "MerkleProof.sol";
import { Ownable  } from "Ownable.sol";

contract EthLock is Ownable {

    uint256 private constant DEPOSIT_AMOUNT = 0.25 ether;
    // Date and time (GMT): Monday, 15 May 2023 00:00:00
    uint256 private constant BLOCK_END = 1684108800;

    bytes32 public merkleRoot;
    mapping(address => bool) public deposited;
    mapping(address => bool) public claimed;

    error InvalidMerkleProof();
    error InvalidDepositAmount();
    error AlreadyDeposited();
    error AlreadyClaimed();
    error BlockNotEnded();
    error FailedTransfer();

    event LogClaim(address indexed user, uint256 amount);
    event LogDeposit(address indexed user, uint256 amount);
    event LogNewRoot(bytes32 merkleRoot);

    function setRoot(
        bytes32 _merkleRoot
    ) external onlyOwner {
        merkleRoot = _merkleRoot;
        emit LogNewRoot(_merkleRoot);
    }

    function canClaim(bytes32[] memory _proof, uint128 _amount) public view returns (bool) {
        if (claimed[msg.sender]) {
            revert AlreadyClaimed();
        }
        if (block.timestamp < BLOCK_END) {
            revert BlockNotEnded();
        }
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));
        return MerkleProof.verify(_proof, merkleRoot, leaf);
    }

    function claim(bytes32[] memory _proof, uint128 _amount) external payable {
            if (!canClaim(_proof, _amount)) {
                revert InvalidMerkleProof();
            }
            claimed[msg.sender] = true;
            (bool sent, ) = msg.sender.call{value: _amount}("");
            if (!sent) revert FailedTransfer();

            emit LogClaim(msg.sender, _amount);
        }


    function deposit() external payable {
        if (msg.value != DEPOSIT_AMOUNT) revert InvalidDepositAmount();
        if (deposited[msg.sender]) revert AlreadyDeposited();
        deposited[msg.sender] = true;
        emit LogDeposit(msg.sender, msg.value);
    }
}