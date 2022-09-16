// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import {IBrawlerBearz} from "./interfaces/IBrawlerBearz.sol";
import {IBrawlerBearzStake} from "./interfaces/IBrawlerBearzStake.sol";
import {IBrawlerBearzDynamicItems} from "./interfaces/IBrawlerBearzDynamicItems.sol";
import "./tunnel/FxBaseRootTunnel.sol";

/*******************************************************************************
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|,|@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@|,*|&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%,**%@@@@@@@@%|******%&@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##*****|||**,(%%%%%**|%@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@***,#%%%%**#&@@@@@#**,|@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@*,(@@@@@@@@@@**,(&@@@@#**%@@@@@@||(%@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%|,****&@((@&***&@@@@@@%||||||||#%&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@&%#*****||||||**#%&@%%||||||||#@&%#(@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@&**,(&@@@@@%|||||*##&&&&##|||||(%@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@**,%@@@@@@@(|*|#%@@@@@@@@#||#%%@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@#||||#@@@@||*|%@@@@@@@@&|||%%&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@#,,,,,,*|**||%|||||||###&@@@@@@@#|||#%@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@&#||*|||||%%%@%%%#|||%@@@@@@@@&(|(%&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@&&%%(||||@@@@@@&|||||(%&((||(#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%%(||||||||||#%#(|||||%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@&%#######%%@@**||(#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%##%%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
********************************************************************************/

/**************************************************
 * @title BrawlerBearzStake
 * @author @ScottMitchell18
 **************************************************/

