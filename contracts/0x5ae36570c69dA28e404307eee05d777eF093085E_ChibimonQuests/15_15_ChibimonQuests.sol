// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {IERC721} from '@openzeppelin/contracts/interfaces/IERC721.sol';
import {IERC1155} from '@openzeppelin/contracts/interfaces/IERC1155.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';

error IncorrectSignature();
error QuestNotActive();
error NoQuestAmountAvailable();
error TokenAlreadyCompletedQuest(uint256 tokenId);
error AddressCantBeBurner();
error QuestIdCantBeZero();
error QuestAlreadyExists();

contract ChibimonQuests is Ownable, ReentrancyGuard {

    using ECDSA for bytes32;

    struct Quest {
        uint256 id;
        uint32 amount;
        uint32 activeFrom;
        uint32 activeUntil;
        uint32 apeCoinRewards;
    }

    struct QuestNftReward {
        uint32 nftContractType;
        uint256 nftRewardTokenId;
        address nftRewardContract;
        uint32 nftRewardTokenAmount;
    }

    address private signer;
    address public treasury;

    mapping(uint256 => mapping(uint256 => bool)) public tokenHistory;
    mapping(uint256 => Quest) public quests;
    mapping(uint256 => QuestNftReward[]) public questNftRewards;
    uint256[] public questIds;
    uint256 public nextQuestId;

    IERC20 public immutable apeCoin;

    constructor(address apeCoinAddress, address signerAddress, uint256 startQuestId) {
        treasury = msg.sender;
        signer = signerAddress;
        nextQuestId = startQuestId;

        apeCoin = IERC20(apeCoinAddress);
    }

    // external

    function claim(bytes calldata signature, uint256 questId, uint256[] calldata tokenIds) external nonReentrant {
        if( !_verifySig(msg.sender, questId, tokenIds, signature) ) revert IncorrectSignature();
        if( (quests[questId].activeFrom > block.timestamp || quests[questId].activeUntil < block.timestamp) ) revert QuestNotActive();
        if( quests[questId].amount <= 0 ) revert NoQuestAmountAvailable();

        for(uint32 i; i < tokenIds.length; i++) {
            if( tokenHistory[tokenIds[i]][questId] ) revert TokenAlreadyCompletedQuest(tokenIds[i]);
            tokenHistory[tokenIds[i]][questId] = true;
        }

        _claim(msg.sender, questId);
    }

    // external owner

    function claimForHolder(address holder, uint256 questId) external onlyOwner {
        if( quests[questId].amount <= 0 ) revert NoQuestAmountAvailable();

        _claim(holder, questId);
    }

    function setTokenQuestHistory(uint256 tokenId, uint256 questId, bool status) external onlyOwner {
        tokenHistory[tokenId][questId] = status;
    }

    function createQuest(uint32 amount, uint32 activeFrom, uint32 activeUntil, uint32 apeCoinRewards, uint32[] calldata nftRewardContractTypes, address[] calldata nftRewardContracts, uint256[] calldata nftRewardTokenIds, uint32[] calldata nftRewardTokenAmounts) external onlyOwner {
        uint256 questId = _createQuest(amount, activeFrom, activeUntil, apeCoinRewards);

        for( uint32 i; i < nftRewardContracts.length; i++) {
            _addNftReward(questId, nftRewardContractTypes[i], nftRewardContracts[i], nftRewardTokenIds[i], nftRewardTokenAmounts[i]);
        }
    }

    function createQuest(uint32 amount, uint32 activeFrom, uint32 activeUntil, uint32 apeCoinRewards) external onlyOwner {
        _createQuest(amount, activeFrom, activeUntil, apeCoinRewards);
    }

    function editQuestAmount(uint256 id, uint32 amount) external onlyOwner {
        quests[id].amount = amount;
    }

    function editQuestActiveTimespan(uint256 id, uint32 activeFrom, uint32 activeUntil) external onlyOwner {
        quests[id].activeFrom = activeFrom;
        quests[id].activeUntil = activeUntil;
    }

    function editQuestApeCoinRewards(uint256 id, uint32 apeCoinRewards) external onlyOwner {
        quests[id].apeCoinRewards = apeCoinRewards;
    }

    function editQuestNftRewards(uint256 id, uint32[] calldata nftRewardContractTypes, address[] calldata nftRewardContracts, uint256[] calldata nftRewardTokenIds, uint32[] calldata nftRewardTokenAmounts) external onlyOwner {

        delete questNftRewards[id];

        for( uint32 i; i < nftRewardContracts.length; i++) {
            _addNftReward(id, nftRewardContractTypes[i], nftRewardContracts[i], nftRewardTokenIds[i], nftRewardTokenAmounts[i]);
        }

    }

    function deleteQuest(uint256 id) external onlyOwner {
        delete quests[id];

        for(uint32 i; i < questIds.length; i++) {
            if(questIds[i] == id ) {
                delete questIds[i];
                break;
            }
        }
    }

    function setSigner(address signerAddress) external onlyOwner {
        if( signerAddress == address(0) ) revert AddressCantBeBurner();
        signer = signerAddress;
    }

    // public views

    function getQuests() public view returns(Quest[] memory) {
        return _getQuests(false);
    }

    function getActiveQuests() public view returns(Quest[] memory) {
        return _getQuests(true);
    }

    function getQuestNftRewards(uint256 questId) public view returns(QuestNftReward[] memory) {
        return _getQuestNftRewards(questId);
    }

    function getTokenQuestHistory(uint256 tokenId) public view returns(uint256[] memory) {
        uint256[] memory tokenQuests = new uint256[](_getTokenQuestHistoryCount(tokenId));
        uint32 tokenQuestIndex;

        for(uint32 i; i < questIds.length; i++) {
            if(tokenHistory[tokenId][questIds[i]]) {
                tokenQuests[tokenQuestIndex++] = questIds[i];
            }
        }

        return tokenQuests;
    }

    // internal

    function _createQuest(uint32 amount, uint32 activeFrom, uint32 activeUntil, uint32 apeCoinRewards) internal returns(uint256) {

        uint256 questId = nextQuestId;

        Quest memory newQuest = Quest(
            questId,
            amount,
            activeFrom,
            activeUntil,
            apeCoinRewards
        );

        quests[questId] = newQuest;
        questIds.push(questId);

        ++nextQuestId;

        return questId;

    }

    function _addNftReward(uint256 questId, uint32 nftContractType, address nftRewardContract, uint256 nftRewardTokenId, uint32 nftRewardTokenAmount) internal {

        QuestNftReward memory newReward = QuestNftReward(
            nftContractType,
            nftRewardTokenId,
            nftRewardContract,
            nftRewardTokenAmount
        );

        questNftRewards[questId].push(newReward);

    }

    function _claim(address sender, uint256 questId) internal {

        --quests[questId].amount;

        Quest memory currentQuest = quests[questId];

        if(currentQuest.apeCoinRewards > 0) {
            apeCoin.transferFrom(treasury, sender, currentQuest.apeCoinRewards * 1e18);
        }

        if(questNftRewards[questId].length > 0) {
            QuestNftReward[] memory currentRewards = questNftRewards[questId];

            for( uint32 i; i < currentRewards.length; i++) {
                if(currentRewards[i].nftContractType == 1) {
                    IERC721 nftContract = IERC721(currentRewards[i].nftRewardContract);
                    nftContract.safeTransferFrom(treasury, sender, currentRewards[i].nftRewardTokenId);
                } else if(currentRewards[i].nftContractType == 2) {
                    IERC1155 nftContract = IERC1155(currentRewards[i].nftRewardContract);
                    nftContract.safeTransferFrom(treasury, sender, currentRewards[i].nftRewardTokenId, currentRewards[i].nftRewardTokenAmount, "");
                }
            }
        }

    }

    // internal views

    function _getTokenQuestHistoryCount(uint256 tokenId) internal view returns(uint32) {
            uint32 tokenQuestCount;

            for(uint32 i; i < questIds.length; i++) {
                if(tokenHistory[tokenId][questIds[i]]) {
                    tokenQuestCount++;
                }
            }

            return tokenQuestCount;
    }

    function _getQuestCount(bool onlyActive) internal view returns(uint32) {
        uint32 questCount;

        for(uint32 i; i < questIds.length; i++) {
            if( questIds[i] > 0 &&
            ( !onlyActive || (quests[questIds[i]].activeFrom <= block.timestamp && quests[questIds[i]].activeUntil >= block.timestamp))) {
                questCount++;
            }
        }

        return questCount;
    }

    function _getQuests(bool onlyActive) internal view returns(Quest[] memory) {
        Quest[] memory allQuests = new Quest[](_getQuestCount(onlyActive));
        uint32 questIndex;

        for(uint32 i; i < questIds.length; i++) {
            if( questIds[i] > 0 &&
            ( !onlyActive || (quests[questIds[i]].activeFrom <= block.timestamp && quests[questIds[i]].activeUntil >= block.timestamp))) {
                allQuests[questIndex++] = quests[questIds[i]];
            }
        }

        return allQuests;
    }

    function _getQuestNftRewards(uint256 id) internal view returns(QuestNftReward[] memory) {
        QuestNftReward[] memory questRewards = new QuestNftReward[](questNftRewards[id].length);
        uint32 questRewardIndex;

        for(uint32 i; i < questNftRewards[id].length; i++) {
            questRewards[questRewardIndex++] = questNftRewards[id][i];
        }

        return questRewards;
    }

    function _verifySig(address sender, uint256 questId, uint256[] calldata tokenIds, bytes memory signature) internal view returns(bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(sender, questId, tokenIds));
        return signer == messageHash.toEthSignedMessageHash().recover(signature);
    }

}