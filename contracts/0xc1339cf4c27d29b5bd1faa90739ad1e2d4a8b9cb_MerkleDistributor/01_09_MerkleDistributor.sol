// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.6.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IMerkleDistributor.sol";
import "./BalanceController.sol";

contract MerkleDistributor is IMerkleDistributor, BalanceController {
    address public immutable override token;
    bytes32 public immutable override merkleRoot;
    uint256 public override gasRebate;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address token_, bytes32 merkleRoot_, uint256 gasRebate_) public {
        token = token_;
        merkleRoot = merkleRoot_;
        gasRebate = gasRebate_;
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

    function claim(uint256 index, address payable account, uint256 ethAmount, uint256 tokenAmount, bytes32[] calldata merkleProof) external override {
        require(!isClaimed(index), 'MerkleDistributor: Drop already claimed.');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, ethAmount, tokenAmount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed
        _setClaimed(index);

        // Send the token
        if (tokenAmount > 0){
            require(IERC20(token).transfer(account, tokenAmount), 'MerkleDistributor: Token transfer failed.');
        }

        // Send any eth, including the gasRebate
        uint256 ethTotal = SafeMath.add(ethAmount, gasRebate);
        if (ethTotal > 0) {
            (bool sent, ) = account.call{value: ethTotal}('');
            require(sent, 'MerkleDistributor: Eth transfer failed.');
        }

        emit Claimed(index, account, ethAmount, tokenAmount);
    }

    function setGasRebate(uint256 _gasRebate) external override onlyOwner {
        gasRebate = _gasRebate;
    }
}