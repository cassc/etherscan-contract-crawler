// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { OwnableUpgradeable } from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import { ERC721CheckpointableUpgradeable } from './base/ERC721CheckpointableUpgradeable.sol';
import { ISweepersDescriptor } from './interfaces/ISweepersDescriptor.sol';
import { ISweepersSeeder } from './interfaces/ISweepersSeeder.sol';
import { ISweepersToken } from './interfaces/ISweepersToken.sol';
import { ISweepersTokenV1 } from './interfaces/ISweepersTokenV1.sol';
import { ERC721Upgradeable } from './base/ERC721Upgradeable.sol';
import { IERC721Upgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';
import { ReentrancyGuardUpgradeable } from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import { IERC721ReceiverUpgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol';
import { IProxyRegistry } from './external/opensea/IProxyRegistry.sol';
import { IDust } from './interfaces/IDust.sol';

contract SweepersTokenV2 is ISweepersToken, OwnableUpgradeable, ERC721CheckpointableUpgradeable, IERC721ReceiverUpgradeable, ReentrancyGuardUpgradeable {
    // The sweepersTreasury address
    address public sweepersTreasury;

    // An address who has permissions to mint Sweepers
    address public minter;

    // The Sweepers token URI descriptor
    ISweepersDescriptor public descriptor;

    // The Sweepers token seeder
    ISweepersSeeder public seeder;

    // The Sweepers V1 token
    ISweepersTokenV1 public sweepersV1;

    // The sweeper seeds
    mapping(uint256 => ISweepersSeeder.Seed) public override seeds;

    // The internal sweeper ID tracker
    uint256 private _currentSweeperId;

    // IPFS content hash of contract-level metadata
    string private _contractURIHash;

    // OpenSea's Proxy Registry
    IProxyRegistry public proxyRegistry;

    // The Dust token 
    IDust private DUST;

    // The base amount of Dust earned per day per Sweeper
    uint256 public dailyDust;

    // The timestamp that rewards will end (if/when applicable)
    uint80 private rewardEnd;

    // The total number of Sweepers staked in the garage
    uint256 public sweepersInGarage;

    // Mapping of background seed to the multiplier rate
    mapping(uint8 => uint16) public multiplier;

    // Mapping of an address to their staked Sweeper info
    mapping(address => stakedNFT) public StakedNFTInfo; // address to struct

    // Mapping of an address to the total number of Sweepers that they have staked
    mapping(address => uint256) public userStakedSweepers;

    // Address which will call to unstake if NFT is listed on a marketplace while staked
    mapping(address => bool) private remover; 

    // Address which will receive the penalty fee to recoup the tx fee of removing the stake
    address payable public PenaltyReceiver;

    // Mapping of an address to their penalty info from being removed
    mapping(address => unstakeEarnings) public penaltyEarnings;

    // Mapping of an address to the number of times they have been removed from the garage
    mapping(address => uint16) public timesRemoved;

    // Mapping of an address to whether they are currently blocked from the garage
    mapping(address => bool) public blockedFromGarage;

    // The number of times that someone is allowed to be removed from the garage before being blocked
    uint256 public allowedTimesRemoved;

    // The static penalty to be assessed if useCalculatedPenalty is false
    uint256 public penalty;

    // The adjuster to be applied to a calculated penalty amount as the calculation will always be inherently short 
    uint8 public penaltyAdjuster;

    // Whether to use calculated penalties or the static penalty amount
    bool public useCalculatedPenalty;

    /**
     * @notice Require that the sender is the sweepers Treasury.
     */
    modifier onlySweepersTreasury() {
        require(msg.sender == sweepersTreasury);
        _;
    }

    /**
     * @notice Require that the sender is the minter.
     */
    modifier onlyMinter() {
        require(msg.sender == minter);
        _;
    }

    /**
     * @notice Require that the sender is a remover.
     */
    modifier onlyRemover() {
        require(remover[msg.sender]);
        _;
    }

    function initialize(
        address _sweepersTreasury,
        address _minter,
        address _descriptor,
        address _seeder,
        address _proxyRegistry,
        address _sweepersV1,
        uint256 __currentSweeperId,
        address _dust
    ) external initializer {
        __ERC721_init("Sweepers", "SWEEPER");
        __Ownable_init();
        __ReentrancyGuard_init();
        sweepersTreasury = _sweepersTreasury;
        minter = _minter;
        descriptor = ISweepersDescriptor(_descriptor);
        seeder = ISweepersSeeder(_seeder);
        proxyRegistry = IProxyRegistry(_proxyRegistry);
        sweepersV1 = ISweepersTokenV1(_sweepersV1);
        _currentSweeperId = __currentSweeperId;
        _contractURIHash = 'QmeaKx7er3tEgmc4vfCAu9Jus9yVWV8KMydpmbupSKSuJ1';

        dailyDust = 10*10**18;
        DUST = IDust(_dust);
        penaltyAdjuster = 110;
        useCalculatedPenalty = true;
    }

    /**
     * @notice The IPFS URI of contract-level metadata.
     */
    function contractURI() public view override returns (string memory) {
        return string(abi.encodePacked('ipfs://', _contractURIHash));
    }

    /**
     * @notice Set the _contractURIHash.
     * @dev Only callable by the owner.
     */
    function setContractURIHash(string memory newContractURIHash) external override onlyOwner {
        _contractURIHash = newContractURIHash;
    }

    /**
     * @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) public view override(ERC721Upgradeable, IERC721Upgradeable) returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistry.proxies(owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @notice Check if a Sweeper exists.
     */
    function exists(uint256 tokenId) external view override returns (bool) {
        return _exists(tokenId);
    } 

    /**
     * @notice Mint a Sweeper to the minter.
     * @dev Call _mintTo with the to address(es).
     */
    function mint() public override onlyMinter returns (uint256) {
        return _mintTo(minter, _currentSweeperId++);
    }

    /**
     * @notice Burn a sweeper.
     */
    function burn(uint256 sweeperId) public override onlyMinter {
        _burn(sweeperId);
        emit SweeperBurned(sweeperId);
    }

    /**
     * @notice Dev manually migrate a single sweeper.
     * @dev Does not burn V1 Sweeper.
     */
    function migrate(uint256 sweeperId) external override onlyOwner {
        _mintExistingTo(sweepersV1.ownerOf(sweeperId), sweeperId);
    }

    /**
     * @notice Dev manually migrate a batch of sweepers.
     * @dev Does not burn V1 Sweepers.
     */
    function migrateMany(uint256[] calldata sweeperIds) external onlyOwner {
        for(uint i = 0; i < sweeperIds.length;) {
            _mintExistingTo(sweepersV1.ownerOf(sweeperIds[i]), sweeperIds[i]);
            unchecked{i++;}
        }
    }

    /**
     * @notice Get the Sweepers Tokens that are migratable by owner address.
     */
    function getMigratable(address owner) external view override returns (uint256[] memory migratable) {
        uint256 length = sweepersV1.balanceOf(owner);
        migratable = new uint256[](length);
        uint j = 0;
        for(uint i = 0; i < length; i++) {
            uint256 sweeperId = sweepersV1.tokenOfOwnerByIndex(owner, i);
            if(!_exists(sweeperId)) {
                migratable[j] = sweeperId;
                j++;
            } else {
                continue;
            }
        }
    }

    /**
     * @notice Holder migrate their owned sweepers.
     * @dev Does not burn V1 Sweepers. Skips alreadry migrated Sweepers.
     */
    function migrateManyByOwner(uint256[] calldata sweeperIds) external override {
        uint256 length = sweeperIds.length;
        for(uint i = 0; i < length;) {
            if(!_exists(sweeperIds[i])) {
                require(sweepersV1.ownerOf(sweeperIds[i]) == msg.sender, 'Not owner of Sweeper');
                _mintExistingTo(msg.sender, sweeperIds[i]);
                unchecked{i++;}
            } else {
                unchecked{i++;}
                continue;
            }
        }
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'URI query for nonexistent token');
        return descriptor.tokenURI(tokenId, seeds[tokenId]);
    }

    /**
     * @notice Similar to `tokenURI`, but always serves a base64 encoded data URI
     * with the JSON contents directly inlined.
     */
    function dataURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'URI query for nonexistent token');
        return descriptor.dataURI(tokenId, seeds[tokenId]);
    }

    /**
     * @notice Set the sweepers Treasury.
     * @dev Only callable by the sweepers Treasury when not locked.
     */
    function setSweepersTreasury(address _sweepersTreasury) external override onlySweepersTreasury {
        sweepersTreasury = _sweepersTreasury;

        emit SweepersTreasuryUpdated(_sweepersTreasury);
    }

    /**
     * @notice Set the token minter.
     * @dev Only callable by the owner when not locked.
     */
    function setMinter(address _minter) external override onlyOwner {
        minter = _minter;

        emit MinterUpdated(_minter);
    }

    /**
     * @notice Set the token URI descriptor.
     * @dev Only callable by the owner when not locked.
     */
    function setDescriptor(ISweepersDescriptor _descriptor) external override onlyOwner {
        descriptor = _descriptor;

        emit DescriptorUpdated(_descriptor);
    }

    /**
     * @notice Set the token seeder.
     * @dev Only callable by the owner when not locked.
     */
    function setSeeder(ISweepersSeeder _seeder) external override onlyOwner {
        seeder = _seeder;

        emit SeederUpdated(_seeder);
    }

    /**
     * @notice Mint a Sweeper with `sweeperId` to the provided `to` address.
     */
    function _mintTo(address to, uint256 sweeperId) internal returns (uint256) {
        ISweepersSeeder.Seed memory seed = seeds[sweeperId] = seeder.generateSeed(sweeperId, descriptor);

        _mint(owner(), to, sweeperId);
        emit SweeperCreated(sweeperId, seed);

        return sweeperId;
    }

    /**
     * @notice Mint a Sweeper with `sweeperId` to the provided `to` address.
     */
    function _mintExistingTo(address to, uint256 sweeperId) internal {
        (uint48 _background,
        uint48 _body,
        uint48 _accessory,
        uint48 _head,
        uint48 _eyes,
        uint48 _mouth ) = sweepersV1.seeds(sweeperId);
        ISweepersSeeder.Seed memory seed = seeds[sweeperId] = ISweepersSeeder.Seed({
            background: _background,
            body: _body,
            accessory: _accessory,
            head: _head,
            eyes: _eyes,
            mouth: _mouth
        });

        _mint(owner(), to, sweeperId);
        emit SweeperMigrated(sweeperId, seed);
    }

    /**
     * @notice Allows this contract to receive V1 Sweepers in order to Burn them.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    //******* Garage Functions

    /**
     * @notice Set the daily DUST earned per Sweeper staked in the garage.
     * @dev Only callable by the owner.
     */
    function setDailyDust(uint256 _dailyDust) external override onlyOwner {
        dailyDust = _dailyDust;
    }

    /**
     * @notice Set the DUST contract address.
     * @dev Only callable by the owner.
     */
    function setDustContract(address _dust) external override onlyOwner {
        DUST = IDust(_dust);
    }

    /**
     * @notice Set the Remover address to allow automation of unstaking Sweepers listed on marketplaces.
     * @dev Only callable by the owner.
     */
    function setRemover(address _remover, bool _flag) external override onlyOwner {
        remover[_remover] = _flag;
    }

    /**
     * @notice Set the multipliers based on Sweeper backgrounds.
     * @dev Only callable by the owner.
     */
    function setMultipliers(uint8[] memory _index, uint16[] memory _mult) external override onlyOwner {
        for(uint i = 0; i < _index.length; i++) {
            require(multiplier[_index[i]] == 0, 'Multiplier already set');
            multiplier[_index[i]] = _mult[i];
        }
    }

    /**
     * @notice Set the timestamp that staking rewards will end.
     * @dev Only callable by the owner.
     */
    function setRewardEnd(uint80 _endTime) external override onlyOwner {
        rewardEnd = _endTime;
        emit RewardEndSet(_endTime, block.timestamp);
    }

    /**
     * @notice Set the penalty parameters for being removed from the garage when listing a staked Sweeper.
     * @dev Only callable by the owner.
     */
    function setPenalty(uint256 _penalty, uint8 _adjuster, address payable _receiver, bool _useCalc) external override onlyOwner {
        penalty = _penalty;
        penaltyAdjuster = _adjuster;
        PenaltyReceiver = _receiver;
        useCalculatedPenalty = _useCalc;
        emit PenaltyAmountSet(_penalty, _receiver, block.timestamp);
    }

    /**
     * @notice Set the number of times allowed to be removed before being blocked from the garage.
     * @dev Only callable by the owner.
     */
    function setAllowedTimesRemoved(uint16 _limit) external override onlyOwner {
        allowedTimesRemoved = _limit;
    }

    /**
     * @notice Manually unblock an address from the garage.
     * @dev Only callable by the owner.
     */
    function unblockGarageAccess(address account) external override onlyOwner {
        blockedFromGarage[account] = false;
    }

    /**
     * @notice Correct a penalty amount in case of miscalculation removeStake().
     * @dev Only callable by the owner. Can only decrease penalty amount.
     */
    function penaltyCorrection(address account, uint256 _newPenalty) external override onlyOwner {
        require(_newPenalty < penaltyEarnings[account].penaltyOwed);
        penaltyEarnings[account].penaltyOwed = _newPenalty;
    }

    /**
     * @notice Stake and lock Sweepers in the garage.
     * @dev Also claims all DUST earned prior to updating StakedNFTInfo state.
     */
    function stakeAndLock(uint16[] calldata _ids) external override nonReentrant {
        require(!blockedFromGarage[msg.sender], "Please claim penalty reward");
        _claimDust(msg.sender); 

        uint16 length = uint16(_ids.length);
        uint256 _multiplier;
        uint256 m;
        for (uint16 i = 0; i < length; i++) {
            require(!isStakedAndLocked[_ids[i]], "Already Staked");
            require(msg.sender == ownerOf(_ids[i]), "Not owner");
            m = multiplier[uint8(seeds[_ids[i]].background)];
            require(m > 0, "Contact Dev");
            isStakedAndLocked[_ids[i]] = true;
            _multiplier += m;
            
            emit SweeperStakedAndLocked(_ids[i], block.timestamp);
        }
        StakedNFTInfo[msg.sender].earningsMultiplier += _multiplier;
        userStakedSweepers[msg.sender] += length;
        sweepersInGarage += length;
        emit SweepersStaked(msg.sender, _ids);
    }

    /**
     * @notice Claim all earned DUST.
     * @dev Call _claimDust with the caller's address.
     */
    function claimDust() external override nonReentrant {
        _claimDust(msg.sender);
    }

    /**
     * @notice Claim all earned DUST.
     * @dev Called by all holder garage functions.
     */
    function _claimDust(address account) internal {
        uint256 owed;
        if(rewardEnd > 0 && block.timestamp > rewardEnd) {
            owed = ((((rewardEnd - StakedNFTInfo[account].lastClaimTimestamp) * dailyDust) / 86400) * StakedNFTInfo[account].earningsMultiplier) / 10000;
            StakedNFTInfo[account].lastClaimTimestamp = rewardEnd;
        } else {
            owed = ((((block.timestamp - StakedNFTInfo[account].lastClaimTimestamp) * dailyDust) / 86400) * StakedNFTInfo[account].earningsMultiplier) / 10000;
            StakedNFTInfo[account].lastClaimTimestamp = uint80(block.timestamp);
        }
        if(owed > 0) {
            DUST.mint(msg.sender, owed);
            emit DustClaimed(msg.sender, owed);
        }
    }

    /**
     * @notice Get all Sweepers and garage status for a given account.
     * @dev Returns total DUST owed and arrays of owned Sweepers, DUST earned per Sweeper, Multipliers, and is staked bool.
     */
    function getUnclaimedDust(address account) external view override returns (uint256 owed, uint256[] memory ownedSweepers, uint256[] memory dustPerNFTList, uint256[] memory multipliers, bool[] memory isStaked) {
        uint256 length = balanceOf(account);
        ownedSweepers = new uint256[](length); 
        multipliers = new uint256[](length); 
        dustPerNFTList = new uint256[](length); 
        isStaked = new bool[](length);            
        
        uint256 _multiplier;
        uint256 _owed;
        if(rewardEnd > 0 && block.timestamp > rewardEnd) {
            _owed = (((rewardEnd - StakedNFTInfo[account].lastClaimTimestamp) * dailyDust) / 86400);
        } else {
            _owed = (((block.timestamp - StakedNFTInfo[account].lastClaimTimestamp) * dailyDust) / 86400);
        }
        for (uint i = 0; i < length; i++) {
            uint256 _id = tokenOfOwnerByIndex(account, i);
            _multiplier = multiplier[uint8(seeds[_id].background)];
            if(isStakedAndLocked[_id]) {
                dustPerNFTList[i] = (_owed * _multiplier) / 10000; 
                isStaked[i] = true;
            }
            multipliers[i] = _multiplier;
            ownedSweepers[i] = _id;
        }
        owed = (_owed * StakedNFTInfo[account].earningsMultiplier) / 10000;
        return (owed, ownedSweepers, dustPerNFTList, multipliers, isStaked);
    }

    /**
     * @notice Returns whether a single Sweeper is Staked.
     */
    function isNFTStaked(uint16 _id) public view override returns (bool) {
        if(isStakedAndLocked[_id]) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Returns whether a batch of Sweepers are Staked.
     */
    function isNFTStakedBatch(uint16[] calldata _ids) external view override returns (bool[] memory isStaked) {
        uint length = _ids.length;
        isStaked = new bool[](length);
        for(uint i = 0; i < length; i++) {
            isStaked[i] = isNFTStaked(_ids[i]);
        }
    }

    /**
     * @notice Unstake Sweepers from garage.
     * @dev Also claims all DUST earned prior to updating StakedNFTInfo state.
     */
    function unstake(uint16[] calldata _ids) external override nonReentrant {
        _claimDust(msg.sender);
        uint16 length = uint16(_ids.length);
        uint256 _multiplier;
        for (uint16 i = 0; i < length; i++) {
            require(isStakedAndLocked[_ids[i]], 
            "Not staked");
            require(msg.sender == ownerOf(_ids[i]), "Not owner");

            isStakedAndLocked[_ids[i]] = false;
            _multiplier += multiplier[uint8(seeds[_ids[i]].background)];
            
            emit SweeperStakedAndLocked(_ids[i], block.timestamp);
        }

        StakedNFTInfo[msg.sender].earningsMultiplier -= _multiplier;
        sweepersInGarage -= length;
        userStakedSweepers[msg.sender] -= length;
        if(userStakedSweepers[msg.sender] == 0) {
            delete StakedNFTInfo[msg.sender];
        }
        emit SweepersUnstaked(msg.sender, _ids);
    }

    /**
     * @notice Unstakes a Sweeper if it get's listed on an NFT Marketplace.
     * @dev Only callable by remover. Owner of Sweeper is levied a penalty that reimburses the cost of unstaking them.
     */
    function removeStake(uint16 _id) external override onlyRemover {
        uint256 gasForTX = gasleft();
        require(isStakedAndLocked[_id]);
        address sweepOwner = ownerOf(_id);
        if(rewardEnd > 0 && block.timestamp > rewardEnd) {
            penaltyEarnings[sweepOwner].earnings += ((((rewardEnd - StakedNFTInfo[sweepOwner].lastClaimTimestamp) * dailyDust) / 86400) * StakedNFTInfo[sweepOwner].earningsMultiplier) / 10000;
            StakedNFTInfo[sweepOwner].lastClaimTimestamp = rewardEnd;
        } else {
            penaltyEarnings[sweepOwner].earnings += ((((block.timestamp - StakedNFTInfo[sweepOwner].lastClaimTimestamp) * dailyDust) / 86400) * StakedNFTInfo[sweepOwner].earningsMultiplier) / 10000;
            StakedNFTInfo[sweepOwner].lastClaimTimestamp = uint80(block.timestamp);
        }
        penaltyEarnings[sweepOwner].numUnstakedSweepers++;
        isStakedAndLocked[_id] = false;
        timesRemoved[sweepOwner]++;
        if(penaltyEarnings[sweepOwner].numUnstakedSweepers > allowedTimesRemoved) {
            blockedFromGarage[sweepOwner] = true;
        }

        uint16[] memory _ids = new uint16[](1); 
        _ids[0] = _id;

        StakedNFTInfo[sweepOwner].earningsMultiplier -= multiplier[uint8(seeds[_id].background)];

        sweepersInGarage--;
        userStakedSweepers[sweepOwner]--;

        emit SweepersUnstaked(sweepOwner, _ids);
        emit SweeperRemoved(sweepOwner, _id, block.timestamp);

        penaltyEarnings[sweepOwner].penaltyOwed += ((gasForTX - gasleft()) * tx.gasprice * penaltyAdjuster) / 100 ;
    }

    /**
     * @notice Claim earnings from being removed from garage.
     * @dev Must pay penalty amount equal to cost of removeStake(). Also unblocks holder from garage.
     */
    function claimWithPenalty() external payable override {
        if(useCalculatedPenalty) {
            require(msg.value == penaltyEarnings[msg.sender].penaltyOwed, "Value must equal penalty");
        } else {
            require(msg.value == penaltyEarnings[msg.sender].numUnstakedSweepers * penalty, "Value must equal penalty");
        }
        uint256 owed = penaltyEarnings[msg.sender].earnings;
        DUST.mint(msg.sender, owed);
        (bool sent,) = PenaltyReceiver.call{value: msg.value}("");
        require(sent);
        blockedFromGarage[msg.sender] = false;
        delete penaltyEarnings[msg.sender];
        emit DustClaimed(msg.sender, owed);
    }
}