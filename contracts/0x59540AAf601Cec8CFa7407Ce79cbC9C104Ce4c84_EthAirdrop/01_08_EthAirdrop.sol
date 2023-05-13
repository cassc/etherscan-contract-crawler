//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract EthAirdrop is Ownable, Pausable, ReentrancyGuard {
    using BitMaps for BitMaps.BitMap;

    bytes32 public root;
    BitMaps.BitMap internal _claimed;

    event Claimed(address indexed claimer, uint256 amount);

    constructor(bytes32 _root) {
        root = _root;
    }

    receive() external payable {}

    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function withdrawToken(IERC20 _token) external onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        _token.transfer(msg.sender, balance);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "transfer failed");
    }

    function claimed(uint256 index) external view returns (bool) {
        return _claimed.get(index);
    }

    function claim(
        uint256 amount,
        uint256 index,
        bytes32[] memory proof
    ) external whenNotPaused nonReentrant {
        require(!_claimed.get(index), "claimed");
        _claimed.set(index);
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, index, amount));
        require(MerkleProof.verify(proof, root, leaf), "invalid proof");
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "transfer failed");
        emit Claimed(msg.sender, amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}