// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ClaimRewards is ReentrancyGuard {
    using Strings for uint256;

    address owner;
    address admin;
    bytes32 public root;

    event Claim(uint256 _rewardId, uint256 _rewards);
    event UpdateAdmin(address oldOwner, address newOwner);
    event UpdateOwner(address oldOwner, address newOwner);

    constructor(
        address _admin,
        address _owner,
        bytes32 _root
    ) {
        owner = _owner;
        admin = _admin;
        root = _root;
    }

    function setOwner(address _owner) external nonReentrant {
        require(owner == msg.sender, "not owner");
        owner = _owner;
        emit UpdateOwner(msg.sender, owner);
    }

    function setRoot(bytes32 _root) external nonReentrant {
        require(admin == msg.sender, "not owner");
        root = _root;
    }

    function setAdmin(address _admin) external nonReentrant {
        require(admin == msg.sender, "not owner");
        admin = _admin;
        emit UpdateAdmin(msg.sender, owner);
    }

    function claimRewards(
        uint256 _rewardId,
        bytes32[] memory _merkleProof,
        uint256 _rewards
    ) external {
        bytes32 leafToCheck = keccak256(
            abi.encodePacked(_rewardId.toString(), ",", _rewards.toString())
        );

        require(
            MerkleProof.verify(_merkleProof, root, leafToCheck),
            "Incorrect land proof"
        );

        (bool success, ) = msg.sender.call{value: _rewards}("");
        require(success, "refund failed");

        emit Claim(_rewardId, _rewards);
    }

    function emergencyWithdraw() external nonReentrant {
        require(owner == msg.sender, "not owner");
        _transferETH(address(this).balance);
    }

    function _transferETH(uint256 _amount) internal {
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "refund failed");
    }

    receive() external payable {}
}