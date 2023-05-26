// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Drop {
    using MerkleProof for bytes;
    using SafeERC20 for IERC20;

    struct DropData {
        uint256 startDate;
        uint256 endDate;
        uint256 tokenAmount;
        address owner;
        bool isActive;
    }

    address public factory;
    address public token;

    mapping(bytes32 => DropData) public dropData;
    mapping(bytes32 => mapping(uint256 => uint256)) private claimedBitMap;

    constructor() {
        factory = msg.sender;
    }

    modifier onlyFactory {
        require(msg.sender == factory, "DROP_ONLY_FACTORY");
        _;
    }

    function initialize(address tokenAddress) external onlyFactory {
        token = tokenAddress;
    }

    function addDropData(
        address owner,
        bytes32 merkleRoot,
        uint256 startDate,
        uint256 endDate,
        uint256 tokenAmount
    ) external onlyFactory {
        _addDropData(owner, merkleRoot, startDate, endDate, tokenAmount);
    }

    function claim(
        uint256 index,
        address account,
        uint256 amount,
        uint256 fee,
        address feeReceiver,
        bytes32 merkleRoot,
        bytes32[] calldata merkleProof
    ) external onlyFactory {
        DropData memory dd = dropData[merkleRoot];

        require(dd.startDate < block.timestamp, "DROP_NOT_STARTED");
        require(dd.endDate > block.timestamp, "DROP_ENDED");
        require(dd.isActive, "DROP_NOT_ACTIVE");
        require(!isClaimed(index, merkleRoot), "DROP_ALREADY_CLAIMED");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "DROP_INVALID_PROOF");

        // Calculate fees
        uint256 feeAmount = (amount * fee) / 10000;
        uint256 userReceivedAmount = amount - feeAmount;

        // Subtract from the drop amount
        dropData[merkleRoot].tokenAmount -= amount;

        // Mark it claimed and send the tokens.
        _setClaimed(index, merkleRoot);
        IERC20(token).safeTransfer(account, userReceivedAmount);
        if (feeAmount > 0) {
            IERC20(token).safeTransfer(feeReceiver, feeAmount);
        }
    }

    function _addDropData(
        address owner,
        bytes32 merkleRoot,
        uint256 startDate,
        uint256 endDate,
        uint256 tokenAmount
    ) internal {
        require(dropData[merkleRoot].startDate == 0, "DROP_EXISTS");
        require(endDate > block.timestamp, "DROP_INVALID_END_DATE");
        require(endDate > startDate, "DROP_INVALID_START_DATE");
        dropData[merkleRoot] = DropData(startDate, endDate, tokenAmount, owner, true);
    }

    function update(
        address account,
        bytes32 merkleRoot,
        bytes32 newMerkleRoot,
        uint256 newStartDate,
        uint256 newEndDate,
        uint256 newTokenAmount
    ) external onlyFactory returns (uint256 tokenAmount) {
        DropData memory dd = dropData[merkleRoot];
        require(dd.owner == account, "DROP_ONLY_OWNER");
        tokenAmount = dd.tokenAmount + newTokenAmount;
        _addDropData(dd.owner, newMerkleRoot, newStartDate, newEndDate, tokenAmount);
        delete dropData[merkleRoot];
    }

    function withdraw(address account, bytes32 merkleRoot) external onlyFactory returns (uint256) {
        DropData memory dd = dropData[merkleRoot];
        require(dd.owner == account, "DROP_ONLY_OWNER");

        delete dropData[merkleRoot];

        IERC20(token).safeTransfer(account, dd.tokenAmount);
        return dd.tokenAmount;
    }

    function isClaimed(uint256 index, bytes32 merkleRoot) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[merkleRoot][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function pause(address account, bytes32 merkleRoot) external onlyFactory {
        DropData memory dd = dropData[merkleRoot];
        require(dd.owner == account, "NOT_OWNER");
        dropData[merkleRoot].isActive = false;
    }

    function unpause(address account, bytes32 merkleRoot) external onlyFactory {
        DropData memory dd = dropData[merkleRoot];
        require(dd.owner == account, "NOT_OWNER");
        dropData[merkleRoot].isActive = true;
    }

    function _setClaimed(uint256 index, bytes32 merkleRoot) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[merkleRoot][claimedWordIndex] = claimedBitMap[merkleRoot][claimedWordIndex] | (1 << claimedBitIndex);
    }
}