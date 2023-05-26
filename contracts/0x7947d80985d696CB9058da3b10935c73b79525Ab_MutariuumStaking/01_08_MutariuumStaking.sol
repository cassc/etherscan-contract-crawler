// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import "./interfaces/IMuutariumStaking.sol";

contract MutariuumStaking is IMuutariumStaking, Ownable {

    uint256 private constant _BITMASK_NUMBER_STAKED = (1 << 64) - 1;
    uint256 private constant _BITPOS_CAN_STAKE = 1 << 64;
    uint256 private constant _BITPOS_CAN_UNSTAKE = 1 << 65;
    uint256 private constant _BITMASK_STAKING_STATUS = 3 << 64;

    /**
     * @dev Mapping from nft address to
     *      - mapping from tokenId to packed staking infos
     * packed staking info
     * Bits Layout:
     * - [0..159]     Address of the original owner of the NFT
     * - [160..255]   Timestamp of the staking
     */
    mapping(address => mapping(uint256 => uint256)) private _packedStakingInfos;

    /**
     * @dev Mapping from nft address to packed contract infos
     * Bits Layout:
     * - [0..63]    Number of NFTs currently staked
     * - [64..65]   Staking status (INACTIVE, ACTIVE, PAUSED, LOCKED)
     */
    mapping(address => uint256) private _packedContractInfos;

    /**
     * @dev Mapping from user address to nonce (aka: how many time this user
     * has used a signature provided by the contract owner)
     */
    mapping(address => uint256) private _signatureNonces;

    /** Public Views */

    /**
     * @notice get the current owner and time when the stake started of an NFT
     * @return StakingInfos
     */
    function stakingInfos(address nft, uint256 tokenId) external view returns(StakingInfos memory) {
        (address owner, uint256 stakedAt) = _unpackStakingInfos(_packedStakingInfos[nft][tokenId]);
        return StakingInfos({
            owner: owner,
            stakedAt: stakedAt
        });
    }

    /**
     * @notice Get the number of NFTs currently staked and the current staking status of an NFT collection
     * @param nft The address of the collection
     * @return CollectionInfos
     */
    function collectionInfos(address nft) external view returns(CollectionInfos memory) {
        (StakingStatus status, uint256 numberStaked) = _unpackContractInfos(_packedContractInfos[nft]);
        return CollectionInfos({
            numberStaked: numberStaked,
            status: status
        });
    }

    /** Public function calls */

    /**
     * @notice Stake a list of nfts from a specific collection
     * @param nft The address of the collection
     * @param tokenIds the list of nfts from that collection
     *
     * - The status of the collection needs to be ACTIVE
     * - The staking contract must be approved on that collection for this sender
     */
    function stake(address nft, uint256[] calldata tokenIds) external {
        require(
            _canStake(nft),
            "Staking is not active on this collection"
        );
        require(
            IERC721(nft).isApprovedForAll(msg.sender, address(this)),
            "Missing approval for this collection"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                IERC721(nft).ownerOf(tokenIds[i]) == msg.sender,
                string(abi.encodePacked(
                    "You don't own token #",
                    Strings.toString(tokenIds[i]),
                    " from the contract ",
                    Strings.toHexString(uint256(uint160(nft)), 20)
                ))
            );
            IERC721(nft).transferFrom(msg.sender, address(this), tokenIds[i]);
            _packedStakingInfos[nft][tokenIds[i]] = _packStakingInfos(msg.sender, block.timestamp);
            _packedContractInfos[nft]++;
            emit Stake(nft, msg.sender, tokenIds[i]);
        }
    }


    /**
     * @notice Set an NFT that was sent by mistake to this contract as staked
     * @param nft The address of the collection
     * @param tokenId The nft from that collection
     * @param signature The approval from the owner to claim that stake
     *
     * - The NFT needs to be owned by this contract
     * - There should be no staking record for that NFT
     */
    function recoverStake(address nft, uint256 tokenId, bytes calldata signature) external {
        require(
            IERC721(nft).ownerOf(tokenId) == address(this),
            "I'm not holding that NFT"
        );
        require(
            _packedStakingInfos[nft][tokenId] == 0,
            "That NFT is already marked as staked"
        );
        require(
            _verifySignature(nft, tokenId, signature),
            "This operation was not approved by the contract owner"
        );
        _signatureNonces[msg.sender]++;

        _packedStakingInfos[nft][tokenId] = _packStakingInfos(msg.sender, block.timestamp);
        _packedContractInfos[nft]++;
        emit Stake(nft, msg.sender, tokenId);
    }

    /**
     * @notice Unstake a list of nfts from a specific collection
     *
     * @param nft The address of the collection
     * @param tokenIds the list of nfts from that collection
     *
     * - The nft must have been been staked by the caller
     */
    function unstake(address nft, uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            (address owner, ) = _unpackStakingInfos(_packedStakingInfos[nft][tokenIds[i]]);
            require(owner == msg.sender, "You didn't stake this token");
            _packedContractInfos[nft]--;
            IERC721(nft).transferFrom(address(this), owner, tokenIds[i]);
            delete _packedStakingInfos[nft][tokenIds[i]];
            emit Unstake(nft, msg.sender, tokenIds[i]);
        }
    }

    /** Admin functions calls */

    /**
     * @notice Enable or disable staking or unstaking for a specific collection
     *
     * @param nft The address of the collection
     * @param canStake If staking should be enabled or disabled
     * @param canUnstake If ustaking should be enabled or disabled
     */
    function setStakingStatus(address nft, bool canStake, bool canUnstake) external onlyOwner {
        uint256 status = 0;
        if (canStake) {
            status = status | _BITPOS_CAN_STAKE;
        }
        if (canUnstake) {
            status = status | _BITPOS_CAN_UNSTAKE;
        }
        _packedContractInfos[nft] = _packedContractInfos[nft] & _BITMASK_NUMBER_STAKED | status;
    }

    /** Internal functions */

    function _packStakingInfos(address staker, uint256 timestamp) private pure returns(uint256) {
        return (timestamp << 160) | uint160(staker);
    }

    function _unpackStakingInfos(uint256 pack) private pure returns(address, uint256) {
        return (
            address(uint160(pack)),
            pack >> 160
        );
    }

    function _packContractInfos(StakingStatus status, uint256 numberStaked) private pure returns(uint256) {
        return (uint8(status) << 64) | numberStaked;
    }

    function _unpackContractInfos(uint256 pack) private pure returns(StakingStatus, uint256) {
        return (
            StakingStatus((pack >> 64) & 3),
            uint256(uint64(pack))
        );
    }

    function _canStake(address nft) private view returns(bool) {
        return (_packedContractInfos[nft] & _BITPOS_CAN_STAKE) > 0;
    }

    function _canUnstake(address nft) private view returns(bool) {
        return (_packedContractInfos[nft] & _BITPOS_CAN_UNSTAKE) > 0;
    }

    function _verifySignature(address nft, uint256 tokenId, bytes calldata signature) internal view returns (bool){
        bytes32 message = keccak256(abi.encodePacked(msg.sender, _signatureNonces[msg.sender], nft, tokenId));
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                message
            )
        );
        address signer = ECDSA.recover(hash, signature);
        return signer == owner();
    }
}