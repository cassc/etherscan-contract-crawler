// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.16;
pragma experimental ABIEncoderV2;

import {Initializable} from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import {IQuestFactory} from './interfaces/IQuestFactory.sol';
import {Quest as QuestContract} from './Quest.sol';
import {RabbitHoleReceipt} from './RabbitHoleReceipt.sol';
import {OwnableUpgradeable} from './OwnableUpgradeable.sol';
import {SafeERC20, IERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {ECDSAUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol';
import {AccessControlUpgradeable} from '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';
import {QuestTerminalKey} from "./QuestTerminalKey.sol";
import {QuestNFT as QuestNFTContract} from "./QuestNFT.sol";

/// @title QuestFactory
/// @author RabbitHole.gg
/// @dev This contract is used to create quests and mint receipts
contract QuestFactory is Initializable, OwnableUpgradeable, AccessControlUpgradeable, IQuestFactory {
    using SafeERC20 for IERC20;

    // storage vars. Insert new vars at the end to keep the storage layout the same.
    struct Quest {
        mapping(address => bool) addressMinted;
        address questAddress;
        uint totalParticipants;
        uint numberMinted;
    }
    address public claimSignerAddress;
    address public protocolFeeRecipient;
    address public erc20QuestAddress;
    address public erc1155QuestAddress;
    mapping(string => Quest) public quests;
    RabbitHoleReceipt public rabbitHoleReceiptContract;
    address public rabbitHoleTicketsContract;
    mapping(address => bool) public rewardAllowlist;
    uint16 public questFee;
    uint public mintFee;
    address public mintFeeRecipient;
    uint256 private locked;
    QuestTerminalKey private questTerminalKeyContract;
    uint public nftQuestFee;
    address public questNFTAddress;
    struct QuestNFTData {
        uint256 startTime;
        uint256 endTime;
        uint256 totalParticipants;
        string questId;
        string description;
        string imageIPFSHash;
    }
    struct QuestData {
        address questAddress;
        address rewardToken;
        bool queued;
        uint16 questFee;
        uint startTime;
        uint endTime;
        uint totalParticipants;
        uint numberMinted;
        uint redeemedTokens;
        uint rewardAmountInWei;
        bool hasWithdrawn;
    }
    mapping(address => address[]) public ownerCollections;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address claimSignerAddress_,
        address rabbitHoleReceiptContract_,
        address protocolFeeRecipient_,
        address erc20QuestAddress_,
        address ownerAddress_,
        address questTerminalKeyAddress_,
        address payable questNFTAddress_,
        uint nftQuestFee_
    ) external initializer {
        __Ownable_init(ownerAddress_);
        __AccessControl_init();
        claimSignerAddress = claimSignerAddress_;
        rabbitHoleReceiptContract = RabbitHoleReceipt(rabbitHoleReceiptContract_);
        protocolFeeRecipient = protocolFeeRecipient_;
        questFee = 2_000; // in BIPS
        erc20QuestAddress = erc20QuestAddress_;
        locked = 1;
        questTerminalKeyContract = QuestTerminalKey(questTerminalKeyAddress_);
        questNFTAddress = questNFTAddress_;
        nftQuestFee = nftQuestFee_;
    }

    /// @dev ReentrancyGuard modifier from solmate, copied here because it was added after storage layout was finalized on first deploy
    /// @dev from https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol
    modifier nonReentrant() virtual {
        if (locked == 0) locked = 1;
        require(locked == 1, "REENTRANCY");
        locked = 2;
        _;
        locked = 1;
    }

    modifier claimChecks(string memory questId_, bytes32 hash_, bytes memory signature_) {
        Quest storage currentQuest = quests[questId_];

        if (currentQuest.numberMinted + 1 > currentQuest.totalParticipants) revert OverMaxAllowedToMint();
        if (currentQuest.addressMinted[msg.sender]) revert AddressAlreadyMinted();
        if (keccak256(abi.encodePacked(msg.sender, questId_)) != hash_) revert InvalidHash();
        if (recoverSigner(hash_, signature_) != claimSignerAddress) revert AddressNotSigned();
        _;
    }

    modifier sufficientMintFee() {
        require(msg.value >= mintFee, "Insufficient mint fee");
        _;
    }

    /// @dev Create an erc20 quest, only accounts with the CREATE_QUEST_ROLE can create quests
    modifier checkQuest(string memory questId_, address rewardTokenAddress_) {
        Quest storage currentQuest = quests[questId_];
        if (currentQuest.questAddress != address(0)) revert QuestIdUsed();
        if (!rewardAllowlist[rewardTokenAddress_]) revert RewardNotAllowed();
        if (erc20QuestAddress == address(0)) revert Erc20QuestAddressNotSet();
        _;
    }

    modifier nonZeroAddress(address _address) {
        if (_address == address(0)) revert ZeroAddressNotAllowed();
        _;
    }

    function createQuestInternal(
        address rewardTokenAddress_,
        uint256 endTime_,
        uint256 startTime_,
        uint256 totalParticipants_,
        uint256 rewardAmount_,
        string memory questId_,
        uint256 discountTokenId_
    ) internal returns (address) {
        Quest storage currentQuest = quests[questId_];
        address newQuest = Clones.cloneDeterministic(erc20QuestAddress, keccak256(abi.encodePacked(msg.sender, questId_)));
        emit QuestCreated(
            msg.sender,
            address(newQuest),
            questId_,
            "erc20",
            rewardTokenAddress_,
            endTime_,
            startTime_,
            totalParticipants_,
            rewardAmount_
        );
        uint16 protocolFee;
        currentQuest.questAddress = address(newQuest);
        currentQuest.totalParticipants = totalParticipants_;

        if(discountTokenId_ == 0){
            protocolFee = questFee;
        }else{
            protocolFee = doDiscountedFee(discountTokenId_);
        }

        QuestContract(newQuest).initialize(
            rewardTokenAddress_,
            endTime_,
            startTime_,
            totalParticipants_,
            rewardAmount_,
            questId_,
            address(rabbitHoleReceiptContract),
            protocolFee,
            protocolFeeRecipient
        );

        return newQuest;
    }

    function doDiscountedFee(uint tokenId_) internal returns (uint16) {
        require(questTerminalKeyContract.ownerOf(tokenId_) == msg.sender, "QuestFactory: caller is not owner of discount token");

        (uint16 discountPercentage, ) = questTerminalKeyContract.discounts(tokenId_);

        questTerminalKeyContract.incrementUsedCount(tokenId_);
        return uint16((uint(questFee) * (10000 - uint(discountPercentage))) / 10000);
    }

    /// @dev Transfer the total transfer amount to the quest contract
    /// @dev Contract must be approved to transfer first
    /// @param newQuest_ The address of the new quest
    /// @param rewardTokenAddress_ The contract address of the reward token
    function transferTokensAndQueueQuest(address newQuest_, address rewardTokenAddress_) internal {
        IERC20(rewardTokenAddress_).safeTransferFrom(msg.sender, newQuest_, QuestContract(newQuest_).totalTransferAmount());
        QuestContract(newQuest_).queue();
    }

    /// @dev Create an erc20 quest
    /// @param rewardTokenAddress_ The contract address of the reward token
    /// @param endTime_ The end time of the quest
    /// @param startTime_ The start time of the quest
    /// @param totalParticipants_ The total amount of participants (accounts) the quest will have
    /// @param rewardAmount_ The reward amount for an erc20 quest
    /// @param questId_ The id of the quest
    /// @return address the quest contract address
    function createQuest(
        address rewardTokenAddress_,
        uint256 endTime_,
        uint256 startTime_,
        uint256 totalParticipants_,
        uint256 rewardAmount_,
        string memory, // was contractType_ , currently deprecated.
        string memory questId_
    ) external checkQuest(questId_, rewardTokenAddress_) returns (address) {
        address newQuest = createQuestInternal(
            rewardTokenAddress_,
            endTime_,
            startTime_,
            totalParticipants_,
            rewardAmount_,
            questId_,
            0
        );

        QuestContract(newQuest).transferOwnership(msg.sender);

        return newQuest;
    }

    /// @dev Create an erc20 quest and start it at the same time. The function will transfer the reward amount to the quest contract
    /// @param rewardTokenAddress_ The contract address of the reward token
    /// @param endTime_ The end time of the quest
    /// @param startTime_ The start time of the quest
    /// @param totalParticipants_ The total amount of participants (accounts) the quest will have
    /// @param rewardAmount_ The reward amount for an erc20 quest
    /// @param questId_ The id of the quest
    /// @param jsonSpecCID The CID of the JSON spec for the quest
    /// @param discountTokenId_ The id of the discount token
    /// @return address the quest contract address
    function createQuestAndQueue(
        address rewardTokenAddress_,
        uint256 endTime_,
        uint256 startTime_,
        uint256 totalParticipants_,
        uint256 rewardAmount_,
        string memory questId_,
        string memory jsonSpecCID,
        uint256 discountTokenId_
    ) external checkQuest(questId_, rewardTokenAddress_) returns (address) {
        address newQuest = createQuestInternal(
            rewardTokenAddress_,
            endTime_,
            startTime_,
            totalParticipants_,
            rewardAmount_,
            questId_,
            discountTokenId_
        );

        transferTokensAndQueueQuest(newQuest, rewardTokenAddress_);
        if(bytes(jsonSpecCID).length > 0) QuestContract(newQuest).setJsonSpecCID(jsonSpecCID);
        QuestContract(newQuest).transferOwnership(msg.sender);

        return newQuest;
    }

    /// @dev Create an ERC1155 QuestNFT collection
    /// @param collectionName_ The collection name of the 1155 NFT contract
    /// @return address the QuestNFT contract address
    function createCollection(string memory collectionName_) nonReentrant external returns (address) {
        address payable newQuestNFT = payable(Clones.cloneDeterministic(questNFTAddress, keccak256(abi.encodePacked(msg.sender, collectionName_))));

        QuestNFTContract(newQuestNFT).initialize(
            protocolFeeRecipient,
            address(this),
            collectionName_
        );
        QuestNFTContract(newQuestNFT).transferOwnership(msg.sender);

        ownerCollections[msg.sender].push(newQuestNFT);

        emit QuestNFTCreated(
            address(newQuestNFT),
            msg.sender,
            collectionName_
        );

        return newQuestNFT;
    }

    /// @dev Add a quest to a QuestNFT collection. The function will transfer the total questFee amount to the QuestNFT
    /// @param collectionAddress_ The address of the QuestNFT collection
    /// @param startTime_ The start time of the quest
    /// @param endTime_ The end time of the quest
    /// @param totalParticipants_ The total amount of participants (accounts) the quest will have
    /// @param questId_ The id of the quest
    /// @param description_ The description of the quest
    /// @param imageIPFSHash_ The IPFS hash of the image for the quest
    function addQuestToCollection(
        address payable collectionAddress_,
        uint256 startTime_,
        uint256 endTime_,
        uint256 totalParticipants_,
        string memory questId_,
        string memory description_,
        string memory imageIPFSHash_
    ) external payable nonReentrant {
        QuestNFTData memory data = QuestNFTData({
            startTime: startTime_,
            endTime: endTime_,
            totalParticipants: totalParticipants_,
            questId: questId_,
            description: description_,
            imageIPFSHash: imageIPFSHash_
        });

        Quest storage currentQuest = quests[data.questId];
        if (currentQuest.questAddress != address(0)) revert QuestIdUsed();
        require(msg.value >= totalQuestNFTFee(data.totalParticipants), "QuestFactory: msg.value is not equal to the total quest fee");
        require(msg.sender == QuestNFTContract(collectionAddress_).owner(), "QuestFactory: only the NFT quest owner can call this function");

        QuestNFTContract(collectionAddress_).addQuest(nftQuestFee, data.startTime, data.endTime, data.totalParticipants, data.questId, data.description, data.imageIPFSHash);

        currentQuest.questAddress = address(collectionAddress_);
        currentQuest.totalParticipants = data.totalParticipants;

        (bool success, ) = payable(collectionAddress_).call{value: msg.value}("");
        require(success, "QuestFactory: Failed to send coins to the QuestNFT contract");

        emit QuestCreated(
            msg.sender,
            collectionAddress_,
            data.questId,
            "nft",
            address(0), // rewardTokenAddress
            data.endTime,
            data.startTime,
            data.totalParticipants,
            1
        );
    }

    function ownerCollectionsByOwner(address owner_) external view returns (address[] memory) {
        return ownerCollections[owner_];
    }

    function totalQuestNFTFee(uint totalParticipants_) public view returns (uint256) {
        return nftQuestFee * totalParticipants_;
    }

    /// @dev set erc20QuestAddress
    /// @param erc20QuestAddress_ The address of the erc20 quest
    function setErc20QuestAddress(address erc20QuestAddress_) public onlyOwner {
        erc20QuestAddress = erc20QuestAddress_;
    }

    /// @dev set the claim signer address
    /// @param claimSignerAddress_ The address of the claim signer
    function setClaimSignerAddress(address claimSignerAddress_) public onlyOwner {
        claimSignerAddress = claimSignerAddress_;
    }

    /// @dev set the protocol fee recipient
    /// @param protocolFeeRecipient_ The address of the protocol fee recipient
    function setProtocolFeeRecipient(address protocolFeeRecipient_) public onlyOwner {
        if (protocolFeeRecipient_ == address(0)) revert AddressZeroNotAllowed();
        protocolFeeRecipient = protocolFeeRecipient_;
    }

    /// @dev set the mintFeeRecipient
    /// @param mintFeeRecipient_ The address of the mint fee recipient
    function setMintFeeRecipient(address mintFeeRecipient_) public onlyOwner {
        if (mintFeeRecipient_ == address(0)) revert AddressZeroNotAllowed();
        mintFeeRecipient = mintFeeRecipient_;
    }

    /// @dev get the mintFeeRecipient return the protocol fee recipient if the mint fee recipient is not set
    /// @return address the mint fee recipient
    function getMintFeeRecipient() public view returns (address) {
        if (mintFeeRecipient == address(0)) {
            return protocolFeeRecipient;
        }
        return mintFeeRecipient;
    }

    /// @dev set the rabbithole receipt contract
    /// @param rabbitholeReceiptContract_ The address of the rabbithole receipt contract
    function setRabbitHoleReceiptContract(address rabbitholeReceiptContract_) external onlyOwner {
        rabbitHoleReceiptContract = RabbitHoleReceipt(rabbitholeReceiptContract_);
    }

    /// @dev set the questNFT Address
    /// @param questNFTAddress_ The address of the questNFT
    function setQuestNFTAddress(address questNFTAddress_) external onlyOwner nonZeroAddress(questNFTAddress_) {
        questNFTAddress = questNFTAddress_;
    }

    /// @dev set the nftQuestFee
    /// @param nftQuestFee_ The value of the nftQuestFee
    function setNftQuestFee(uint nftQuestFee_) external onlyOwner {
        nftQuestFee = nftQuestFee_;
        emit NftQuestFeeSet(nftQuestFee_);
    }

    /// @dev set questTerminalKeyContract address
    /// @param questTerminalKeyContract_ The address of the questTerminalKeyContract
    function setQuestTerminalKeyContract(address questTerminalKeyContract_) external onlyOwner {
        questTerminalKeyContract = QuestTerminalKey(questTerminalKeyContract_);
    }

    /// @dev set or remave a contract address to be used as a reward
    /// @param rewardAddress_ The contract address to set
    /// @param allowed_ Whether the contract address is allowed or not
    function setRewardAllowlistAddress(address rewardAddress_, bool allowed_) public onlyOwner {
        rewardAllowlist[rewardAddress_] = allowed_;
    }

    /// @dev set the quest fee
    /// @notice the quest fee should be in Basis Point units
    /// @param questFee_ The quest fee value
    function setQuestFee(uint16 questFee_) public onlyOwner {
        if (questFee_ > 10_000) revert QuestFeeTooHigh();
        questFee = questFee_;
    }

    /// @dev set the mint fee
    /// @notice the mint fee in ether
    /// @param mintFee_ The mint fee value
    function setMintFee(uint mintFee_) public onlyOwner {
        mintFee = mintFee_;
        emit MintFeeSet(mintFee_);
    }

    /// @dev return the number of minted receipts for a quest
    /// @param questId_ The id of the quest
    function getNumberMinted(string memory questId_) external view returns (uint) {
        return quests[questId_].numberMinted;
    }

    /// @dev return extended quest data for a questId
    /// @param questId_ The id of the quest
    function questData(string memory questId_) external view returns (QuestData memory) {
        Quest storage thisQuest = quests[questId_];
        QuestContract questContract = QuestContract(thisQuest.questAddress);

        QuestData memory data = QuestData(
            thisQuest.questAddress,
            questContract.rewardToken(),
            questContract.queued(),
            questContract.questFee(),
            questContract.startTime(),
            questContract.endTime(),
            questContract.totalParticipants(),
            thisQuest.numberMinted,
            questContract.redeemedTokens(),
            questContract.rewardAmountInWei(),
            questContract.hasWithdrawn()
        );

        return data;
    }

    /// @dev return data in the quest struct for a questId
    /// @param questId_ The id of the quest
    function questInfo(string memory questId_) external view returns (address, uint, uint) {
        Quest storage currentQuest = quests[questId_];
        return (currentQuest.questAddress, currentQuest.totalParticipants, currentQuest.numberMinted);
    }

    /// @dev return status of whether an address has minted a receipt for a quest
    /// @param questId_ The id of the quest
    /// @param address_ The address to check
    /// @return Minted status
    function getAddressMinted(string memory questId_, address address_) external view returns (bool) {
        return quests[questId_].addressMinted[address_];
    }

    /// @dev recover the signer from a hash and signature
    /// @param hash_ The hash of the message
    /// @param signature_ The signature of the hash
    function recoverSigner(bytes32 hash_, bytes memory signature_) public pure returns (address) {
        bytes32 messageDigest = keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', hash_));
        return ECDSAUpgradeable.recover(messageDigest, signature_);
    }

    function claimRewards(string memory questId_, bytes32 hash_, bytes memory signature_) external payable nonReentrant sufficientMintFee claimChecks(questId_, hash_, signature_) {
        Quest storage currentQuest = quests[questId_];
        QuestContract questContract_ = QuestContract(currentQuest.questAddress);
        if (!questContract_.queued()) revert QuestNotQueued();
        if (block.timestamp < questContract_.startTime()) revert QuestNotStarted();
        if (block.timestamp > questContract_.endTime()) revert QuestEnded();

        currentQuest.addressMinted[msg.sender] = true;
        ++currentQuest.numberMinted;
        questContract_.singleClaim(msg.sender);

        if(mintFee > 0) processMintFee();

        emit QuestClaimed(msg.sender, currentQuest.questAddress, questId_, questContract_.rewardToken(), questContract_.rewardAmountInWei());
    }

    /// @dev mint a QuestNFT.
    /// @notice this contract must be set as Minter on the QuestNFT
    /// @param questId_ The id of the quest
    /// @param hash_ The hash of the message
    /// @param signature_ The signature of the hash
    function mintQuestNFT(string memory questId_, bytes32 hash_, bytes memory signature_) external nonReentrant claimChecks(questId_, hash_, signature_) {
        Quest storage currentQuest = quests[questId_];

        currentQuest.addressMinted[msg.sender] = true;
        ++currentQuest.numberMinted;
        QuestNFTContract(payable(currentQuest.questAddress)).mint(msg.sender, questId_);
        emit QuestNFTMinted(msg.sender, currentQuest.questAddress, QuestNFTContract(payable(currentQuest.questAddress)).tokenIdFromQuestId(questId_), questId_);
    }

    /// @dev mint a RabbitHole Receipt. Note: this contract must be set as Minter on the receipt contract
    /// @param questId_ The id of the quest
    /// @param hash_ The hash of the message
    /// @param signature_ The signature of the hash
    function mintReceipt(string memory questId_, bytes32 hash_, bytes memory signature_) external payable nonReentrant claimChecks(questId_, hash_, signature_) {
        Quest storage currentQuest = quests[questId_];
        if (!QuestContract(currentQuest.questAddress).queued()) revert QuestNotQueued();
        if (block.timestamp < QuestContract(currentQuest.questAddress).startTime()) revert QuestNotStarted();
        if (block.timestamp > QuestContract(currentQuest.questAddress).endTime()) revert QuestEnded();

        currentQuest.addressMinted[msg.sender] = true;
        ++currentQuest.numberMinted;
        rabbitHoleReceiptContract.mint(msg.sender, questId_);

        emit ReceiptMinted(msg.sender, quests[questId_].questAddress, rabbitHoleReceiptContract.getTokenId(), questId_);
    }

    function processMintFee() private {
        uint change = msg.value - mintFee;
        if (change > 0) {
            // Refund any excess payment
            (bool changeSuccess, ) = msg.sender.call{value: change}("");
            require(changeSuccess, "Failed to return change");
            emit ExtraMintFeeReturned(msg.sender, change);
        }
        // Send the mint fee to the mint fee recipient
        (bool mintSuccess, ) = getMintFeeRecipient().call{value: mintFee}("");
        require(mintSuccess, "Failed to send mint fee");
    }

    // Receive function to receive ETH
    receive() external payable {}

    // Fallback function to receive ETH when other functions are not available
    fallback() external payable {}
}