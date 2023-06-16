//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM`MMM NMM MMM MMM MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM  MMMMhMMMMMMM  MMMMMMMM MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMM  MM-MMMMM   MMMM    MMMM   lMMMDMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMM jMMMMl   MM    MMM  M  MMM   M   MMMM MMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMM MMMMMMMMM  , `     M   Y   MM  MMM  BMMMMMM MMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMM MMMMMMMMMMMM  IM  MM  l  MMM  X   MM.  MMMMMMMMMM MMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM.nlMMMMMMMMMMMMMMMMM]._  MMMMMMMMMMMMMMMNMMMMMMMMMMMMMM
// MMMMMMMMMMMMMM TMMMMMMMMMMMMMMMMMM          +MMMMMMMMMMMM:  rMMMMMMMMN MMMMMMMMMMMMMM
// MMMMMMMMMMMM MMMMMMMMMMMMMMMM                  MMMMMM           MMMMMMMM qMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMM^                   MMMb              .MMMMMMMMMMMMMMMMMMM
// MMMMMMMMMM MMMMMMMMMMMMMMM                     MM                  MMMMMMM MMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMM                     M                   gMMMMMMMMMMMMMMMMM
// MMMMMMMMu MMMMMMMMMMMMMMM                                           MMMMMMM .MMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMM                                           :MMMMMMMMMMMMMMMM
// MMMMMMM^ MMMMMMMMMMMMMMMl                                            MMMMMMMM MMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMM                                             MMMMMMMMMMMMMMMM
// MMMMMMM MMMMMMMMMMMMMMMM                                             MMMMMMMM MMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMM                                             MMMMMMMMMMMMMMMM
// MMMMMMr MMMMMMMMMMMMMMMM                                             MMMMMMMM .MMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMM                                           MMMMMMMMMMMMMMMMM
// MMMMMMM MMMMMMMMMMMMMMMMM                                         DMMMMMMMMMM MMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMM                              MMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMM|`MMMMMMMMMMMMMMMM         q                      MMMMMMMMMMMMMMMMMMM  MMMMMMM
// MMMMMMMMMTMMMMMMMMMMMMMMM                               qMMMMMMMMMMMMMMMMMMgMMMMMMMMM
// MMMMMMMMq MMMMMMMMMMMMMMMh                             jMMMMMMMMMMMMMMMMMMM nMMMMMMMM
// MMMMMMMMMM MMMMMMMMMMMMMMMQ      nc    -MMMMMn        MMMMMMMMMMMMMMMMMMMM MMMMMMMMMM
// MMMMMMMMMM.MMMMMMMMMMMMMMMMMMl            M1       `MMMMMMMMMMMMMMMMMMMMMMrMMMMMMMMMM
// MMMMMMMMMMMM MMMMMMMMMMMMMMMMMMMM               :MMMMMMMMMM MMMMMMMMMMMM qMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMM  MMMMMMX       MMMMMMMMMMMMMMM  uMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMM DMMMMMMMMM   IMMMMMMMMMMMMMMMMMMMMMMM   M   Y  MMMMMMMN MMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMM MMMMMM    ``    M      MM  MMM   , MMMM    Mv  MMM MMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMM MMh  Ml  .   M  MMMM  I  MMMT  M     :M   ,MMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMM MMMMMMMMt  MM  MMMMB m  ]MMM  MMMM   MMMMMM MMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMM MMMMM  MMM   TM   MM  9U  .MM  _MMMMM MMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMM YMMMMMMMn     MMMM    +MMMMMMM1`MMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM MMMMMMMMMMMMMMMMMMMMMMM MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM.`MMM MMM MMMMM`.MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MM     M M    M M    M______  ____   ___   __ __  ____   ___  M M     M M    M M   MM
// MM    M M    M M    M|      ||    \ /   \ |  |  ||    \ /  _]  M M     M M    M M  MM
// MM   M M    M M    M |      ||  D  )     ||  |  ||  o  )  [_    M M     M M    M M MM
// MM  M M    M M    M M|_|  |_||    /|  O  ||  |  ||   _/    _]    M M     M M    M MMM
// MM M M    M M    M M   |  |  |    \|     ||  :  ||  | |   [_ M    M M     M M    M MM
// MMM M    M M    M M    |  |  |  .  \     ||     ||  | |     | M    M M     M M    MMM
// MM M    M M    M M     |__|  |__|\_|\___/  \__,_||__| |_____|M M    M M     M M    MM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM author: phaze MMM

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

import './lib/Ownable.sol';
import {VRFBaseMainnet as VRFBase} from './lib/VRFBase.sol';

import './Gouda.sol';
import './MadMouseStaking.sol';

