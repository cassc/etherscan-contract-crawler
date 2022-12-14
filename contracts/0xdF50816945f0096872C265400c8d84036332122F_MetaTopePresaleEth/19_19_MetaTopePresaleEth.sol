//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./MetaTopeIERC1155Receiver.sol";

/**
 * @title Contract for MetaTope Presale
 * Copyright 2022 MetaTope
 */
contract MetaTopePresaleEth is MetaTopeIERC1155Receiver, Ownable, ReentrancyGuard {
    ERC1155 public rewardToken;
    uint128 public rewardTokenId;
    bytes32 public merkleRoot;

    address[] public buyerAddresses;

    bool public started;
    uint256 public totalTokenAmount;
    uint256 public pricePerToken;
    bool public isWhitelistMode;
    uint128 public startAt;
    uint128 public endAt;
    uint256 public maxTokenPerAddress;

    event StartPresale();
    event EndPresale();
    event Buy(address indexed user, uint256 tokenAmount);
    event Withdraw(address to);

    modifier onlyStarted() {
        require(started == true, "Auction should not be ended");
        require(endAt >= uint128(block.timestamp), "Auction was already ended");
        _;
    }

    /**
     * @dev Constructor
     * @param _rewardToken reward token after presale finished
     * @param _rewardTokenId reward token id by default 0
     * @param _isWhitelistMode set whitelist mode
     */
    constructor(
        ERC1155 _rewardToken,
        uint128 _rewardTokenId,
        bool _isWhitelistMode
    ) {
        rewardToken = _rewardToken;
        rewardTokenId = _rewardTokenId;
        isWhitelistMode = _isWhitelistMode;
    }

    /**
     * @dev Function to set merkle root
     * @param _merkleRoot set merkleRoot
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @dev Function to start presale
     * @param _totalTokenAmount set totalTokenAmount
     * @param _pricePerToken set token price per token
     * @param _endDuration set presale duration
     * @param _maxTokenPerAddress set max amount of tokens
     */
    function start(
        uint256 _totalTokenAmount,
        uint256 _pricePerToken,
        uint128 _endDuration,
        uint256 _maxTokenPerAddress
    ) external onlyOwner {
        require(started == false, "Presale should not be started yet");
        require(_totalTokenAmount > 0, "TotalTokenAmount should be greater than zero");

        totalTokenAmount = _totalTokenAmount;
        pricePerToken = _pricePerToken;
        maxTokenPerAddress = _maxTokenPerAddress;
        started = true;
        startAt = uint128(block.timestamp);
        endAt = startAt + (_endDuration * 1 days);
        rewardToken.safeTransferFrom(msg.sender, address(this), rewardTokenId, totalTokenAmount, "0x");

        emit StartPresale();
    }

    /**
     * @dev Function to bid or update
     * @param _tokenAmount Token Amount
     */
    function buy(
        uint256 _tokenAmount,
        bytes32[] calldata _merkleProof
    ) external payable onlyStarted nonReentrant {
        if (isWhitelistMode) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Buyer should be whitelisted");
        }

        require(_tokenAmount > 0, "TokenAmount should be greater than zero");

        uint256 _rewardTokenAmount = rewardToken.balanceOf(address(this), rewardTokenId);
        require(_rewardTokenAmount >= _tokenAmount, "Insufficient funds");

        uint256 buyerRewardTokenAmount = rewardToken.balanceOf(msg.sender, rewardTokenId);
        require(maxTokenPerAddress >= _tokenAmount + buyerRewardTokenAmount, "TokenAmount should be less than maxTokenPerAddress");

        require(pricePerToken * _tokenAmount == msg.value, "Amount sent should be equal total price");

        rewardToken.safeTransferFrom(address(this), msg.sender, rewardTokenId, _tokenAmount, "0x");
        buyerAddresses.push(msg.sender);

        emit Buy(msg.sender, _tokenAmount);
    }

    /**
     * @dev Function to get buyer addresses in chunks
     */
    function getBuyerAddresses(uint256 _from, uint256 _count) external view returns(address[] memory) {
        uint256 from = _from;
        uint256 range = _from + _count;
        uint256 index = 0;
        address[] memory mBuyers = new address[](range);
        for (from; from < range; ++from) {
            if (from >= buyerAddresses.length) break;
            mBuyers[index] = buyerAddresses[from];
            index++;
        }
        return mBuyers;
    }

    /**
     * @dev Function to withdraw funds
     * @param _to withdraw
     */
    function withdraw(address payable _to) external onlyOwner {
        require(started == false, "Auction must be ended before withdrawal");
        uint256 _rewardTokenAmount = rewardToken.balanceOf(address(this), rewardTokenId);
        _to.transfer(address(this).balance);

        if(_rewardTokenAmount > 0) {
            rewardToken.safeTransferFrom(address(this), _to, rewardTokenId, _rewardTokenAmount, "0x");
        }

        emit Withdraw(_to);
    }

    /**
     * @dev Function to forcefully ended
     */
    function end() external onlyOwner {
        require(started == true, "Presale should not be ended");

        endAt = uint128(block.timestamp);
        started = false;
        emit EndPresale();
    }
}