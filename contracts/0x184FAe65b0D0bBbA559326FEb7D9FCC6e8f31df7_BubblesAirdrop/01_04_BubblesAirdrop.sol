// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

//import "hardhat/console.sol";

/// @title Interface to interact with Bubbles contract.
interface IBubbles {
    function mint(address recipient, uint256 amount) external;
}

/// @author The Axolittles Team
/// @title Contract for claiming Bubbles airdrops
contract BubblesAirdrop is Ownable {
    address public TOKEN;
    bytes32 public merkleRoot;
    uint256 public version;

    struct recipient {
        address user;
        uint256 amount;
    }

    mapping(uint256 => mapping(address => bool)) internal claimed;

    constructor(address _tokenAddress) {
        TOKEN = _tokenAddress;
    }

    event ClaimAirdrop(
        address indexed owner,
        uint256 rewardAmount,
        uint256 version
    );
    event SendAirdrop(address indexed owner, uint256 rewardAmount);

    /**
    todo: claim migration rewards function
    pass in data via merkle root in format of addreess/$BUBBLE owed
    keep mapping(address => bool) rewardsTracker to track who has claimed already
  */
    function claimAirdrop(uint256 _amount, bytes32[] calldata merkleProof)
        external
    {
        require(!claimed[version][msg.sender], "Already claimed!");
        bytes32 node = keccak256(abi.encodePacked(msg.sender, _amount)); //check both address and amount
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "Verification failed!"
        );
        claimed[version][msg.sender] = true;
        IBubbles(TOKEN).mint(msg.sender, _amount);
        emit ClaimAirdrop(msg.sender, _amount, version);
    }

    //for admin to airdrop $BUBBLE to recipients
    function sendAirdrop(recipient[] memory _recipients) external onlyOwner {
        for (uint256 i = 0; i < _recipients.length; i++) {
            IBubbles(TOKEN).mint(_recipients[i].user, _recipients[i].amount);
            emit SendAirdrop(_recipients[i].user, _recipients[i].amount);
        }
    }

    /// @notice Function to change address of reward token
    function setTokenAddress(address _tokenAddress) external onlyOwner {
        TOKEN = _tokenAddress;
    }

    /// @notice Function to set new merkle root
    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
        version = version + 1;
    }
}