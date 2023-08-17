// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IOCB} from "./interfaces/IOCB.sol";
import {IOCBStaking} from "./interfaces/IOCBStaking.sol";

/// @notice Staking contract for OCB
contract OCBStaking is IOCBStaking, Initializable, PausableUpgradeable, OwnableUpgradeable {

    IOCB private ocbContract;

    mapping(uint256 => Position) public stakingPositions;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // @dev Initializer as we using an upgradable contract
    function initialize(address ocbContractAddress) public initializer {
        ocbContract = IOCB(ocbContractAddress);

        // inits
        __Ownable_init();
        __Pausable_init();
    }


    // -- STAKING --

    // @dev Stake one token
    function stake(uint256 tokenId) external whenNotPaused {

        _stake(msg.sender, tokenId);

    }

    // @dev Stake one or more tokens
    function batchStake(uint256[] calldata tokenIds) external whenNotPaused {

        uint256 tokenLen = tokenIds.length;

        for(uint256 i; i < tokenLen; i++) {
            _stake(msg.sender, tokenIds[i]);
        }
    }

    // @dev Unstake one token
    function unstake(uint256 tokenId) external whenNotPaused {

        _unstake(msg.sender, tokenId);

    }

    // @dev Unstake one or more tokens
    function batchUnstake(uint256[] calldata tokenIds) external whenNotPaused {

        uint256 tokenLen = tokenIds.length;

        for(uint256 i; i < tokenLen; i++) {
            _unstake(msg.sender, tokenIds[i]);
        }
    }


    // -- VIEWS --

    // @dev Check if given token is staked
    function isTokenStaked(uint256 tokenId) external view returns(bool) {
        Position memory stakingPosition = stakingPositions[tokenId];
        return stakingPosition.startTime > 0;
    }

    // @dev Get staking start timestamp of given token
    function getTokenStakingStart(uint256 tokenId) external view returns(uint256) {
        Position memory stakingPosition = stakingPositions[tokenId];
        return stakingPosition.startTime;
    }

    // @dev Get staking time (in seconds) of given token
    function getTokenStakingTime(uint256 tokenId) external view returns(uint256) {
        Position memory stakingPosition = stakingPositions[tokenId];
        return (stakingPosition.startTime > 0 ? (block.timestamp - stakingPosition.startTime) : 0);
    }

    // @dev Get all staked tokenIds of given owner
    function getOwnerStakedTokenIds(address owner) public view returns(uint256[] memory) {

        unchecked {

            uint256[] memory stakedTokenIds = new uint256[](888);
            uint256 stakedTokenBalance;
            uint256 arrCounter;
            uint256 stakedIndex;

            for(uint256 tokenId = 0; tokenId < 888; tokenId++) {
                Position memory stakingPosition = stakingPositions[tokenId];

                if( stakingPosition.owner == owner ) {
                    stakedTokenBalance++;
                    stakedTokenIds[arrCounter++] = tokenId;
                }
            }

            if( stakedTokenBalance > 0 ) {
                arrCounter = 0;

                uint256[] memory trimmedStakedTokenIds = new uint256[](stakedTokenBalance);

                do {
                    trimmedStakedTokenIds[arrCounter++] = stakedTokenIds[stakedIndex++];
                } while( stakedTokenIds[stakedIndex] > 0 );

                return trimmedStakedTokenIds;

            } else {

                uint256[] memory trimmedStakedTokenIds;
                return trimmedStakedTokenIds;
            }

        }

    }

    // @dev Get all staked positions of given owner
    function getOwnerStakedTokenPositions(address owner) public view returns(ReadablePosition[] memory) {

        unchecked {

            uint256[] memory stakedTokenIds = getOwnerStakedTokenIds(owner);
            ReadablePosition[] memory stakedTokenPositions = new ReadablePosition[](stakedTokenIds.length);

            for(uint256 i = 0; i < stakedTokenIds.length; i++) {
                stakedTokenPositions[i] = _convertToReadablePosition(stakedTokenIds[i], stakingPositions[stakedTokenIds[i]]);
            }

            return stakedTokenPositions;

        }

    }

    // @dev Get all staked balance of given owner
    function balanceOf(address owner) public view returns(uint256) {

        unchecked {
            uint256[] memory stakedTokenIds = getOwnerStakedTokenIds(owner);
            return stakedTokenIds.length;
        }

    }

    // @dev Get all staked tokenIds
    function getStakedTokenIds() public view returns(uint256[] memory) {

        unchecked {

            uint256[] memory stakedTokenIds = new uint256[](888);
            uint256 stakedTokenBalance;
            uint256 arrCounter;
            uint256 stakedIndex;

            for(uint256 tokenId = 0; tokenId < 888; tokenId++) {
                Position memory stakingPosition = stakingPositions[tokenId];

                if( stakingPosition.startTime > 0 ) {
                    stakedTokenBalance++;
                    stakedTokenIds[arrCounter++] = tokenId;
                }
            }

            if( stakedTokenBalance > 0 ) {
                arrCounter = 0;

                uint256[] memory trimmedStakedTokenIds = new uint256[](stakedTokenBalance);

                do {
                    trimmedStakedTokenIds[arrCounter++] = stakedTokenIds[stakedIndex++];
                } while( stakedTokenIds[stakedIndex] > 0 );

                return trimmedStakedTokenIds;

            } else {

                uint256[] memory trimmedStakedTokenIds;
                return trimmedStakedTokenIds;
            }

        }

    }

    // @dev Get all staked positions
    function getStakedTokenPositions() public view returns(ReadablePosition[] memory) {

        unchecked {

            uint256[] memory stakedTokenIds = getStakedTokenIds();
            ReadablePosition[] memory stakedTokenPositions = new ReadablePosition[](stakedTokenIds.length);

            for(uint256 i = 0; i < stakedTokenIds.length; i++) {
                stakedTokenPositions[i] = _convertToReadablePosition(stakedTokenIds[i], stakingPositions[stakedTokenIds[i]]);
            }

            return stakedTokenPositions;

        }

    }

    // @dev Get token position by given tokenId
    function getTokenPosition(uint256 tokenId) public view returns(ReadablePosition memory) {

        unchecked {
            return _convertToReadablePosition(tokenId, stakingPositions[tokenId]);
        }

    }


    // -- INTERNAL --

    // @dev Internal stake function
    function _stake(address sender, uint256 tokenId) internal {

        Position storage stakingPosition = stakingPositions[tokenId];

        if( stakingPosition.startTime > 0 ) revert TokenAlreadyStaked(tokenId);

        stakingPosition.owner = sender;
        stakingPosition.startTime = uint40(block.timestamp);

        ocbContract.transferFrom(sender, address(this), tokenId);

        emit TokenStaked(tokenId, sender);
        emit MetadataUpdate(tokenId);
    }

    // @dev Internal unstake function
    function _unstake(address recipient, uint256 tokenId) internal {

        Position storage stakingPosition = stakingPositions[tokenId];

        if( recipient != stakingPosition.owner ) revert SenderIsNotTokenOwner(tokenId);
        if( stakingPosition.startTime <= 0 ) revert TokenIsNotStaked(tokenId);

        stakingPosition.owner = address(0);
        stakingPosition.startTime = 0;

        ocbContract.transferFrom(address(this), recipient, tokenId);

        emit TokenUnstaked(tokenId, recipient);
    }

    // @dev Internal force unstake function. Only use with caution [!]
    function _forceUnstake(uint256 tokenId) internal {

        Position storage stakingPosition = stakingPositions[tokenId];

        if( stakingPosition.startTime <= 0 ) revert TokenIsNotStaked(tokenId);

        address recipient = stakingPosition.owner;

        stakingPosition.owner = address(0);
        stakingPosition.startTime = 0;

        ocbContract.transferFrom(address(this), recipient, tokenId);

        emit TokenUnstaked(tokenId, recipient);
    }

    // @dev Converts a stakingPosition to a readable staking position
    function _convertToReadablePosition(uint256 tokenId, Position memory stakingPosition) internal view returns (ReadablePosition memory) {

        ReadablePosition memory readableStakingPosition;

        readableStakingPosition.tokenId = tokenId;
        readableStakingPosition.owner = stakingPosition.owner;
        readableStakingPosition.startTime = stakingPosition.startTime;
        readableStakingPosition.isTokenStaked = stakingPosition.startTime > 0;
        readableStakingPosition.tokenStakingTime = (stakingPosition.startTime > 0 ? uint40((block.timestamp - stakingPosition.startTime)) : 0);

        return readableStakingPosition;
    }


    // -- ADMIN --

    // @dev Force unstake one or more tokens (skips contract pause)
    function forceBatchUnstake(uint256[] calldata tokenIds) external onlyOwner {

        uint256 tokenLen = tokenIds.length;

        for(uint256 i; i < tokenLen; i++) {
            _forceUnstake(tokenIds[i]);
        }
    }

    // @dev Set the OCB contract address
    function setOCBContract(address ocbContractAddress) external onlyOwner {
        ocbContract = IOCB(ocbContractAddress);

        emit ocbContractChanged(ocbContractAddress);
    }

    // @dev Pause staking
    function pauseStaking() external onlyOwner {
        _pause();
    }

    // @dev Unpause staking
    function unpauseStaking() external onlyOwner {
        _unpause();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;

}