// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;

import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Kiko} from "../../libraries/Kiko.sol";
import {ShareMathKiko} from "../../libraries/ShareMathKiko.sol";
import {ExoticOracleInterface} from "../../interfaces/ExoticOracleInterface.sol";
import {PolysynthKikoVaultStorage} from "../../storage/PolysynthKikoVaultStorage.sol";
import {KikoVault} from "./KikoVault.sol";

contract PolysynthKikoVault is 
    KikoVault,
    PolysynthKikoVaultStorage
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using ShareMathKiko for Kiko.DepositReceipt;

    constructor(
        address _oracle        
    ) KikoVault(_oracle){}

    function initialize(
        address _owner,
        address _keeper,
        address _feeRecipent,        
        string memory _tokenName,
        string memory _tokenSymbol,
        Kiko.VaultParams calldata _vaultParams
    ) external initializer {
        baseInitialize(_owner, _keeper, _feeRecipent, _tokenName, _tokenSymbol, _vaultParams);
    }

    modifier onlyObserver() {
        require(msg.sender == observer, "!observer");
        _;
    }


    function setAuctionTime(uint256 _auctionTime) external onlyOwner {
        require(_auctionTime != 0, "!_auctionTime");
        auctionTime = _auctionTime;
    }

    function setObserver(address _newObserver) external onlyOwner {
        require(_newObserver != address(0), "!_newObserver");
        observer = _newObserver;
    }

    /**
     * @notice Initiates a withdrawal that can be processed once the round completes
     * @param numShares is the number of shares to withdraw
     */
    function initiateWithdraw(uint256 numShares) external nonReentrant {
        _initiateWithdraw(numShares);
        currentQueuedWithdrawShares = currentQueuedWithdrawShares.add(
            numShares
        );
    }

    /**
     * @notice Completes a scheduled withdrawal from a past round. Uses finalized pps for the round
     */
    function completeWithdraw() external nonReentrant {
        uint256 withdrawAmount = _completeWithdraw();
        lastQueuedWithdrawAmount = uint128(
            uint256(lastQueuedWithdrawAmount).sub(withdrawAmount)
        );
    }

    function close() external nonReentrant onlyKeeper{
        // 1, Check if settlement is done by MM
        // 2. Calculate PPS
        require(
            optionState.isSettled || vaultState.round == 1,
            "Round closed"
        );        

        uint256 currQueuedWithdrawShares = currentQueuedWithdrawShares;
        (uint256 lockedBalance, uint256 queuedWithdrawAmount) =
            _closeRound();

        lastQueuedWithdrawAmount = queuedWithdrawAmount;

        uint256 newQueuedWithdrawShares =
            uint256(vaultState.queuedWithdrawShares).add(
                currQueuedWithdrawShares
            );
        ShareMathKiko.assertUint128(newQueuedWithdrawShares);
        vaultState.queuedWithdrawShares = uint128(newQueuedWithdrawShares);

        currentQueuedWithdrawShares = 0;

        ShareMathKiko.assertUint104(lockedBalance);
        vaultState.lockedAmount = uint104(lockedBalance);

        // Set strike price for all the underlying assets
        // Currently strike prices are 8AM UTC price of vault start day
        // Make this 1PM UTC
        uint256 tt = block.timestamp - (block.timestamp % (1 days)) + auctionTime;
        for (uint256 i = 0; i < vaultParams.basketSize; i++) {
            uint256 assetPrice = getExpiryPrice(vaultParams.underlyings[i], tt);
            require(assetPrice > 0, "assetPrice is 0");
            assetStrikePrices[vaultParams.underlyings[i]] = assetPrice.mul(vaultParams.strikeRatio).div(Kiko.RATIO_MULTIPLIER);
        }

        optionState.isSettled = false;
        optionState.hasKnockedIn = false;
        optionState.hasKnockedOut = false;
        optionState.vaultActiveDays = 0;
        optionState.couponRate = 0;
        optionState.borrowRate = 0;
        optionState.isBorrowed = false;
        optionState.koTime = 0;
        optionState.lastObservation = 0;
        // Make this expiry to be of 8AM
        uint256 future30Days = block.timestamp.add(vaultParams.vaultPeriod);
        optionState.expiry = future30Days - (future30Days % (1 days)) + (8 hours);
     }

    function _closeRound() internal returns (uint256 lockedBalance, uint256 queuedWithdrawAmount) {
        address recipient = feeRecipient;
        uint256 mintShares;
        uint256 performanceFeeInAsset;
        uint256 totalVaultFee;
        {
            uint256 newPricePerShare;

            uint256 currentBalance = IERC20(vaultParams.asset).balanceOf(address(this));
            uint256 pendingAmount = vaultState.totalPending;
            uint256 currentShareSupply = totalSupply();
            // Total amount of queued withdrawal shares from previous rounds (doesn't include the current round)
            uint256 lastQueuedWithdrawShares = vaultState.queuedWithdrawShares;

            // Deduct older queued withdraws so we don't charge fees on them
            uint256 balanceForVaultFees =
                currentBalance.sub(lastQueuedWithdrawAmount);

            {
                (performanceFeeInAsset, , totalVaultFee) = getVaultFees(
                    balanceForVaultFees,
                    vaultState.lockedAmount,
                    vaultState.totalPending,
                    performanceFee,
                    managementFee                    
                );
            }

            // Take into account the fee
            // so we can calculate the newPricePerShare
            currentBalance = currentBalance.sub(totalVaultFee);

            {
                newPricePerShare = ShareMathKiko.pricePerShare(
                    currentShareSupply.sub(lastQueuedWithdrawShares),
                    currentBalance.sub(lastQueuedWithdrawAmount),
                    pendingAmount,
                    vaultParams.decimals
                );

                queuedWithdrawAmount = lastQueuedWithdrawAmount.add(
                    ShareMathKiko.sharesToAsset(
                        currentQueuedWithdrawShares,
                        newPricePerShare,
                        vaultParams.decimals
                    )
                );

                // After closing the short, if the options expire in-the-money
                // vault pricePerShare would go down because vault's asset balance decreased.
                // This ensures that the newly-minted shares do not take on the loss.
                mintShares = ShareMathKiko.assetToShares(
                    pendingAmount,
                    newPricePerShare,
                    vaultParams.decimals
                );
            }


            // Finalize the pricePerShare at the end of the round
            uint256 currentRound = vaultState.round;
            roundPricePerShare[currentRound] = newPricePerShare;

            emit CollectVaultFees(
                performanceFeeInAsset,
                totalVaultFee,
                currentRound,
                recipient
            );

            vaultState.totalPending = 0;
            vaultState.round = uint16(currentRound + 1);

            lockedBalance = currentBalance.sub(queuedWithdrawAmount);
        }

        _mint(address(this), mintShares);

        if (totalVaultFee > 0) {
            transferAsset(payable(recipient), totalVaultFee);
        }        

        return (lockedBalance, queuedWithdrawAmount);
    }

    function observe() external onlyObserver nonReentrant {
        _observe();
    }

}