// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./interfaces/IERC20.sol";
import "./libraries/SafeERC20.sol";
import "./libraries/MerkleProof.sol";

contract Airdrop {
    using SafeERC20 for IERC20;

    bool private entered;
    address public owner;
    IERC20 public L;
    uint256 public deadline;
    bytes32 public merkleRoot;

    mapping(uint256 => uint256) private _claimedBitMap;

    event Claimed(uint256 indexed index, address indexed account, uint256 indexed amount);
    event Withdrawal(address indexed to, uint256 indexed amount);
    event Reset(address indexed token, bytes32 indexed merkleRoot, uint256 indexed deadline);

    modifier nonReentrant() {
        require(!entered, "REENTRANT");
        entered = true;
        _;
        entered = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    constructor(address _token, bytes32 _merkleRoot, uint256 _deadline) {
        L = IERC20(_token);
        merkleRoot = _merkleRoot;
        deadline = _deadline;
        owner = msg.sender;
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = _claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        _claimedBitMap[claimedWordIndex] = _claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external nonReentrant {
        require(block.timestamp < deadline, "The airdrop has ended");
        require(!isClaimed(index), "Airdrop has been claimed");
        bytes32 leaf = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Invalid proof");
        _setClaimed(index);
        L.safeTransfer(account, amount);
        emit Claimed(index, account, amount);
    }

    function withdraw(address to) external onlyOwner {
        require(block.timestamp > deadline, "Airdrop not over");
        uint256 balance = L.balanceOf(address(this));
        require(balance > 0, "Insufficient balance");
        L.safeTransfer(to, balance);
        emit Withdrawal(to, balance);
    }

    function reset(address _token, bytes32 _merkleRoot, uint256 _deadline) external onlyOwner {
        L = IERC20(_token);
        merkleRoot = _merkleRoot;
        deadline = _deadline;
        emit Reset(_token, _merkleRoot, _deadline);
    }
}