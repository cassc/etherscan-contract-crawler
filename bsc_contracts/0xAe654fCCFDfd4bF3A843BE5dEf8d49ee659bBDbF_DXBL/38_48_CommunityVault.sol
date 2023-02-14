//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./interfaces/ICommunityVault.sol";
import "./baseContracts/StorageView.sol";
import "./VaultStorage.sol";
import "./baseContracts/V1Migration.sol";
import "./baseContracts/RewardHandler.sol";
import "./baseContracts/ComputationalView.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "hardhat/console.sol";

interface WNative {
    function withdraw(uint256 amount) external;
}

/**
 * The community vault controls the supply of DXBL tokens. It has minting authority on the 
 * token contract so it can request mints/burns on behalf of traders. The Dexible contract
 * is the only address able to request DXBL rewards for trades being made through the protocol.
 *
 * This contract is not upgradeable or modifiable. However, if an upgrade/fork is necessary,
 * the contract can be paused and migrated to a new version after a grace period and only 
 * initiated from the admin multi-sig assigned to the vault.
 */

contract CommunityVault is StorageView, ComputationalView, RewardHandler, V1Migration, ICommunityVault {
    using SafeERC20 for IERC20;


    constructor(VaultStorage.VaultConfig memory config) {
        VaultStorage.VaultData storage vs = VaultStorage.load();
        if(vs.adminMultiSig != address(0)) {
            require(msg.sender == vs.adminMultiSig, "Unauthorized to change configuration");
        } else {
            //pause vault until the dexible contracts are configured
            vs.paused = true;
        }
        require(config.baseMintThreshold > 0, "Must provide a base mint threshold");
        require(config.wrappedNativeToken != address(0), "Invalid wrapped native token");
        require(config.timelockSeconds > 0, "Invalid timelock period");

        vs.adminMultiSig = config.adminMultiSig;
        vs.baseMintThreshold = config.baseMintThreshold;
        vs.wrappedNativeToken = config.wrappedNativeToken;
        vs.timelockSeconds = config.timelockSeconds;
        
        _initializeMintRates(vs, config.rateRanges);
        _initializeFeeTokens(vs, config.feeTokenConfig);
    }

    receive() external payable {
        require(msg.sender == VaultStorage.load().wrappedNativeToken, "Cannot receive funds except for native withdraws");
    }

    function redeemDXBL(address rewardToken, uint dxblAmount, uint minOutAmount, bool unwrapNative) public {
        VaultStorage.VaultData storage rs = VaultStorage.load();
        
        //estimate how much we could withdraw if there is sufficient reward tokens available
        uint wdAmt = estimateRedemption(rewardToken, dxblAmount);

        /**
        * NOTE: is it likely that there will be dust remaining for the asset due to USD
        * rounding/precision.
        *
        * It will be redeemable once the balance acrues enough for the
        * next burn request
        */

        //how much does the vault own?
        uint vaultBal = IERC20(rewardToken).balanceOf(address(this));

        //do we have enough to cover the withdraw?
        if(wdAmt > vaultBal) {
            //vault doesn't have sufficient funds to cover. See if meets trader's 
            //min expectations
            if(vaultBal >= minOutAmount) {
                wdAmt = vaultBal;
            } else {
                revert("Insufficient asset balance to produce expected withdraw amount");
            }
        }
        
        //burn the tokens
        //will revert if insufficient amount
        rs.dxbl.burn(msg.sender, dxblAmount);

        //if all good, transfer withdraw amount to caller
        emit DXBLRedeemed(msg.sender, dxblAmount, rewardToken, wdAmt);

        if(unwrapNative && rewardToken == rs.wrappedNativeToken) {
            WNative(rs.wrappedNativeToken).withdraw(wdAmt);
            address payable rec = payable(msg.sender);
            require(rec.send(wdAmt), "Transfer failed");
        } else {
            IERC20(rewardToken).safeTransfer(msg.sender, wdAmt);
        }

        //see if there is a pending migration that we can go ahead with
        if(canMigrate()) {
            this.migrateV1();
        }
    }

    /**
     * Called to either initially set or change the dexible and token contract addresses.
     * The token contract address can only be set once.
     */
    function configureContracts(address dexible, address token) public {

        VaultStorage.VaultData storage vs = VaultStorage.load();
        if(address(vs.dxbl) == address(0)) {
            //initial configuration
            vs.dxbl = IDXBL(token);
            vs.paused = false;
        } else {
            //otherwise, can only be changed by multi sig admin
            require(msg.sender == vs.adminMultiSig, "Unauthorized");
        }

        vs.dexible = dexible;
    }

    /**
     * Used in emergency situations when we need to hault operations.
     */
    function pause() public onlyAdmin {
        VaultStorage.VaultData storage vs = VaultStorage.load();
        vs.paused = true;
    }

    function resume() public onlyAdmin {
        VaultStorage.VaultData storage vs = VaultStorage.load();
        vs.paused = false;
    }
    

    function _initializeFeeTokens(VaultStorage.VaultData storage rs, VaultStorage.FeeTokenConfig memory config) internal {
        require(config.feeTokens.length > 0 && config.feeTokens.length == config.priceFeeds.length, "Must provide equal-length arrays for fee tokens and price feeds");

        for(uint i=0;i<config.feeTokens.length;++i) {
            address token = config.feeTokens[i];
            address feed = config.priceFeeds[i];
            rs.feeTokens.push(IERC20(token));
            rs.tokenDecimals[token] = IERC20Metadata(token).decimals();
            rs.allowedFeeTokens[token] = VaultStorage.PriceFeed({
                feed: IPriceFeed(feed),
                decimals: IPriceFeed(feed).decimals()
            });
        }
        require(rs.allowedFeeTokens[rs.wrappedNativeToken].decimals > 0, "Wrapped native asset must be a valid fee token");
    }


    /**
     * Initialize the mint rate buckets
     */
    function _initializeMintRates(VaultStorage.VaultData storage rs, VaultStorage.MintRateRangeConfig[] memory ranges) internal {
        require(rs.mintRateRanges.length == 0, "Already initialized rate ranges");
        for(uint i=0;i<ranges.length;++i) {
            VaultStorage.MintRateRangeConfig memory rc = ranges[i];
            require(rc.maxMMVolume > 0, "Max MM Volume must be > 0");
            require(rc.rate > 0, "Rate must be > 0");
            rs.mintRateRanges.push(VaultStorage.MintRateRange({
                minMMVolume: rc.minMMVolume,
                maxMMVolume: rc.maxMMVolume,
                rate: rc.rate,
                index: i
            }));
        }
        rs.currentMintRate = rs.mintRateRanges[0];
    }
}