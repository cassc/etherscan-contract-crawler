// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '../interfaces/IMerkleDistributor.sol';

contract MerkleClaimer is Ownable, IMerkleDistributor {
    address public immutable override token;
    bytes32 public immutable override merkleRoot;
    string public id;
    bool public isPaused;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(
        string memory _id,
        address token_,
        bytes32 merkleRoot_
    ) {
        id = _id;
        token = token_;
        merkleRoot = merkleRoot_;
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

    function claim(
        uint256 index,
        address account,
        uint256 amount,
        uint256 time,
        bytes32[] calldata merkleProof
    ) external override {
        require(!isPaused, 'MerkleDistributor: Distribution paused');
        require(!isClaimed(index), 'MerkleDistributor: Claim already claimed');
        require(block.timestamp >= time, 'MerkleDistributor: Claim is not available yet');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount, time));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof');

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(IERC20(token).transfer(account, amount), 'MerkleDistributor: Transfer failed');

        emit Claimed(index, account, amount, time);
    }

    function claimAll(
        uint256[] calldata indexes,
        address account,
        uint256[] calldata amounts,
        uint256[] calldata times,
        bytes32[][] calldata merkleProofs
    ) external override {
        require(!isPaused, 'MerkleDistributor: Distribution paused');

        uint256 toSend;
        for (uint256 i = 0; i < indexes.length; i++) {
            uint256 index = indexes[i];
            uint256 amount = amounts[i];
            uint256 time = times[i];
            bytes32[] memory merkleProof = merkleProofs[i];

            require(!isClaimed(index), 'MerkleDistributor: Claim already claimed');
            require(block.timestamp >= time, 'MerkleDistributor: Claim is not available yet');

            // Verify the merkle proof.
            bytes32 node = keccak256(abi.encodePacked(index, account, amount, time));
            require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof');

            // Mark it claimed and send the token.
            _setClaimed(index);
            toSend += amount;
            emit Claimed(index, account, amount, time);
        }

        require(IERC20(token).transfer(account, toSend), 'MerkleDistributor: Transfer failed');
    }

    function setPaused(bool status) external onlyOwner {
        isPaused = status;
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(owner()).transfer(balance);
        }

        IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
    }

    function withdrawToken(address _token, uint256 amount) external onlyOwner {
        IERC20(_token).transfer(owner(), amount);
    }
}