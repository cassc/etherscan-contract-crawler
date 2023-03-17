// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/governance/utils/IVotes.sol";

contract Airdrop is Ownable {
    using SafeERC20 for IERC20;

    event Claimed(uint256 index, address account, uint256 amount);
    event RemainingWithdrawed(address account, uint256 amount);

    address public immutable token;
    bytes32 public immutable root;
    uint256 public immutable start;
    uint256 public immutable end;

    // bitmap of claimed by claim ID.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(
        address owner,
        address _token,
        bytes32 _root,
        uint256 _start,
        uint256 _end
    ) {
        require(_token != address(0), "Invalid token");
        require(_start > block.timestamp, "Must start later than now");
        require(_end > _start, "Invalid end time");
        token = _token;
        root = _root;
        start = _start;
        end = _end;

        transferOwnership(owner);
    }

    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata proof
    ) external {
        require(block.timestamp >= start, "Airdrop not started yet.");
        require(block.timestamp <= end, "Airdrop ended.");
        require(!isClaimed(index), "already claimed.");

        // Verify the merkle proof.
        bytes32 leaf = keccak256(abi.encodePacked(index, account, amount));
        require(
            MerkleProof.verifyCalldata(proof, root, leaf),
            "Invalid proof."
        );

        // Mark it claimed
        _setClaimed(index);

        // use SafeERC20 transfer funds to send the token.
        IERC20(token).safeTransfer(account, amount);
        emit Claimed(index, account, amount);
    }

    function sweepAfterEnded(address recipient) external onlyOwner {
        require(block.timestamp > end, "Airdrop not ended yet");
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(recipient, balance);
        emit RemainingWithdrawed(recipient, balance);
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
        claimedBitMap[claimedWordIndex] =
            claimedBitMap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function recoverOtherERC20(
        address tokenAddress, uint256 tokenAmount) public onlyOwner {
        require(tokenAddress != address(token), "only other token can be recovered");
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }

    // Not necessary, unless someone force ether to this contract in strange ways, e.g. selfdestruct.
    // function recoverNativeToken() public onlyOwner {
    //      (bool sent, ) = this.owner().call{value: address(this).balance}("");
    //     require(sent, "Failed to send Ether");
    // }
}