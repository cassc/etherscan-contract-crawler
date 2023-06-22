// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ERC20Claim is Ownable, Pausable, ReentrancyGuard {
    IERC20 public claimToken;
    mapping(uint256 => bytes32) public merkles;
    mapping(address => mapping(uint256 => bool)) public claimed;

    event Claimed(address indexed to, uint256 amount);

    constructor() {
        pause();
    }

    function verify(
        bytes32 root,
        bytes32[] memory proof,
        address account,
        uint256 allocatedAmount
    ) public pure returns (bool) {
        return MerkleProof.verify(proof, root, keccak256(abi.encodePacked(account, allocatedAmount)));
    }

    modifier checkMerkle(uint256 allocatedAmount, address sender, uint256 index, bytes32[] memory proof) {
        require(verify(merkles[index], proof, sender, allocatedAmount), "Not in list");
        require(!hasClaimed(index, sender), "Already claimed");
        _;
    }
    /**
        @param index - the merkle tree they belong to
        @param allocatedAmount - the amount of tokens they have been allocated
        @param proof - proof of being in merkle tree

        @dev claim for the token
     */
    function claim(
        uint256 index,  
        uint256 allocatedAmount, 
        bytes32[] memory proof
    ) 
        external 
        nonReentrant
        whenNotPaused 
        checkMerkle(allocatedAmount, msg.sender, index, proof) 
    {
        claimed[msg.sender][index] = true;
        claimToken.transfer(
            msg.sender,
            allocatedAmount * 1 ether
        );
        emit Claimed(msg.sender, allocatedAmount);
    }

    function setMerkle(uint256 index, bytes32 root) external onlyOwner {
        merkles[index] = root;
    }

    /**
        @param _claimToken - the token which users will claim
        @dev to change the token - NOTE: changing this will change the token for past merkles as welll
     */

    function setClaimToken(IERC20 _claimToken) external onlyOwner {
        claimToken = _claimToken;
    }

    /**
        @dev emergency withdraw of token from contract
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 currentBalance = claimToken.balanceOf(address(this));
        claimToken.transfer(
            msg.sender,
            currentBalance
        );
    }

    function pause() public onlyOwner {
        _pause();
    }

    function hasClaimed(uint256 index, address to) public view returns (bool) {
        return claimed[to][index];
    }

    function unpause() public onlyOwner {
        require(address(claimToken) != address(0x0), "Claim token not set");
        uint256 currentBalance = claimToken.balanceOf(address(this));
        require(currentBalance > 0, "Claim token not provided");
        _unpause();
    }
}