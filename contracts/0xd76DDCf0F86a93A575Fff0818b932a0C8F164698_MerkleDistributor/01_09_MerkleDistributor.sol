// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../access/Adminable.sol";

/**
 * @title MerkleDistributor
 */
contract MerkleDistributor is Adminable, Pausable {
    using SafeERC20 for IERC20;

    address public token;

    uint256 public merkleIndex;
    bytes32 public merkleRoot;

    // This is a packed array of booleans.
    mapping(uint256 => mapping(uint256 => uint256)) private claimedBitMap;

    // This event is triggered whenever a call to claim succeeds.
    event Claimed(uint256 merkleIndex, uint256 index, address account, uint256 amount);
    // This event is triggered whenever the merkle root gets updated.
    event MerkleRootUpdated(uint256 merkleIndex, bytes32 merkleRoot);
    // This event is triggered whenever a call to withdraw by owner.
    event TokensWithdrawn(address token, uint256 amount);

    constructor (address _token, bytes32 _merkleRoot) {
        token = _token;
        merkleRoot = _merkleRoot;
        merkleIndex = 0;
    }


    // ** PUBLIC VIEW functions **

    function isClaimed(uint256 _index) public view returns (bool) {
        return isClaimed(merkleIndex, _index);
    }

    function isClaimed(uint256 _merkleIndex, uint256 _index) public view returns (bool) {
        uint256 claimedWordIndex = _index / 256;
        uint256 claimedBitIndex = _index % 256;
        uint256 claimedWord = claimedBitMap[_merkleIndex][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }


    // ** EXTERNAL functions **

    function claim(uint256 _index, address _account, uint256 _amount, bytes32[] calldata _merkleProof) external whenNotPaused {
        require(!isClaimed(_index), "MerkleDistributor: Drop already claimed.");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(_index, _account, _amount));
        require(MerkleProof.verify(_merkleProof, merkleRoot, node), "MerkleDistributor: Invalid proof.");

        // Mark it claimed and send the token.
        _setClaimed(_index);
        IERC20(token).safeTransfer(_account, _amount);

        emit Claimed(merkleIndex, _index, _account, _amount);
    }


    // ** ONLY OWNER OR ADMIN functions **

    function updateRoot(bytes32 _merkleRoot) external onlyOwnerOrAdmin {
        _updateMerkleRoot(_merkleRoot);
    }

    function updateRootAndUnpause(bytes32 _merkleRoot) external onlyOwnerOrAdmin {
        _updateMerkleRoot(_merkleRoot);
        if (paused()) {
            _unpause();
        }
    }

    function pause() external onlyOwnerOrAdmin {
        _pause();
    }

    function unpause() external onlyOwnerOrAdmin {
        _unpause();
    }


    // ** ONLY OWNER functions **

    function withdrawTokens(IERC20 _token, uint256 _amount) external onlyOwner {
        uint256 tokenBalance = _token.balanceOf(address(this));
        uint256 withdrawalAmount = (_amount > tokenBalance) ? tokenBalance : _amount;

        _token.safeTransfer(msg.sender, withdrawalAmount);
        emit TokensWithdrawn(address(_token), withdrawalAmount);
    }


    // ** PRIVATE functions **

    function _updateMerkleRoot(bytes32 _merkleRoot) private {
        merkleRoot = _merkleRoot;
        merkleIndex += 1;
        emit MerkleRootUpdated(merkleIndex, merkleRoot);
    }

    function _setClaimed(uint256 _index) private {
        uint256 claimedWordIndex = _index / 256;
        uint256 claimedBitIndex = _index % 256;
        claimedBitMap[merkleIndex][claimedWordIndex] = claimedBitMap[merkleIndex][claimedWordIndex] | (1 << claimedBitIndex);
    }
}