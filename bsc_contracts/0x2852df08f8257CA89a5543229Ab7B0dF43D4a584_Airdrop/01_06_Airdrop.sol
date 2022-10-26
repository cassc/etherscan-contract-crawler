// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Airdrop is Ownable, ReentrancyGuard {

    uint256 public immutable amountOfAirdrop;
    address public immutable airdropToken;
    bytes32 public merkleRoot;
    uint256 public startTime;
    uint256 public endTime;

    mapping(address => bool) public airdropMinted;
    constructor(address token_) {
        airdropToken = token_;
        amountOfAirdrop = 1000 ether;
    }

    function claim(bytes32[] calldata proof_) external notContract nonReentrant {
        require(block.timestamp > startTime || startTime == 0, "not start");
        require(block.timestamp < endTime || endTime == 0, "time end");
        require(isLegalListed(proof_, merkleRoot, _msgSender()), "not in list");
        require(!airdropMinted[_msgSender()], "minted");
        airdropMinted[_msgSender()] = true;
        IERC20(airdropToken).transfer(_msgSender(), amountOfAirdrop);
    }

    function setClaimTime(uint256 startTime_, uint256 endTime_) external onlyOwner {
        startTime = startTime_;
        endTime = endTime_;
    }

    function claimAll() external onlyOwner {
        uint256 balance = IERC20(airdropToken).balanceOf(address(this));
        IERC20(airdropToken).transfer(_msgSender(), balance);
    }

    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }

    function leaf(address account_) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(account_));
    }

    function isLegalListed(
        bytes32[] calldata proof_,
        bytes32 merkleRoot_,
        address account_
    ) private pure returns (bool) {
        return MerkleProof.verify(proof_, merkleRoot_, leaf(account_));
    }

    modifier notContract() {
        uint256 size;
        address addr = msg.sender;
        assembly {
            size := extcodesize(addr)
        }
        require(size == 0, "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }
}