// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import './interfaces/IMerkleDistributor.sol';

contract MerkleDistributor is IMerkleDistributor {
    address public immutable override token;
    bytes32 public immutable override merkleRoot;
    address public returnAddress;
    uint256 public immutable claimableUntil;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address token_, address returnAddress_, bytes32 merkleRoot_, uint256 claimableUntil_) {
        token = token_;
        merkleRoot = merkleRoot_;
        returnAddress = returnAddress_;
        claimableUntil = claimableUntil_;
    }

    modifier onlyOwner() {
        require(msg.sender == address(returnAddress), 'onlyOwner: only owner can call this function');
        _;
    }

    function setReturnAddress(address _returnAddress) external onlyOwner {
        returnAddress = _returnAddress;
    }

    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external override {
        require(!isClaimed(index), 'MerkleDistributor: Drop already claimed.');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(IERC20(token).transfer(account, amount), 'MerkleDistributor: Transfer failed.');

        emit Claimed(index, account, amount);
    }

    function getUnclaimedFunds() public {
        require(block.timestamp > claimableUntil);
        IERC20(token).transfer(returnAddress, IERC20(token).balanceOf(address(this)));
    }
}