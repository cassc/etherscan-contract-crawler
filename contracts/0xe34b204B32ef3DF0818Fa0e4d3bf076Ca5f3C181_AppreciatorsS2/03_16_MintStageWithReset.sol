// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error InvalidMintAmount();
error InvalidDuration();
error NotOpenMint();
error ReachedMintStageLimit();
error ReachedMintWalletLimit();
error NotWhitelisted();
error NotEnoughPayment();

contract MintStageWithReset is Ownable {
    struct Stage {
        uint256 id;
        uint256 totalLimit;
        uint256 walletLimit;
        uint256 rate;
        uint256 walletLimitCounter;
        uint256 openingTime;
        uint256 closingTime;
        bytes32 whitelistRoot;
        bool isPublic;
    }

    Stage public currentStage;

    mapping(uint256 => mapping(address => uint256)) public walletMintCount;

    uint256 private constant BATCH_LIMIT = 10000;

    event MintStageUpdated(
        uint256 indexed _stage,
        uint256 _stageLimit,
        uint256 _stageLimitPerWallet,
        uint256 _rate,
        uint256 _openingTime,
        uint256 _closingTIme
    );

    function setMintStage(
        uint256 _stage,
        uint256 _stageLimit,
        uint256 _stageLimitPerWallet,
        uint256 _rate,
        uint256 _openingTime,
        uint256 _closingTime,
        bytes32 _whitelistMerkleRoot,
        bool _isPublic,
        bool _resetClaimCounter
    ) public onlyOwner {
        if (_openingTime > _closingTime) {
            revert InvalidDuration();
        }

        uint256 currentLimitWalletPerCounter = currentStage.walletLimitCounter;

        if (_resetClaimCounter) {
            currentLimitWalletPerCounter = currentLimitWalletPerCounter + 1;
        }

        currentStage = Stage(
            _stage,
            _stageLimit,
            _stageLimitPerWallet,
            _rate,
            currentLimitWalletPerCounter,
            _openingTime,
            _closingTime,
            _whitelistMerkleRoot,
            _isPublic
        );

        emit MintStageUpdated(
            _stage,
            _stageLimit,
            _stageLimitPerWallet,
            _rate,
            _openingTime,
            _closingTime
        );
    }

    function _verifyMint(
        bytes32[] calldata _merkleProof,
        uint256 _mintAmount,
        uint256 currentMintedCount,
        uint256 discount
    ) internal {
        address sender = msg.sender;
        uint256 sentAmount = msg.value;

        if (_mintAmount == 0 || _mintAmount > BATCH_LIMIT) {
            revert InvalidMintAmount();
        }

        if (!isStageOpen()) {
            revert NotOpenMint();
        }

        if (currentMintedCount + _mintAmount > currentStage.totalLimit) {
            revert ReachedMintStageLimit();
        }

        uint256 mintCount = walletMintCount[currentStage.walletLimitCounter][
            sender
        ];
        if (
            currentStage.walletLimit > 0 &&
            mintCount + _mintAmount > currentStage.walletLimit
        ) {
            revert ReachedMintWalletLimit();
        }

        if (!currentStage.isPublic) {
            bytes32 leaf = keccak256(abi.encodePacked(sender));

            if (
                !MerkleProof.verify(
                    _merkleProof,
                    currentStage.whitelistRoot,
                    leaf
                )
            ) {
                revert NotWhitelisted();
            }
        }

        uint256 requiredPayment = _mintAmount * (currentStage.rate - discount);
        if (sentAmount < requiredPayment) {
            revert NotEnoughPayment();
        }
    }

    function isStageOpen() public view returns (bool) {
        return
            block.timestamp >= currentStage.openingTime &&
            block.timestamp <= currentStage.closingTime;
    }

    function _updateWalletMintCount(address sender, uint256 _mintAmount)
        internal
    {
        uint256 mintCount = walletMintCount[currentStage.walletLimitCounter][
            sender
        ];
        walletMintCount[currentStage.walletLimitCounter][sender] =
            mintCount +
            _mintAmount;
    }
}