// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {Clone} from "clones-with-immutable-args/Clone.sol";
import {ClonesWithImmutableArgs} from "clones-with-immutable-args/ClonesWithImmutableArgs.sol";

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {IOwnershipTransferReceiver} from "../lib/IOwnershipTransferReceiver.sol";
import {OwnableWithTransferCallback} from "../lib/OwnableWithTransferCallback.sol";

import {ILSSVMPair} from "../ILSSVMPair.sol";
import {LSSVMPair} from "../LSSVMPair.sol";
import {ILSSVMPairFactoryLike} from "../ILSSVMPairFactoryLike.sol";
import {ISettings} from "./ISettings.sol";
import {Splitter} from "./Splitter.sol";
import {LSSVMPairERC1155} from "../erc1155/LSSVMPairERC1155.sol";
import {CurveErrorCodes} from "../bonding-curves/CurveErrorCodes.sol";

contract StandardSettings is IOwnershipTransferReceiver, OwnableWithTransferCallback, Clone, ISettings {
    using ClonesWithImmutableArgs for address;
    using SafeTransferLib for address payable;

    uint96 constant MAX_SETTABLE_FEE = 0.2e18; // Max fee of 20% (0.2)

    mapping(address => PairInfo) public pairInfos;
    address payable public settingsFeeRecipient;

    Splitter immutable splitterImplementation;
    ILSSVMPairFactoryLike immutable pairFactory;

    error StandardSettings__BondingCurveError(CurveErrorCodes.Error error);

    event StandardSettings__PairAddedSettings(address indexed pairAddress);
    event StandardSettings__PairRemovedSettings(address indexed pairAddress);

    constructor(Splitter _splitterImplementation, ILSSVMPairFactoryLike _pairFactory) {
        splitterImplementation = _splitterImplementation;
        pairFactory = _pairFactory;
    }

    function initialize(address _owner, address payable _settingsFeeRecipient) public {
        require(owner() == address(0), "Initialized");
        __Ownable_init(_owner);
        settingsFeeRecipient = _settingsFeeRecipient;
    }

    // Immutable params

    /**
     * @return Returns the upfront cost to enter into the Settings, in ETH
     */
    function getSettingsCost() public pure returns (uint256) {
        return _getArgUint256(0);
    }

    /**
     * @return Returns the minimum lock duration of the Settings, in seconds
     */
    function getLockDuration() public pure returns (uint64) {
        return _getArgUint64(32);
    }

    /**
     * @return Returns the trade fee split for the duration of the Settings, in bps
     */
    function getFeeSplitBps() public pure returns (uint64) {
        return _getArgUint64(40);
    }

    /**
     * @return Returns the modified royalty amount for the duration of the Settings, in bps
     */
    function getSettingsRoyaltyBps() public pure returns (uint64) {
        return _getArgUint64(48);
    }

    // Admin functions

    /**
     * @param newFeeRecipient The address to receive all payments plus trade fees
     */
    function setSettingsFeeRecipient(address payable newFeeRecipient) public onlyOwner {
        settingsFeeRecipient = newFeeRecipient;
    }

    // View functions

    /**
     * @param pairAddress The address of the pair to look up
     * @return Returns the previously set fee recipient address for a pair
     */
    function getPrevFeeRecipientForPair(address pairAddress) public view returns (address) {
        return pairInfos[pairAddress].prevFeeRecipient;
    }

    /**
     * @notice Fetches the royalty info for a pair address
     * @param pairAddress The address of the pair to look up
     * @return Returns whether the royalty is enabled and the royalty bps if enabled
     */
    function getRoyaltyInfo(address pairAddress) external view returns (bool, uint96) {
        if (LSSVMPair(pairAddress).owner() == address(this)) {
            return (true, getSettingsRoyaltyBps());
        }
        return (false, 0);
    }

    // Functions intended to be called by the pair or pair owner

    /**
     * @notice Callback after ownership is transferred to this contract from a pair
     * This function performs the following:
     * - upfront payment, if any, is taken
     * - pair verification and nft verification (done in pair factory external call)
     * - the modified royalty bps is set (done in pair factory external call)
     * - the previous fee recipient / owner parameters are recorded and saved
     * - a new fee splitter clone is deployed
     * - the fee recipient of the pair is set to the fee splitter
     * @param prevOwner The owner of the pair calling transferOwnership
     */
    function onOwnershipTransferred(address prevOwner, bytes calldata) public payable {
        ILSSVMPair pair = ILSSVMPair(msg.sender);

        // Only for trade pairs
        require(pair.poolType() == ILSSVMPair.PoolType.TRADE, "Only TRADE pairs");

        // Prevent high-fee trading pairs
        require(pair.fee() <= MAX_SETTABLE_FEE, "Fee too high");

        // Verify the upfront cost
        require(msg.value == getSettingsCost(), "Insufficient payment");

        // Transfer the ETH to the fee recipient
        if (msg.value != 0) {
            settingsFeeRecipient.safeTransferETH(msg.value);
        }

        // Enable settings in factory contract. This also validates that msg.sender is a valid pair.
        try pairFactory.enableSettingsForPair(address(this), msg.sender) {}
        catch {
            revert("Pair verification failed");
        }

        // Store the original owner, unlock date, and old fee recipient
        pairInfos[msg.sender] = PairInfo({
            prevOwner: prevOwner,
            unlockTime: uint96(block.timestamp) + getLockDuration(),
            prevFeeRecipient: ILSSVMPair(msg.sender).getFeeRecipient()
        });

        // Deploy the fee splitter clone
        // param1 = parent Settings address, i.e. address(this)
        // param2 = pair address, i.e. msg.sender
        bytes memory data = abi.encodePacked(address(this), msg.sender);
        address splitterAddress = address(splitterImplementation).clone(data);

        // Set the asset (i.e. fee) recipient to be the splitter clone
        ILSSVMPair(msg.sender).changeAssetRecipient(payable(splitterAddress));

        emit StandardSettings__PairAddedSettings(msg.sender);
    }

    /**
     * @notice Transfers ownership of the pair back to the original owner
     * @param pairAddress The address of the pair to reclaim ownership
     */
    function reclaimPair(address pairAddress) public {
        PairInfo memory pairInfo = pairInfos[pairAddress];

        ILSSVMPair pair = ILSSVMPair(pairAddress);

        // Verify that the caller is the previous pair owner or admin of the NFT collection
        if (msg.sender == pairInfo.prevOwner || pairFactory.authAllowedForToken(address(pair.nft()), msg.sender)) {
            // Verify that the current time is past the unlock time
            require(block.timestamp > pairInfo.unlockTime, "Lockup not over");
        } else {
            revert("Not prev owner or authed");
        }

        // Split fees (if applicable)
        ILSSVMPairFactoryLike.PairTokenType pairTokenType = pairFactory.getPairTokenType(pairAddress);
        if (pairTokenType == ILSSVMPairFactoryLike.PairTokenType.ETH) {
            Splitter(payable(pair.getFeeRecipient())).withdrawAllETHInSplitter();
        } else if (pairTokenType == ILSSVMPairFactoryLike.PairTokenType.ERC20) {
            Splitter(payable(pair.getFeeRecipient())).withdrawAllBaseQuoteTokens();
        }

        // Change the fee recipient back
        pair.changeAssetRecipient(payable(pairInfo.prevFeeRecipient));

        // Disable the royalty override
        pairFactory.disableSettingsForPair(address(this), pairAddress);

        // Transfer ownership back to original pair owner
        OwnableWithTransferCallback(pairAddress).transferOwnership(pairInfo.prevOwner, "");

        // Remove pairInfo entry
        delete pairInfos[pairAddress];

        emit StandardSettings__PairRemovedSettings(pairAddress);
    }

    /**
     * @notice Allows a pair owner to adjust fee % even while a pair has Settings enabled
     * @param pairAddress The address of the pair to change fee
     * @param newFee The new fee to set the pair to, subject to MAX_FEE or less
     */
    function changeFee(address pairAddress, uint96 newFee) public {
        // Verify that the caller is the previous owner of the pair
        require(msg.sender == pairInfos[pairAddress].prevOwner, "Not prev owner");
        require(newFee <= MAX_SETTABLE_FEE, "Fee too high");
        ILSSVMPair(pairAddress).changeFee(newFee);
    }

    /**
     * @notice Allows a pair owner to adjust spot price / delta even while a pair is in an Settings, subject to liquidity considerations
     * @param pairAddress The address of the pair to change spot price and delta for
     * @param newSpotPrice The new spot price
     * @param newDelta The new delta
     */
    function changeSpotPriceAndDelta(address pairAddress, uint128 newSpotPrice, uint128 newDelta, uint256 assetId)
        public
    {
        // Verify that the caller is the previous owner of the pair
        require(msg.sender == pairInfos[pairAddress].prevOwner, "Not prev owner");

        ILSSVMPair pair = ILSSVMPair(pairAddress);

        // Get current price to buy from pair
        (CurveErrorCodes.Error error,,, uint256 priceToBuyFromPair,,) = pair.getBuyNFTQuote(assetId, 1);
        if (error != CurveErrorCodes.Error.OK) {
            revert StandardSettings__BondingCurveError(error);
        }

        // Get new price to buy from pair
        uint256 newPriceToBuyFromPair;
        (
            error,
            ,
            ,
            /* error */
            /* new spot price */
            /* new delta */
            newPriceToBuyFromPair, /* trade fee */ /* protocol fee */
            ,
        ) = pair.bondingCurve().getBuyInfo(newSpotPrice, newDelta, 1, pair.fee(), pairFactory.protocolFeeMultiplier());
        if (error != CurveErrorCodes.Error.OK) {
            revert StandardSettings__BondingCurveError(error);
        }

        uint256 nftBalance;
        if (pairFactory.getPairNFTType(pairAddress) == ILSSVMPairFactoryLike.PairNFTType.ERC721) {
            nftBalance = IERC721(pair.nft()).balanceOf(pairAddress);
        } else {
            nftBalance = IERC1155(pair.nft()).balanceOf(pairAddress, LSSVMPairERC1155(pairAddress).nftId());
        }

        // If the price to buy is now lower (i.e. NFTs are now cheaper), and there is at least 1 NFT in pair, then make the change
        if ((newPriceToBuyFromPair < priceToBuyFromPair) && nftBalance > 0) {
            pair.changeSpotPrice(newSpotPrice);
            pair.changeDelta(newDelta);
            return;
        }

        // Get current price to buy from pair
        uint256 priceToSellToPair;
        (error,,, priceToSellToPair,,) = pair.getSellNFTQuote(assetId, 1);
        if (error != CurveErrorCodes.Error.OK) {
            revert StandardSettings__BondingCurveError(error);
        }

        // Get new price to sell to pair
        uint256 newPriceToSellToPair;
        (
            error,
            ,
            ,
            /* error */
            /* new spot price */
            /* new delta */
            newPriceToSellToPair, /* trade fee */ /* protocol fee */
            ,
        ) = pair.bondingCurve().getSellInfo(newSpotPrice, newDelta, 1, pair.fee(), pairFactory.protocolFeeMultiplier());
        if (error != CurveErrorCodes.Error.OK) {
            revert StandardSettings__BondingCurveError(error);
        }

        // Get token balance of the pair (ETH or ERC20)
        uint256 pairBalance;
        if (pairFactory.getPairTokenType(pairAddress) == ILSSVMPairFactoryLike.PairTokenType.ETH) {
            pairBalance = pairAddress.balance;
        } else if (pairFactory.getPairTokenType(pairAddress) == ILSSVMPairFactoryLike.PairTokenType.ERC20) {
            pairBalance = pair.token().balanceOf(pairAddress);
        }

        // If the new sell price is higher, and there is enough liquidity to support at least 1 sell, then make the change
        if ((newPriceToSellToPair > priceToSellToPair) && pairBalance >= newPriceToSellToPair) {
            pair.changeSpotPrice(newSpotPrice);
            pair.changeDelta(newDelta);
            return;
        }

        revert("Pricing and liquidity mismatch");
    }

    /**
     * @notice Allows owners or pair owners to bulk withdraw trade fees from a series of Splitters
     * @param splitterAddresses List of addresses of Splitters to withdraw from
     * @param isETHPair If the underlying Splitter's pair is an ETH pair or not
     */
    function bulkWithdrawFees(address[] calldata splitterAddresses, bool[] calldata isETHPair) external {
        for (uint256 i; i < splitterAddresses.length;) {
            Splitter splitter = Splitter(payable(splitterAddresses[i]));
            if (isETHPair[i]) {
                splitter.withdrawAllETHInSplitter();
            } else {
                splitter.withdrawAllBaseQuoteTokens();
            }
            unchecked {
                ++i;
            }
        }
    }
}