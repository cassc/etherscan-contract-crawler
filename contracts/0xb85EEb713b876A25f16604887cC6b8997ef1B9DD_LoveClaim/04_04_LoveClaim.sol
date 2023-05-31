// SPDX-License-Identitfier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    function mint(address receiver, uint amount) external;
}

error AlreadyClaimed();
error InvalidProof();

contract LoveClaim is Ownable {

    bool public claimActivated;

    address public immutable loveToken;
    bytes32 public immutable merkleRoot;

    uint256 public claimStart;
    uint256 public claimEnd;

    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address _loveToken, bytes32 _merkleRoot) Ownable() {
        loveToken = _loveToken;
        merkleRoot = _merkleRoot;
    }

    function isClaimed(uint256 index) public view returns (bool) {
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

    function claim(uint256 index, uint256 amount, bytes32[] calldata merkleProof) external {
        require(block.timestamp <= claimEnd, "Claim period has ended.");
        if (isClaimed(index)) revert AlreadyClaimed();
        bytes32 node = keccak256(abi.encodePacked(index, msg.sender, amount));
        if (!MerkleProof.verify(merkleProof, merkleRoot, node)) revert InvalidProof();
        _setClaimed(index);
        IERC20(loveToken).mint(msg.sender, amount);
    }

    function activateClaim() external onlyOwner{
        require(!claimActivated, "Claim has already been activated.");
        claimStart = block.timestamp;
        claimEnd = block.timestamp + 7 days;
        claimActivated = true;
    }

}