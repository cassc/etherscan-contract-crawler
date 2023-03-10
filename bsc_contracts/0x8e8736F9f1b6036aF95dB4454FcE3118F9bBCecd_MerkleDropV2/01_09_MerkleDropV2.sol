// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MerkleDropV2 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bytes32 public root;
    address immutable public token;
    mapping(address => uint256) public claimed;

    event FeesClaimed(address account, uint amount);

    constructor(bytes32 _merkleroot, address _token) {
        root = _merkleroot;
        token = _token;
    }

    function withdrawFees(address _account, uint256 _amount) external onlyOwner {
        IERC20(token).safeTransfer(_account, _amount);
    }

    function updateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        root = _merkleRoot;
    }

    function redeemFees(address _account, uint256 _amount, bytes32[] calldata _proof) external nonReentrant {
        bytes32 leaf = _leafEncode(_account, _amount);
        require(_verify(leaf, _proof), "MerkleDrop: Invalid merkle proof");

        uint256 amountToClaim = _amount.sub(claimed[_account]);
        require(amountToClaim > 0, "MerkleDrop: No fees to claim");

        claimed[_account] = _amount;

        IERC20(token).safeTransfer(_account, amountToClaim);

        emit FeesClaimed(_account, amountToClaim);
    }

    function _leafEncode(address _account, uint256 _amount) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _amount));
    }

    function _verify(bytes32 _leaf, bytes32[] memory _proof) internal view returns (bool) {
        return MerkleProof.verify(_proof, root, _leaf);
    }
}