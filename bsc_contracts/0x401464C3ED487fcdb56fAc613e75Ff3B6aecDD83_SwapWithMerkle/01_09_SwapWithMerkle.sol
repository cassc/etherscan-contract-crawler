// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {MerkleProof} from "./lib/MerkleProof.sol";

contract SwapWithMerkle is Ownable, ReentrancyGuard{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    mapping(address => bool) public excludeList;
    mapping(address => uint256) public swappedAmount;
    
    address public immutable oldToken;
    address public immutable newToken;
    bytes32 public immutable merkleRoot;
    uint256 public maxSwap = 5 * (10 ** 6) * (10 ** 18);

    event Swapped(address, uint256);

    constructor(address oldToken_, address newToken_, bytes32 _merkleRoot)
    {
        require (oldToken_ != address(0), "invalid token address");
        require (newToken_ != address(0), "invalid token address");

        oldToken = oldToken_;
        newToken = newToken_;
        merkleRoot = _merkleRoot;
    }

    function updateSwapLimit(uint256 amount) external onlyOwner {
        maxSwap = amount;
    }

    function withdrawNewTokens(uint256 amount, address target) external onlyOwner {
        require (IERC20(newToken).balanceOf(address(this)) >= amount, "invalid amount");
        
        IERC20(newToken).safeTransfer(target, amount);
    }

    function withdrawOldTokens(uint256 amount, address target) external onlyOwner {
        require (IERC20(oldToken).balanceOf(address(this)) >= amount, "invalid amount");
        
        IERC20(oldToken).safeTransfer(target, amount);
    }

    function swap(uint256 amount, uint256 index, uint256 merkleAmount, bytes32[] calldata merkleProof) external nonReentrant {
        require (swappedAmount[msg.sender] + amount <= merkleAmount, "invalid amount");
        require (IERC20(newToken).balanceOf(address(this)) >= amount, "no enough balance");
        require (!excludeList[msg.sender], "invalid address");
        require (amount <= maxSwap, "amount exceeds limit");
        
        bytes32 node = keccak256(abi.encodePacked(index, msg.sender, merkleAmount));
        require(MerkleProof._verify(merkleProof, merkleRoot, node), "invalid merkle data");
        
        IERC20(oldToken).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(newToken).safeTransfer(msg.sender, amount);
        swappedAmount[msg.sender] += amount;

        emit Swapped(msg.sender, amount);
    }

    function addExcludeAccounts(address[] memory accounts) external onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            excludeList[accounts[i]] = true;
        }
    }
    
    function removeExcludeAccounts(address[] memory accounts) external onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            excludeList[accounts[i]] = false;
        }
    }
}