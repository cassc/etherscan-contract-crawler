// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IERC20 } from "../../../lib/openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IBatchAuctionSeller } from "../../interfaces/IBatchAuctionSeller.sol";

import { HashnoteVault } from "./base/HashnoteVault.sol";
import { HashnoteOptionsVaultStorage } from "../../storage/HashnoteOptionsVaultStorage.sol";

import { Vault } from "../../libraries/Vault.sol";
import { AuctionUtil } from "../../libraries/AuctionUtil.sol";
import { StructureUtil } from "../../libraries/StructureUtil.sol";
import { VaultUtil } from "../../libraries/VaultUtil.sol";
import { TokenIdUtil } from "../../../lib/grappa/src/libraries/TokenIdUtil.sol";

import "../../libraries/Errors.sol";

/**
 * UPGRADEABILITY: Since we use the upgradeable proxy pattern, we must observe the inheritance chain closely.
 * Any changes/appends in storage variable needs to happen in HashnoteOptionsVaultStorage.
 * HashnoteOptionsVault should not inherit from any other contract aside from HashnoteVault, HashnoteOptionsVaultStorage
 */
contract HashnoteOptionsVault is HashnoteVault, HashnoteOptionsVaultStorage, IBatchAuctionSeller {
    /*///////////////////////////////////////////////////////////////
                        Constants and Immutables
    //////////////////////////////////////////////////////////////*/

    // The minimum duration for an option auction.
    uint256 private constant MIN_AUCTION_DURATION = 5 minutes;

    // MARGIN_ENGINE is Grappa protocol's collateral pool.
    // https://github.com/antoncoding/grappa/blob/master/src/core/engines
    address public immutable MARGIN_ENGINE;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event StagedStructure(uint256[] options, uint256[] strikes, uint256 maxStructures, int256 premium, address indexed manager);

    event CreatedAuction(uint256 auctionId, uint256[] options, address indexed manager);

    event SettledAuction(uint256 auctionId, uint256 totalSold, int256 clearingPrice);

    event WroteOptions(uint256[] options, uint256 mintedStructures, uint256[] depositAmounts, address indexed manager);

    event SettledOptions(uint256[] options, uint256 totalStructures, uint256[] withdrawAmounts, address indexed manager);

    event AuctionSet(address auction, address newAuction);

    event AuctionDurationSet(uint256 auctionDuration, uint256 newAuctionDuration);

    event PremiumSet(int256 premium, int256 newpremium);

    /*///////////////////////////////////////////////////////////////
                    Constructor and initialization
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the contract with immutable variables
     * @param _share is the erc1155 contract that issues shares
     * @param _marginEngine is the margin engine used for Grappa (options protocol)
     */
    constructor(address _share, address _marginEngine) HashnoteVault(_share) {
        if (_marginEngine == address(0)) revert HV_BadAddress();

        MARGIN_ENGINE = _marginEngine;
    }

    /**
     * @notice Initializes the OptionsVault contract with storage variables.
     * @param _initParams is the struct with vault initialization parameters
     * @param _vaultParams is the struct with vault general data
     */
    function initialize(Vault.InitParams calldata _initParams, Vault.VaultParams calldata _vaultParams) external initializer {
        baseInitialize(_initParams, _vaultParams);

        if (_initParams._auction == address(0)) revert HV_BadAddress();
        if (
            _initParams._auctionDuration < MIN_AUCTION_DURATION
                || _initParams._auctionDuration >= _initParams._roundConfig.duration
        ) revert HV_BadDuration();
        if (_initParams._leverageRatio == 0) revert HV_BadLevRatio();

        auction = _initParams._auction;
        auctionDuration = _initParams._auctionDuration;
        leverageRatio = _initParams._leverageRatio;
    }

    /*///////////////////////////////////////////////////////////////
                                Setters
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the new batch auction address
     * @param _auction is the auction duration address
     */
    function setAuction(address _auction) external {
        _onlyOwner();

        if (_auction == address(0)) revert HV_BadAddress();

        emit AuctionSet(auction, _auction);

        auction = _auction;
    }

    /**
     * @notice Sets the new auction duration
     * @param _auctionDuration is the auction duration
     */
    function setAuctionDuration(uint256 _auctionDuration) external {
        _onlyOwner();

        // must be larger that minimum but not longer than the duration of a round
        if (_auctionDuration < MIN_AUCTION_DURATION || _auctionDuration >= roundConfig.duration) {
            revert HV_BadDuration();
        }

        emit AuctionDurationSet(auctionDuration, _auctionDuration);

        auctionDuration = _auctionDuration;
    }

    /**
     * @notice Sets structure premium
     * @dev will be used for pricing re-auctions of structures
     * @param _premium is new premium expected to receive/pay for each structure (scale of 10**18)
     */
    function setPremium(int256 _premium) external {
        _onlyManager();

        emit PremiumSet(optionState.premium, _premium);

        optionState.premium = _premium;
    }

    /*///////////////////////////////////////////////////////////////
                            Vault Operations
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Settles the existing option(s), closes round and processes withdraws
     */
    function closeRound() external nonReentrant {
        uint256[] memory prevOptions = optionState.currentOptions;

        if (prevOptions.length == 0 && vaultState.round > 1) {
            revert HV_RoundClosed();
        }

        _settleOptions(prevOptions);

        _closeRound();

        _completeWithdraw();
    }

    /**
     * @notice Sets the next options the vault writting
     * @dev performing asset requirements offchain to save gas fees
     * @param strikes new prices for each instruments
     * @param maxStructures max structures to mint
     * @param premium new premium expected to receive/pay for each structure (scale of 10**18)
     * @param vault assets earmarked to be used as collateral (scale in assets native decimals)
     * @param counterparty assets earmarked to be used as collateral (scale in assets native decimals)
     */
    function stageStructure(
        uint256[] calldata strikes,
        uint256 maxStructures,
        int256 premium,
        uint256[] calldata vault,
        uint256[] calldata counterparty
    ) external {
        _onlyManager();

        uint256 currentRound = vaultState.round;

        // setting vault collateral requirements for first round
        // accounts for ratio of collaterals if more than 1 required
        if (currentRound == 1) {
            optionState.vault = vault;
            roundStartingBalances[currentRound] = vault;
        } else {
            if (strikes.length != instruments.length) revert HV_BadNumStrikes();

            if (vault.length != collaterals.length) revert HV_BadCollaterals();

            if (optionState.mintedStructures > 0 || auctionId > 0) revert HV_ActiveRound();

            (uint256[] memory options, uint256 expiry) =
                StructureUtil.stageStructure(MARGIN_ENGINE, strikes, instruments, roundConfig);

            delete optionState.currentOptions;
            optionState.nextOptions = options;
            optionState.maxStructures = maxStructures;
            optionState.premium = premium;
            optionState.vault = vault;
            optionState.counterparty = counterparty;

            roundExpiry[currentRound] = expiry;

            emit StagedStructure(options, strikes, maxStructures, premium, msg.sender);
        }
    }

    /**
     * @notice Rebalances assets after a round to maximize the total investment in the next round.
     */
    function rebalance(address otc, uint256[] calldata amounts) external nonReentrant {
        _onlyManager();

        VaultUtil.rebalance(otc, amounts, collaterals, optionState.vault, whitelist);
    }

    /**
     * @notice Initiate the batch auction.
     */
    function startAuction() external {
        _onlyManager();

        if (auctionId != 0) revert HV_AuctionInProgress();

        uint256 _auctionDuration = auctionDuration;

        if (block.timestamp + _auctionDuration >= roundExpiry[vaultState.round]) revert HV_BadDuration();

        // number of structures left to sell
        uint256 structures = optionState.maxStructures - optionState.mintedStructures;

        if (structures == 0) revert HV_BadStructures();

        uint256[] memory options = optionState.currentOptions;

        if (options.length == 0) {
            options = optionState.nextOptions;

            if (options.length == 0) revert HV_BadOption();
        }

        AuctionUtil.AuctionParams memory params;
        params.auctionAddr = auction;
        params.collaterals = collaterals;
        params.counterparty = optionState.counterparty;
        params.duration = _auctionDuration;
        params.engineAddr = MARGIN_ENGINE;
        params.maxStructures = optionState.maxStructures;
        params.options = options;
        params.premium = optionState.premium;
        params.premiumToken = collaterals[0].addr;
        params.structures = structures;
        params.whitelist = whitelist;

        uint256 newAuctionId = AuctionUtil.startAuction(params);

        auctionId = newAuctionId;

        emit CreatedAuction(newAuctionId, params.options, msg.sender);
    }

    /**
     * @notice Called by auction on settlement.
     * @dev batch auction transfered premium (if vault is a net seller of the structure)
     * @dev batch auction transfered collateral from bidders if counterparty needed to post margin
     */
    function settledAuction(uint256, /*auctionId*/ uint256 structuresSold, int256 clearingPrice) external override nonReentrant {
        _onlyBatchAuction();

        emit SettledAuction(auctionId, structuresSold, clearingPrice);

        // setting options after first auction settlement
        if (optionState.currentOptions.length == 0) {
            optionState.currentOptions = optionState.nextOptions;

            delete optionState.nextOptions;
        }

        if (structuresSold > 0) {
            StructureUtil.CreateStructuresParams memory params;
            params.collaterals = collaterals;
            params.counterparty = optionState.counterparty;
            params.engineAddr = MARGIN_ENGINE;
            params.instruments = instruments;
            params.maxStructures = optionState.maxStructures;
            params.options = optionState.currentOptions;
            params.structuresToMint = structuresSold;
            params.vault = optionState.vault;

            // if vault paying premium, setting to remove allowance post auction settlement
            if (optionState.premium < 0) params.batchAuctionAddr = auction;

            // creates structures in grappa, returns vault collateral deposits
            uint256[] memory depositAmounts = StructureUtil.createStructures(params);

            unchecked {
                optionState.mintedStructures += structuresSold;
            }

            emit WroteOptions(params.options, structuresSold, depositAmounts, msg.sender);
        }

        // resetting auction id to indicate completion
        auctionId = 0;
    }

    /**
     * @notice Called by auction when bidder claims winnings.
     */
    function novate(address recipient, uint256 amount, uint256[] calldata options, uint256[] calldata counterparty)
        external
        override
        nonReentrant
    {
        _onlyBatchAuction();

        AuctionUtil.novate(MARGIN_ENGINE, instruments, options, collaterals, counterparty, recipient, amount);
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    function _onlyBatchAuction() internal view {
        if (msg.sender != auction) revert HV_Unauthorized();
    }

    /**
     * @notice Settles the margin account positions.
     */
    function _settleOptions(uint256[] memory options) internal {
        if (options.length != 0) {
            // checks if options expired by sampling the first one
            // all options written in a round expire at the same time
            uint256 option = options[0];

            if (!TokenIdUtil.isExpired(option)) revert HV_OptionNotExpired();

            uint256 lockedAmount = vaultState.lockedAmount;

            vaultState.lastLockedAmount = uint104(lockedAmount);
        }

        uint256 mintedStructures = optionState.mintedStructures;

        vaultState.lockedAmount = 0;
        optionState.premium = 0;
        optionState.maxStructures = 0;
        optionState.mintedStructures = 0;
        delete optionState.currentOptions;

        if (options.length != 0) {
            uint256[] memory withdrawAmounts = StructureUtil.settleOptions(MARGIN_ENGINE);

            emit SettledOptions(options, mintedStructures, withdrawAmounts, msg.sender);
        }
    }
}