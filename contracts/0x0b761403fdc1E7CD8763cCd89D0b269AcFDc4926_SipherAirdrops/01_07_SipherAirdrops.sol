// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Pausable.sol";

contract SipherAirdrops is Ownable, Pausable {
    using SafeERC20 for IERC20;

    struct AirdropsConfig {
        uint32 startTime; // the airdrops start time in UNIX time format, e.g. 1643043600
        uint32 vestingInterval; //time between 2 vesting points in seconds e.g. 86400, 2592000, ...
        uint32 numberOfVestingPoint; //number of scheduled vesting points, e.g. 1, 3, 6, 12, ...
    }

    event Claim(address indexed account, uint256 amount, uint32 airdropsID);

    bytes32 public whitelistedMerkleRoot;

    uint32 public airdropsID;

    mapping(uint256 => mapping(address => uint256)) public claimed;

    IERC20 public tokenDrops;

    AirdropsConfig public airdropsConfig;

    constructor(
        IERC20 _tokenDrops,
        AirdropsConfig memory _airdropsConfig,
        bytes32 _whitelistedMerkleRoot
    ) {
        _initAirdrop(_tokenDrops, _airdropsConfig, _whitelistedMerkleRoot);
    }

    /**
     * @dev Initiate airdrop
     */
    function _initAirdrop(
        IERC20 _tokenDrops,
        AirdropsConfig memory _airdropsConfig,
        bytes32 _whitelistedMerkleRoot
    ) internal {
        tokenDrops = _tokenDrops;
        whitelistedMerkleRoot = _whitelistedMerkleRoot;
        airdropsConfig = _airdropsConfig;
    }

    /**
     * @dev for Owner to update Merkle root hash
     *
     * Requirements:
     * - Only for Owner.
     */
    function updateWhitelistedMerkleRoot(bytes32 _whitelistedMerkleRoot) external onlyOwner {
        whitelistedMerkleRoot = _whitelistedMerkleRoot;
    }

    /**
     * @dev Claim airdrop token
     *
     * Requirements:
     * - The contract is not be paused
     * - Claim time is after start time
     * - Caller is a valid claimer (being in the airdrop's whitelist)
     * - Caller has available token to claim
     * - Enough tokens are available on the contract
     */
    function claim(uint256 totalAmount, bytes32[] memory proofs) external whenNotPaused {
        uint256 timeStamp = block.timestamp;
        AirdropsConfig memory config = airdropsConfig;

        require(timeStamp >= config.startTime, "SipherAirdrops: airdrops not started yet");

        uint256 claimAmount = _releasableAmount(msg.sender, totalAmount, proofs, timeStamp);

        require(claimAmount > 0, "SipherAirdrops: no available token to claim");

        require(tokenDrops.balanceOf(address(this)) >= claimAmount, "SipherAirdrops: insufficient token in contract");

        claimed[airdropsID][msg.sender] += claimAmount;
        tokenDrops.safeTransfer(msg.sender, claimAmount);

        emit Claim(msg.sender, claimAmount, airdropsID);
    }

    /**
     * @dev Withdraw tokens from contract's balance
     *
     * Requirements:
     * - Only for contract owner
     */
    function withdrawFund(IERC20 _tokenERC20, uint256 amount) external onlyOwner {
        require(_tokenERC20.balanceOf(address(this)) >= amount, "SipherAirdrops: insufficient token in contract");
        _tokenERC20.safeTransfer(owner(), amount);
    }

    /**
     * @dev Update airdrop config: start time, vesting interval, number of vesting points
     *
     * Requirements:
     * - Only for contract owner
     */
    function updateAirdropsConfg(AirdropsConfig memory _airdropsConfig) external onlyOwner {
        airdropsConfig = _airdropsConfig;
    }

    /**
     * @dev Start a new airdrop
     *
     * Requirements:
     * - Only for contract owner
     */
    function startNewAirdrops(
        IERC20 _tokenDrops,
        AirdropsConfig memory _airdropsConfig,
        bytes32 _whitelistedMerkleRoot
    ) external onlyOwner {
        airdropsID += 1;
        _initAirdrop(_tokenDrops, _airdropsConfig, _whitelistedMerkleRoot);
    }

    /**
     * @dev Pause the contract, this will disable the `claim` function
     *
     * Requirements:
     * - Only for contract owner
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract, this will enable the `claim` function
     *
     * Requirements:
     * - Only for contract owner
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Check if an address is a valid claimer
     * It is recommended to visit Sipher website for automatically check if your address is eligible.
     */
    function isValidClaimer(
        address claimer,
        uint256 totalAmount,
        bytes32[] memory proofs
    ) external view returns (bool) {
        return _isWhitelistedAddress(claimer, totalAmount, proofs);
    }

    /**
     * @dev Calculate the claimable amount at a specific timestamp
     */
    function getClaimableAmountAtTimestamp(
        address claimer,
        uint256 totalAmount,
        bytes32[] memory proofs,
        uint32 timestamp
    ) external view returns (uint256) {
        return _releasableAmount(claimer, totalAmount, proofs, timestamp);
    }

    /**
     * @dev Private: verify if the address is valid with provided proofs
     */
    function _isWhitelistedAddress(
        address claimer,
        uint256 totalAmount,
        bytes32[] memory proofs
    ) private view returns (bool) {
        require(whitelistedMerkleRoot != bytes32(0), "SipherAirdrops: Merkle Root is not set yet");

        bytes32 computedHash = keccak256(abi.encode(claimer, totalAmount));
        for (uint256 i = 0; i < proofs.length; i++) {
            bytes32 proofElement = proofs[i];
            if (computedHash < proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        return computedHash == whitelistedMerkleRoot;
    }

    /**
     * @dev Private: verify if the address is valid and calculate the available amount to claim.
     */
    function _releasableAmount(
        address claimer,
        uint256 totalAmount,
        bytes32[] memory proofs,
        uint256 timeStamp
    ) private view returns (uint256) {
        require(_isWhitelistedAddress(claimer, totalAmount, proofs), "SipherAirdrops: invalid claimer");
        require(claimed[airdropsID][claimer] <= totalAmount, "SipherAirdrops: invalid claim amount");

        uint256 currentVestingPoint = (timeStamp - airdropsConfig.startTime) / airdropsConfig.vestingInterval + 1;
        uint256 vestingPosition = currentVestingPoint < airdropsConfig.numberOfVestingPoint
            ? currentVestingPoint
            : airdropsConfig.numberOfVestingPoint;

        return (totalAmount * vestingPosition) / airdropsConfig.numberOfVestingPoint - claimed[airdropsID][claimer];
    }
}