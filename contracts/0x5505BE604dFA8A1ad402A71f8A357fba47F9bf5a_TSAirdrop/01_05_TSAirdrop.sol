// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "./interfaces/IERC20.sol";
import {IERC4626} from "./interfaces/IERC4626.sol";
import {ReentrancyGuard} from "../lib/ReentrancyGuard.sol";
import {MerkleProof} from "../lib/MerkleProof.sol";

contract TSAirdrop is ReentrancyGuard {
    IERC20 public thor;
    IERC4626 public vTHOR;
    bytes32 public merkleRoot;
    uint256 public airdropAmount;
    address public owner;
    bool public isAirdropLive;
    mapping(address => bool) public claimed;

    event Claimed(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    constructor(
        IERC20 _thor,
        IERC4626 _vTHOR,
        bytes32 _merkleRoot,
        uint256 _airdropAmount
    ) {
        thor = _thor;
        vTHOR = _vTHOR;
        merkleRoot = _merkleRoot;
        airdropAmount = _airdropAmount;
        owner = msg.sender;
        isAirdropLive = true;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setAirdropAmount(uint256 _airdropAmount) external onlyOwner {
        airdropAmount = _airdropAmount;
    }

    function toggleAirdrop() external onlyOwner {
        isAirdropLive = !isAirdropLive;
    }

    function verify(
        address user,
        bytes32[] calldata merkleProof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(user));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    function previewClaim(
        address user,
        bytes32[] calldata merkleProof
    ) external view returns (uint256) {
        require(isAirdropLive, "Airdrop is not live");
        require(!claimed[user], "Airdrop already claimed");
        require(verify(user, merkleProof), "Invalid Merkle proof");

        return airdropAmount;
    }

    function claim(bytes32[] calldata merkleProof) external nonReentrant {
        require(isAirdropLive, "Airdrop is not live");
        require(!claimed[msg.sender], "Airdrop already claimed");
        require(verify(msg.sender, merkleProof), "Invalid Merkle proof");

        claimed[msg.sender] = true;
        thor.transfer(msg.sender, airdropAmount);

        emit Claimed(msg.sender, airdropAmount);
    }

    function claimAndStake(
        bytes32[] calldata merkleProof
    ) external nonReentrant {
        require(isAirdropLive, "Airdrop is not live");
        require(!claimed[msg.sender], "Airdrop already claimed");
        require(verify(msg.sender, merkleProof), "Invalid Merkle proof");

        claimed[msg.sender] = true;
        thor.approve(address(vTHOR), airdropAmount);
        vTHOR.deposit(airdropAmount, msg.sender);

        emit Claimed(msg.sender, airdropAmount);
    }

    function withdrawRemainingTokens(address to) external onlyOwner {
        uint256 remainingTokens = thor.balanceOf(address(this));
        thor.transfer(to, remainingTokens);
    }
}