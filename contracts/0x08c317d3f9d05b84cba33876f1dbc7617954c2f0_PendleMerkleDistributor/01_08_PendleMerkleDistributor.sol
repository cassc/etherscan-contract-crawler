// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";
import "../periphery/BoringOwnable.sol";
import "../libraries/TokenUtilsLib.sol";

contract PendleMerkleDistributor is BoringOwnable {
    using TokenUtils for IERC20;
    using SafeMath for uint256;

    struct IncentiveData {
        uint32 epochBegin;
        uint32 epochEnd;
        uint192 total;
        // sum 256 bits
    }

    address public immutable rewardToken;
    bytes32 public merkleRoot;
    mapping(address => uint256) public claimedAmount;

    event Claimed(address indexed user, uint256 amount);

    constructor(address _rewardToken) BoringOwnable() {
        rewardToken = _rewardToken;
    }

    function setNewRootAndFund(bytes32 newRoot, uint256 amountToFund) external onlyOwner {
        merkleRoot = newRoot;
        if (amountToFund > 0) {
            fund(amountToFund);
        }
    }

    function fund(uint256 amount) public {
        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) external onlyOwner {
        IERC20(rewardToken).safeTransfer(msg.sender, amount);
    }

    function claim(
        address user,
        uint256 totalAmount,
        bytes32[] calldata merkleProof
    ) external returns (uint256 amountOut) {
        // no reentrancy protection needed

        bytes32 node = keccak256(abi.encodePacked(user, totalAmount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "INVALID_PROOF");

        amountOut = totalAmount.sub(claimedAmount[user]);
        claimedAmount[user] = claimedAmount[user].add(amountOut);

        emit Claimed(user, amountOut);
        IERC20(rewardToken).safeTransfer(user, amountOut);
    }
}