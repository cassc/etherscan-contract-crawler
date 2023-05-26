// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IDropFactory.sol";

import "./Drop.sol";

contract DropFactory is IDropFactory {
    using SafeERC20 for IERC20;

    uint256 public fee;
    address public feeReceiver;
    address public timelock;
    mapping(address => address) public drops;

    constructor(
        uint256 _fee,
        address _feeReceiver,
        address _timelock
    ) {
        fee = _fee;
        feeReceiver = _feeReceiver;
        timelock = _timelock;
    }

    modifier dropExists(address tokenAddress) {
        require(drops[tokenAddress] != address(0), "FACTORY_DROP_DOES_NOT_EXIST");
        _;
    }

    modifier onlyTimelock() {
        require(msg.sender == timelock, "FACTORY_ONLY_TIMELOCK");
        _;
    }

    function createDrop(address tokenAddress) external override {
        require(drops[tokenAddress] == address(0), "FACTORY_DROP_EXISTS");
        bytes memory bytecode = type(Drop).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(tokenAddress));
        address dropAddress = Create2.deploy(0, salt, bytecode);
        Drop(dropAddress).initialize(tokenAddress);
        drops[tokenAddress] = dropAddress;
        emit DropCreated(dropAddress, tokenAddress);
    }

    function addDropData(
        uint256 tokenAmount,
        uint256 startDate,
        uint256 endDate,
        bytes32 merkleRoot,
        address tokenAddress
    ) external override dropExists(tokenAddress) {
        address dropAddress = drops[tokenAddress];
        IERC20(tokenAddress).safeTransferFrom(msg.sender, dropAddress, tokenAmount);
        Drop(dropAddress).addDropData(msg.sender, merkleRoot, startDate, endDate, tokenAmount);
        emit DropDataAdded(tokenAddress, merkleRoot, tokenAmount, startDate, endDate);
    }

    function updateDropData(
        uint256 additionalTokenAmount,
        uint256 startDate,
        uint256 endDate,
        bytes32 oldMerkleRoot,
        bytes32 newMerkleRoot,
        address tokenAddress
    ) external override dropExists(tokenAddress) {
        address dropAddress = drops[tokenAddress];
        IERC20(tokenAddress).safeTransferFrom(msg.sender, dropAddress, additionalTokenAmount);
        uint256 tokenAmount = Drop(dropAddress).update(msg.sender, oldMerkleRoot, newMerkleRoot, startDate, endDate, additionalTokenAmount);
        emit DropDataUpdated(tokenAddress, oldMerkleRoot, newMerkleRoot, tokenAmount, startDate, endDate);
    }

    function claimFromDrop(
        address tokenAddress,
        uint256 index,
        uint256 amount,
        bytes32 merkleRoot,
        bytes32[] calldata merkleProof
    ) external override dropExists(tokenAddress) {
        Drop(drops[tokenAddress]).claim(index, msg.sender, amount, fee, feeReceiver, merkleRoot, merkleProof);
        emit DropClaimed(tokenAddress, index, msg.sender, amount, merkleRoot);
    }

    function multipleClaimsFromDrop(
        address tokenAddress,
        uint256[] calldata indexes,
        uint256[] calldata amounts,
        bytes32[] calldata merkleRoots,
        bytes32[][] calldata merkleProofs
    ) external override dropExists(tokenAddress) {
        uint256 tempFee = fee;
        address tempFeeReceiver = feeReceiver;
        for (uint256 i = 0; i < indexes.length; i++) {
            Drop(drops[tokenAddress]).claim(indexes[i], msg.sender, amounts[i], tempFee, tempFeeReceiver, merkleRoots[i], merkleProofs[i]);
            emit DropClaimed(tokenAddress, indexes[i], msg.sender, amounts[i], merkleRoots[i]);
        }
    }

    function withdraw(address tokenAddress, bytes32 merkleRoot) external override dropExists(tokenAddress) {
        uint256 withdrawAmount = Drop(drops[tokenAddress]).withdraw(msg.sender, merkleRoot);
        emit DropWithdrawn(tokenAddress, msg.sender, merkleRoot, withdrawAmount);
    }

    function updateFee(uint256 newFee) external override onlyTimelock {
        // max fee 20%
        require(newFee < 2000, "FACTORY_MAX_FEE_EXCEED");
        fee = newFee;
    }

    function updateFeeReceiver(address newFeeReceiver) external override onlyTimelock {
        feeReceiver = newFeeReceiver;
    }

    function pause(address tokenAddress, bytes32 merkleRoot) external override {
        Drop(drops[tokenAddress]).pause(msg.sender, merkleRoot);
        emit DropPaused(merkleRoot);
    }

    function unpause(address tokenAddress, bytes32 merkleRoot) external override {
        Drop(drops[tokenAddress]).unpause(msg.sender, merkleRoot);
        emit DropUnpaused(merkleRoot);
    }

    function getDropDetails(address tokenAddress, bytes32 merkleRoot)
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            address,
            bool
        )
    {
        return Drop(drops[tokenAddress]).dropData(merkleRoot);
    }

    function isDropClaimed(
        address tokenAddress,
        uint256 index,
        bytes32 merkleRoot
    ) external view override dropExists(tokenAddress) returns (bool) {
        return Drop(drops[tokenAddress]).isClaimed(index, merkleRoot);
    }
}