error PublicSaleNotActive();
error WhitelistNotActive();
error InvalidAmount();
error ExceedsLimit();
error SignatureExceedsLimit();
error IncorrectValue();
error InvalidSignature();
error ContractCallNotAllowed();

error InvalidString();
error MaxLevelReached();
error MaxNumberReached();
error MinHoldDurationRequired();

error IncorrectHash();
error CollectionAlreadyRevealed();
error CollectionNotRevealed();
error TokenDataAlreadySet();
error MintAndStakeMinHoldDurationNotReached();

interface IMadMouseMetadata {
    function buildMouseMetadata(uint256 tokenId, uint256 level) external view returns (string memory);
}

contract MadMouseTroupe is Ownable, MadMouseStaking, VRFBase {
    using ECDSA for bytes32;
    using UserDataOps for uint256;
    using TokenDataOps for uint256;
    using DNAOps for uint256;

    bool public publicSaleActive;

    uint256 constant MAX_SUPPLY = 5000;
    uint256 constant MAX_PER_WALLET = 50;

    uint256 constant PURCHASE_LIMIT = 3;
    uint256 constant whitelistPrice = 0.075 ether;

    address public metadata;
    address public multiSigTreasury = 0xFB79a928C5d6c5932Ba83Aa8C7145cBDCDb9fd2E;
    address signerAddress = 0x3ADE0c5e35cbF136245F4e4bBf4563BD151d39D1;

    uint256 public totalLevel2Reached;
    uint256 public totalLevel3Reached;

    uint256 constant LEVEL_2_COST = 120 * 1e18;
    uint256 constant LEVEL_3_COST = 350 * 1e18;

    uint256 constant MAX_NUM_LEVEL_2 = 3300;
    uint256 constant MAX_NUM_LEVEL_3 = 1200;

    uint256 constant NAME_CHANGE_COST = 25 * 1e18;
    uint256 constant BIO_CHANGE_COST = 15 * 1e18;

    uint256 constant MAX_LEN_NAME = 20;
    uint256 constant MAX_LEN_BIO = 35;

    uint256 constant MINT_AND_STAKE_MIN_HOLD_DURATION = 3 days;
    uint256 profileUpdateMinHoldDuration = 30 days;

    mapping(uint256 => string) public mouseName;
    mapping(uint256 => string) public mouseBio;

    string public description;
    string public imagesBaseURI;
    string constant unrevealedURI = 'ipfs://QmW9NKUGYesTiYx5iSP1o82tn4Chq9i1yQV6DBnzznrHTH';

    bool private revealed;
    bytes32 immutable secretHash;

    constructor(bytes32 secretHash_) MadMouseStaking(MAX_SUPPLY, MAX_PER_WALLET) {
        secretHash = secretHash_;
        _mintAndStake(multiSigTreasury, 30, false);
    }

    /* ------------- External ------------- */

    function mint(uint256 amount, bool stake) external payable noContract {
        if (!publicSaleActive) revert PublicSaleNotActive();
        if (PURCHASE_LIMIT < amount) revert ExceedsLimit();

        uint256 price_ = price();
        if (msg.value != price_ * amount) revert IncorrectValue();

        if (price_ == 0) {
            // free mints will at first be restricted to purchase limit
            uint256 numMinted = _userData[msg.sender].numMinted();
            if (numMinted + amount > PURCHASE_LIMIT) revert ExceedsLimit();

            // free mints > 1 will be staked
            if (amount != 1) stake = true;
        }

        _mintAndStake(msg.sender, amount, stake);
    }

    function whitelistMint(
        uint256 amount,
        uint256 limit,
        bytes calldata signature,
        bool stake
    ) external payable noContract {
        if (publicSaleActive) revert WhitelistNotActive();
        if (!validSignature(signature, limit)) revert InvalidSignature();

        uint256 numMinted = _userData[msg.sender].numMinted();
        if (numMinted + amount > limit) revert ExceedsLimit();

        _mintAndStake(msg.sender, amount, stake);
    }

    function levelUp(uint256 tokenId) external payable {
        uint256 tokenData = _tokenDataOf(tokenId);
        address owner = tokenData.trueOwner();

        if (owner != msg.sender) revert IncorrectOwner();

        uint256 level = tokenData.level();
        if (level > 2) revert MaxLevelReached();

        if (level == 1) {
            if (totalLevel2Reached >= MAX_NUM_LEVEL_2) revert MaxNumberReached();
            gouda.burnFrom(msg.sender, LEVEL_2_COST);
            ++totalLevel2Reached;
        } else {
            if (totalLevel3Reached >= MAX_NUM_LEVEL_3) revert MaxNumberReached();
            gouda.burnFrom(msg.sender, LEVEL_3_COST);
            ++totalLevel3Reached;
        }

        uint256 newTokenData = tokenData.increaseLevel().resetOwnerCount();

        if (tokenData.staked() && revealed) {
            uint256 userData = _claimReward();
            (userData, newTokenData) = updateDataWhileStaked(userData, tokenId, tokenData, newTokenData);
            _userData[msg.sender] = userData;
        }

        _tokenData[tokenId] = newTokenData;
    }

    function setName(uint256 tokenId, string calldata name) external payable onlyLongtermHolder(tokenId) {
        if (!isValidString(name, MAX_LEN_NAME)) revert InvalidString();

        gouda.burnFrom(msg.sender, NAME_CHANGE_COST);
        mouseName[tokenId] = name;
    }

    function setBio(uint256 tokenId, string calldata bio) external payable onlyLongtermHolder(tokenId) {
        if (!isValidString(bio, MAX_LEN_BIO)) revert InvalidString();

        gouda.burnFrom(msg.sender, BIO_CHANGE_COST);
        mouseBio[tokenId] = bio;
    }

    // only to be used by owner in extreme cases when these reflect negatively on the collection
    // since they are automatically shown in the metadata (on OpenSea)
    function resetName(uint256 tokenId) external payable {
        address _owner = _tokenDataOf(tokenId).trueOwner();
        if (_owner != msg.sender && owner() != msg.sender) revert IncorrectOwner();
        delete mouseName[tokenId];
    }

    function resetBio(uint256 tokenId) external payable {
        address _owner = _tokenDataOf(tokenId).trueOwner();
        if (_owner != msg.sender && owner() != msg.sender) revert IncorrectOwner();
        delete mouseBio[tokenId];
    }

    /* ------------- View ------------- */

    function price() public view returns (uint256) {
        return totalSupply < 3500 ? 0 ether : .02 ether;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert NonexistentToken();
        if (!revealed || address(metadata) == address(0)) return unrevealedURI;
        return IMadMouseMetadata(address(metadata)).buildMouseMetadata(tokenId, this.getLevel(tokenId));
    }

    function previewTokenURI(uint256 tokenId, uint256 level) external view returns (string memory) {
        if (!_exists(tokenId)) revert NonexistentToken();
        if (!revealed || address(metadata) == address(0)) return unrevealedURI;
        return IMadMouseMetadata(address(metadata)).buildMouseMetadata(tokenId, level);
    }

    function getDNA(uint256 tokenId) external view onceRevealed returns (uint256) {
        if (!_exists(tokenId)) revert NonexistentToken();
        return computeDNA(tokenId);
    }

    function getLevel(uint256 tokenId) external view returns (uint256) {
        return _tokenDataOf(tokenId).level();
    }

    /* ------------- Private ------------- */

    function validSignature(bytes calldata signature, uint256 limit) private view returns (bool) {
        bytes32 msgHash = keccak256(abi.encode(address(this), msg.sender, limit));
        return msgHash.toEthSignedMessageHash().recover(signature) == signerAddress;
    }

    // not guarded for reveal
    function computeDNA(uint256 tokenId) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(randomSeed, tokenId)));
    }

    /* ------------- Owner ------------- */

    function setPublicSaleActive(bool active) external payable onlyOwner {
        publicSaleActive = active;
    }

    function setProfileUpdateMinHoldDuration(uint256 duration) external payable onlyOwner {
        profileUpdateMinHoldDuration = duration;
    }

    function giveAway(address[] calldata to, uint256[] calldata amounts) external payable onlyOwner {
        for (uint256 i; i < to.length; ++i) _mintAndStake(to[i], amounts[i], false);
    }

    function setSignerAddress(address address_) external payable onlyOwner {
        signerAddress = address_;
    }

    function setMetadataAddress(address metadata_) external payable onlyOwner {
        metadata = metadata_;
    }

    function withdraw() external payable onlyOwner {
        uint256 balance = address(this).balance;
        multiSigTreasury.call{value: balance}('');
    }

    function recoverToken(IERC20 token) external payable onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function setDescription(string memory description_) external payable onlyOwner {
        description = description_;
    }

    // requires that the reveal is first done through chainlink vrf
    function setImagesBaseURI(string memory uri) external payable onlyOwner onceRevealed {
        imagesBaseURI = uri;
    }

    // extra security for reveal:
    // the owner sets a hash of a secret seed
    // once chainlink randomness fulfills, the secret is revealed and shifts the secret seed set by chainlink
    // Why? The final randomness should come from a trusted third party,
    // however devs need time to generate the collection from the metadata.
    // There is a time-frame in which an unfair advantage is gained after the seed is set and before the metadata is revealed.
    // This eliminates any possibility of the team generating an unfair seed and any unfair advantage by snipers.
    function reveal(string memory _imagesBaseURI, bytes32 secretSeed_) external payable onlyOwner whenRandomSeedSet {
        if (revealed) revert CollectionAlreadyRevealed();
        if (secretHash != keccak256(abi.encode(secretSeed_))) revert IncorrectHash();

        revealed = true;
        imagesBaseURI = _imagesBaseURI;
        _shiftRandomSeed(uint256(secretSeed_));
    }

    /* ------------- Hooks ------------- */

    // update role, level information when staking
    function _beforeStakeDataTransform(
        uint256 tokenId,
        uint256 userData,
        uint256 tokenData
    ) internal view override returns (uint256, uint256) {
        // assumption that mint&stake won't have revealed yet
        if (!tokenData.mintAndStake() && tokenData.role() == 0 && revealed)
            tokenData = tokenData.setRoleAndRarity(computeDNA(tokenId));
        userData = userData.updateUserDataStake(tokenData);
        return (userData, tokenData);
    }

    function _beforeUnstakeDataTransform(
        uint256,
        uint256 userData,
        uint256 tokenData
    ) internal view override returns (uint256, uint256) {
        userData = userData.updateUserDataUnstake(tokenData);
        if (tokenData.mintAndStake() && block.timestamp - tokenData.lastTransfer() < MINT_AND_STAKE_MIN_HOLD_DURATION)
            revert MintAndStakeMinHoldDurationNotReached();
        return (userData, tokenData);
    }

    function updateStakedTokenData(uint256[] calldata tokenIds) external payable onceRevealed {
        uint256 userData = _claimReward();
        uint256 tokenId;
        uint256 tokenData;
        for (uint256 i; i < tokenIds.length; ++i) {
            tokenId = tokenIds[i];
            tokenData = _tokenDataOf(tokenId);

            if (tokenData.trueOwner() != msg.sender) revert IncorrectOwner();
            if (!tokenData.staked()) revert TokenIdUnstaked(); // only useful for staked ids
            if (tokenData.role() != 0) revert TokenDataAlreadySet();

            (userData, tokenData) = updateDataWhileStaked(userData, tokenId, tokenData, tokenData);

            _tokenData[tokenId] = tokenData;
        }
        _userData[msg.sender] = userData;
    }

    // note: must be guarded by check for revealed
    function updateDataWhileStaked(
        uint256 userData,
        uint256 tokenId,
        uint256 oldTokenData,
        uint256 newTokenData
    ) private view returns (uint256, uint256) {
        uint256 userDataX;
        // add in the role and rarity data if not already
        uint256 tokenDataX = newTokenData.role() != 0
            ? newTokenData
            : newTokenData.setRoleAndRarity(computeDNA(tokenId));

        // update userData as if to unstake with old tokenData and stake with new tokenData
        userDataX = userData.updateUserDataUnstake(oldTokenData).updateUserDataStake(tokenDataX);
        return applySafeDataTransform(userData, newTokenData, userDataX, tokenDataX);
    }

    // simulates a token update and only returns ids != 0 if
    // the user gets a bonus increase upon updating staked data
    function shouldUpdateStakedIds(address user) external view returns (uint256[] memory) {
        if (!revealed) return new uint256[](0);

        uint256[] memory stakedIds = this.tokenIdsOf(user, 1);

        uint256 userData = _userData[user];
        uint256 oldTotalBonus = totalBonus(user, userData);

        uint256 tokenData;
        for (uint256 i; i < stakedIds.length; ++i) {
            tokenData = _tokenDataOf(stakedIds[i]);
            if (tokenData.role() == 0)
                (userData, ) = updateDataWhileStaked(userData, stakedIds[i], tokenData, tokenData);
            else stakedIds[i] = 0;
        }

        uint256 newTotalBonus = totalBonus(user, userData);

        return (newTotalBonus > oldTotalBonus) ? stakedIds : new uint256[](0);
    }

    /* ------------- Modifier ------------- */

    modifier onceRevealed() {
        if (!revealed) revert CollectionNotRevealed();
        _;
    }

    modifier noContract() {
        if (tx.origin != msg.sender) revert ContractCallNotAllowed();
        _;
    }

    modifier onlyLongtermHolder(uint256 tokenId) {
        uint256 tokenData = _tokenDataOf(tokenId);
        uint256 timeHeld = block.timestamp - tokenData.lastTransfer();

        if (tokenData.trueOwner() != msg.sender) revert IncorrectOwner();
        if (timeHeld < profileUpdateMinHoldDuration) revert MinHoldDurationRequired();
        _;
    }
}