contract BrawlerBearzStake is
    FxBaseRootTunnel,
    AccessControl,
    IBrawlerBearzStake
{
    /// @dev Sync actions
    bytes32 public constant STAKE = keccak256("STAKE");
    bytes32 public constant UNSTAKE = keccak256("UNSTAKE");
    bytes32 public constant XP_SYNC = keccak256("XP_SYNC");
    bytes32 public constant REWARDS_CLAIM = keccak256("REWARDS_CLAIM");

    /// @dev Roles
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    /// @notice Contract of the brawler bearz nft
    IBrawlerBearz public nftContract;

    /// @notice Vendor contract
    IBrawlerBearzDynamicItems public vendorContract;

    /// @notice boolean of whether staking is live or not
    bool public stakingPaused;

    /// @notice map from id to its staked state
    mapping(uint256 => Stake) public staked;

    constructor(
        address _checkpointManager,
        address _fxRoot,
        address _tokenAddress,
        address _vendorContractAddress
    ) FxBaseRootTunnel(_checkpointManager, _fxRoot) {
        // Setup access control
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OWNER_ROLE, _msgSender());
        // Setup interaction contracts
        nftContract = IBrawlerBearz(_tokenAddress);
        vendorContract = IBrawlerBearzDynamicItems(_vendorContractAddress);
    }

    /**
     * @notice Stake tokenids
     * @param tokenIds to stake
     */
    function stake(uint256[] calldata tokenIds) external override {
        require(!stakingPaused, "Staking paused");
        require(tokenIds.length > 0, "Staking requires at least 1 token");
        uint256 tokenId;
        for (uint256 i = 0; i < tokenIds.length; ) {
            tokenId = tokenIds[i];
            // No need to check ownership since transferFrom already checks that
            // and the caller of this function should be the token Owner
            staked[tokenId] = Stake(_msgSender(), uint96(block.timestamp));
            // Lock token
            nftContract.lockId(tokenId);
            unchecked {
                ++i;
            }
        }
        // Send to L2
        _sendMessageToChild(
            abi.encode(STAKE, abi.encode(_msgSender(), tokenIds))
        );
    }

    /**
     * @notice Unstake tokenids
     * @param tokenIds to unstake
     */
    function unstake(uint256[] calldata tokenIds) external override {
        require(tokenIds.length > 0, "Unstaking requires at least 1 token");
        uint256 tokenId;
        Stake memory stakeInfo;
        for (uint256 i = 0; i < tokenIds.length; ) {
            tokenId = tokenIds[i];
            stakeInfo = staked[tokenId];
            if (stakeInfo.owner != _msgSender()) revert InvalidOwner();
            staked[tokenId] = Stake(address(0), 1);
            // Unlock token
            nftContract.unlockId(tokenId);
            unchecked {
                ++i;
            }
        }
        // Send to L2
        _sendMessageToChild(
            abi.encode(STAKE, abi.encode(_msgSender(), tokenIds))
        );
    }

    /**
     * @dev Set active state of staking protocol
     * @param paused - the state's new value.
     */
    function setStakingPaused(bool paused) external onlyRole(OWNER_ROLE) {
        stakingPaused = paused;
    }

    /**
     * Set FxChildTunnel
     * @param _fxChildTunnel - the fxChildTunnel address
     */
    function setFxChildTunnel(address _fxChildTunnel)
        public
        override
        onlyRole(OWNER_ROLE)
    {
        fxChildTunnel = _fxChildTunnel;
    }

    /**
     * @dev Sets brawler bearz compatible nft contract
     * @param _nftContract address of contract
     */
    function setNFTContract(address _nftContract)
        external
        onlyRole(OWNER_ROLE)
    {
        nftContract = IBrawlerBearz(_nftContract);
    }

    /**
     * @notice Sets the bearz vendor item contract
     * @dev only owner call this function
     * @param _vendorContractAddress The new contract address
     */
    function setVendorContractAddress(address _vendorContractAddress)
        external
        onlyRole(OWNER_ROLE)
    {
        vendorContract = IBrawlerBearzDynamicItems(_vendorContractAddress);
    }

    /**
     * @dev Add XP by batch
     * @param tokenIds of the nfts
     * @param amounts of XPs
     */
    function addXPBatch(uint256[] memory tokenIds, uint256[] memory amounts)
        internal
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (amounts[i] > 0) {
                nftContract.addXP(tokenIds[i], amounts[i]);
            }
        }
    }

    /**
     * @dev Remove XP by batch
     * @param tokenIds of the nfts
     * @param amounts of XPs
     */
    function subtractXPBatch(
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) internal {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (amounts[i] > 0) {
                nftContract.subtractXP(tokenIds[i], amounts[i]);
            }
        }
    }

    /**
     * @dev Add XP emergency - OWNER ONLY
     * @param tokenId of the nft
     * @param amount of XP
     */
    function addXP(uint256 tokenId, uint256 amount)
        external
        onlyRole(OWNER_ROLE)
    {
        nftContract.addXP(tokenId, amount);
    }

    /**
     * @dev Subtract XP emergency - OWNER ONLY
     * @param tokenId of the nft
     * @param amount of XP
     */
    function subtractXP(uint256 tokenId, uint256 amount)
        external
        onlyRole(OWNER_ROLE)
    {
        nftContract.subtractXP(tokenId, amount);
    }

    function _processSyncXP(bytes memory data) internal {
        (uint256[] memory tokenIds, uint256[] memory amounts, bool isAdd) = abi
            .decode(data, (uint256[], uint256[], bool));
        if (isAdd) {
            addXPBatch(tokenIds, amounts);
        } else {
            subtractXPBatch(tokenIds, amounts);
        }
    }

    function _processRewardsClaim(bytes memory data) internal {
        (address to, uint256[] memory itemIds) = abi.decode(
            data,
            (address, uint256[])
        );
        vendorContract.dropItems(to, itemIds);
    }

    /// @dev TEST
    function _processMessageFromChildTest(bytes memory message)
        external
        onlyRole(OWNER_ROLE)
    {
        (bytes32 syncType, bytes memory syncData) = abi.decode(
            message,
            (bytes32, bytes)
        );
        if (syncType == XP_SYNC) {
            _processSyncXP(syncData);
        } else if (syncType == REWARDS_CLAIM) {
            _processRewardsClaim(syncData);
        } else {
            revert("INVALID_SYNC_TYPE");
        }
    }

    function _processMessageFromChild(bytes memory message) internal override {
        (bytes32 syncType, bytes memory syncData) = abi.decode(
            message,
            (bytes32, bytes)
        );
        if (syncType == XP_SYNC) {
            _processSyncXP(syncData);
        } else if (syncType == REWARDS_CLAIM) {
            _processRewardsClaim(syncData);
        } else {
            revert("INVALID_SYNC_TYPE");
        }
    }
}