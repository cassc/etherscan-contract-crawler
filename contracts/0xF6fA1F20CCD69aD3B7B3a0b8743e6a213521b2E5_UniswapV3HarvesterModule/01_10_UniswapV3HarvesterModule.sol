// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "AutomationCompatible.sol";
import "Pausable.sol";

import "INonfungiblePositionManager.sol";

import {BaseModule} from "BaseModule.sol";
import {UniswapV3HarvesterModuleConstants} from "UniswapV3HarvesterModuleConstants.sol";

/// @title UniswapV3HarvesterModule
/// @notice Allows the module the processing of fees accumulated in each NFT position owned by the
///         safe (vault_msig) under a specific cadence.
contract UniswapV3HarvesterModule is BaseModule, AutomationCompatible, Pausable, UniswapV3HarvesterModuleConstants {
    ////////////////////////////////////////////////////////////////////////////
    // STORAGE
    ////////////////////////////////////////////////////////////////////////////
    address public guardian;

    uint256 public lastProcessingTimestamp;
    uint256 public processingInterval;

    ////////////////////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////////////////////

    error NotGovernance(address caller);
    error NotGovernanceOrGuardian(address caller);
    error NotKeeper(address caller);

    error TooSoon(uint256 lastProcessing, uint256 timestamp);

    error NoFeesCollected(uint256 tokenId);
    error NotOwnedNft(uint256 tokenId);

    error ZeroIntervalPeriod();
    error ZeroAddress();
    error ModuleMisconfigured();

    ////////////////////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////////////////////

    event ProcessingIntervalUpdated(uint256 oldProcessingInterval, uint256 newProcessingInterval, uint256 timestamp);
    event GuardianUpdated(address indexed oldGuardian, address indexed newGuardian, uint256 timestamp);

    ////////////////////////////////////////////////////////////////////////////
    // MODIFIERS
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Checks whether a call is from governance
    modifier onlyGovernance() {
        if (msg.sender != GOVERNANCE) revert NotGovernance(msg.sender);
        _;
    }

    /// @notice Checks whether a call is from governance or guardian
    modifier onlyGovernanceOrGuardian() {
        if (msg.sender != GOVERNANCE && msg.sender != guardian) revert NotGovernanceOrGuardian(msg.sender);
        _;
    }

    /// @notice Checks whether a call is from the keeper.
    modifier onlyKeeper() {
        if (msg.sender != CHAINLINK_KEEPER_REGISTRY) revert NotKeeper(msg.sender);
        _;
    }

    /// @param _processingInterval Frequency in seconds at which `feeToken` will be processed
    /// @param _guardian Address allowed to pause contract
    constructor(uint256 _processingInterval, address _guardian) {
        if (_processingInterval == 0) revert ZeroIntervalPeriod();
        if (_guardian == address(0)) revert ZeroAddress();
        processingInterval = _processingInterval;
        guardian = _guardian;
    }

    ////////////////////////////////////////////////////////////////////////////
    // PUBLIC: Governance
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Updates the duration for the processing of the UniV3 fees. Can only be called by owner.
    /// @param _processingInterval The new frequency period in seconds for processing `feeToken` in storage.
    function setProcessingInterval(uint256 _processingInterval) external onlyGovernance {
        if (_processingInterval == 0) revert ZeroIntervalPeriod();

        uint256 oldProcessingInterval = processingInterval;

        processingInterval = _processingInterval;
        emit ProcessingIntervalUpdated(oldProcessingInterval, _processingInterval, block.timestamp);
    }

    /// @notice  Updates the guardian address. Only callable by governance.
    /// @param _guardian Address which will become guardian
    function setGuardian(address _guardian) external onlyGovernance {
        if (_guardian == address(0)) revert ZeroAddress();
        address oldGuardian = guardian;
        guardian = _guardian;
        emit GuardianUpdated(oldGuardian, _guardian, block.timestamp);
    }

    /// @dev Pauses the contract, which prevents executing performUpkeep.
    function pause() external onlyGovernanceOrGuardian {
        _pause();
    }

    /// @dev Unpauses the contract.
    function unpause() external onlyGovernance {
        _unpause();
    }

    ////////////////////////////////////////////////////////////////////////////
    // PUBLIC: Keeper
    ////////////////////////////////////////////////////////////////////////////

    /// @dev Contains the logic that should be executed on-chain when
    ///      `checkUpkeep` returns true.
    function performUpkeep(bytes calldata performData) external override whenNotPaused onlyKeeper {
        /// @dev safety check, ensuring onchain module is config
        if (!SAFE.isModuleEnabled(address(this))) revert ModuleMisconfigured();

        if ((block.timestamp - lastProcessingTimestamp) < processingInterval) {
            revert TooSoon(lastProcessingTimestamp, block.timestamp);
        }

        uint256[] memory nftIds = abi.decode(performData, (uint256[]));
        uint256 idsLength = nftIds.length;
        if (idsLength > 0) {
            for (uint256 i; i < idsLength;) {
                (uint256 amount0, uint256 amount1) = _collect(nftIds[i]);
                /// @dev protection for empty fees TokenIds pass by keeper
                if (amount0 == 0 && amount1 == 0) revert NoFeesCollected(nftIds[i]);
                unchecked {
                    ++i;
                }
            }
            lastProcessingTimestamp = block.timestamp;
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    // PUBLIC VIEW
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Checks whether an upkeep is to be performed.
    /// @return upkeepNeeded_ A boolean indicating whether an upkeep is to be performed.
    /// @return performData_ The calldata to be passed to the upkeep function.
    function checkUpkeep(bytes calldata)
        external
        override
        cannotExecute
        returns (bool upkeepNeeded_, bytes memory performData_)
    {
        if (!SAFE.isModuleEnabled(address(this)) && (block.timestamp - lastProcessingTimestamp) < processingInterval) {
            // NOTE: explicit early return to checking rest of logic if these conditions are not met
            return (upkeepNeeded_, performData_);
        }

        uint256[] memory nftIndexes = _getNftsIndexOwned();
        uint256 length = nftIndexes.length;

        // NOTE: helpers to store which nft ids have indeed fees accumulated
        uint256[] memory nftsWithFees = new uint256[](length);
        uint256 nftsWithFeesLength;

        for (uint256 i; i < length;) {
            (uint256 amount0, uint256 amount1) = _collect(nftIndexes[i]);
            if (amount0 > 0 || amount1 > 0) {
                nftsWithFees[nftsWithFeesLength] = nftIndexes[i];
                unchecked {
                    ++nftsWithFeesLength;
                }
            }
            unchecked {
                ++i;
            }
        }

        if (nftsWithFeesLength != length) {
            // NOTE: truncate length
            assembly {
                mstore(nftsWithFees, nftsWithFeesLength)
            }
        }

        if (nftsWithFeesLength > 0) {
            upkeepNeeded_ = true;
            performData_ = abi.encode(nftsWithFees);
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    // INTERNAL
    ////////////////////////////////////////////////////////////////////////////

    /// @return TokenIds owned by governance
    function _getNftsIndexOwned() internal view returns (uint256[] memory) {
        uint256 totalNftOwned = UNIV3_POSITION_MANAGER.balanceOf(GOVERNANCE);
        uint256[] memory tokenIds = new uint256[](totalNftOwned);
        for (uint256 i; i < totalNftOwned;) {
            tokenIds[i] = UNIV3_POSITION_MANAGER.tokenOfOwnerByIndex(GOVERNANCE, i);
            unchecked {
                ++i;
            }
        }
        return tokenIds;
    }

    /// @param tokenId TokenId to claim fees from
    /// @return amount0 Token fees accumulated of token0
    /// @return amount1 Token fees accumulated of token1
    function _collect(uint256 tokenId) internal returns (uint256 amount0, uint256 amount1) {
        if (UNIV3_POSITION_MANAGER.ownerOf(tokenId) != GOVERNANCE) revert NotOwnedNft(tokenId);

        INonfungiblePositionManager.CollectParams memory params =
            INonfungiblePositionManager.CollectParams(tokenId, GOVERNANCE, UINT128_MAX, UINT128_MAX);
        bytes memory data = _checkTransactionAndExecuteReturningData(
            SAFE, address(UNIV3_POSITION_MANAGER), abi.encodeCall(INonfungiblePositionManager.collect, params)
        );
        (amount0, amount1) = abi.decode(data, (uint256, uint256));
    }
}