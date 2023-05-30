// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract TokenClaim is Ownable, ReentrancyGuard {
    using MerkleProof for bytes32[];
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    bool public disabled;
    bytes32 public tokenClaimMerkleRoot;
    IERC20 public token;
    uint256 public currentRound;
    mapping(uint256 => mapping(address => bool)) public roundClaimed;
    uint256 public startTime;
    uint256 public endTime;

    /* ========== CONSTRUCTOR ========== */

    constructor(IERC20 _token, bytes32 _claimMerkleRoot, uint256 _startTime, uint256 _endTime) {
        token = _token;
        _setMerkleRootAndStartEndTime(_claimMerkleRoot, _startTime, _endTime);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setDisabled(bool _disabled) external onlyOwner {
        disabled = _disabled;
        emit SetDisabled(_disabled);
    }

    function withdraw(IERC20 _token) external onlyOwner {
        if (_token == token) {
            require(block.timestamp < startTime || endTime < block.timestamp, "cannot withdraw reward token when claim activated");
        }
        uint256 _tokenBalance = _token.balanceOf(address(this));
        _token.safeTransfer(msg.sender, _tokenBalance);
        emit Withdraw(_token, msg.sender, _tokenBalance);
    }

    function setNewMerkleRootAndStartEndTime(bytes32 _claimMerkleRoot, uint256 _startTime, uint256 _endTime) external onlyOwner {
        _setMerkleRootAndStartEndTime(_claimMerkleRoot, _startTime, _endTime);
    }

    function _setMerkleRootAndStartEndTime(bytes32 _claimMerkleRoot, uint256 _startTime, uint256 _endTime) internal {
        if (currentRound != 0) {
            require(block.timestamp < startTime || endTime < block.timestamp, "can only be set before current startTime or after current endTime");
        }
        require(block.timestamp < _startTime, "new startTime should be larger than current timestamp");
        require(_startTime < _endTime, "new endTime should be larger than new startTime");
        tokenClaimMerkleRoot = _claimMerkleRoot;
        startTime = _startTime;
        endTime = _endTime;
        currentRound += 1;
        emit SetMerkleRootAndStartEndTime(_claimMerkleRoot, _startTime, _endTime, currentRound);
    }

    /* ========== WRITE FUNCTIONS ========== */

    function claim(bytes32[] memory proof, uint256 amount)
        external
        nonReentrant
    {
        require(!disabled, "the contract is disabled");
        require(block.timestamp > startTime, "claim has not started");
        require(block.timestamp < endTime, "claim has finished");
        require(!roundClaimed[currentRound][msg.sender], "this address has already claimed");
        require(
            proof.verify(
                tokenClaimMerkleRoot,
                keccak256(abi.encodePacked(msg.sender, amount))
            ),
            "failed to verify merkle proof"
        );

        roundClaimed[currentRound][msg.sender] = true;
        token.safeTransfer(msg.sender, amount);
        emit TokenClaimed(msg.sender, currentRound, amount);
    }

    /* ========== EVENTS ========== */

    event TokenClaimed(address indexed _address, uint256 indexed _round, uint256 _amount);
    event SetMerkleRootAndStartEndTime(bytes32 _root, uint256 _startTime, uint256 _endTime, uint256 indexed _round);
    event Withdraw(IERC20 _token, address _address, uint256 _amount);
    event SetDisabled(bool _disabled);
}