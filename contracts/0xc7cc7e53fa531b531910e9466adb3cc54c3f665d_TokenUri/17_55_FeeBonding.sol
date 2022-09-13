// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {PuttyV2} from "putty-v2/PuttyV2.sol";
import {LSSVMPairMissingEnumerableETH} from "lssvm/LSSVMPairMissingEnumerableETH.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {MintBurnToken} from "./lib/MintBurnToken.sol";
import {BondingNft} from "./lib/BondingNft.sol";

/**
 * @notice Fee bonding stuff.
 *
 * LP's stake their LP tokens for preset bond durations. In return they receive
 * fee rewards from the shared sudo xyk pool. Fees can be claimed after the bond matures.
 * The longer the bond duration, the higher the yield boost. Fees are distributed via the
 * skim() method.
 *
 * @author 0xacedia
 */
contract FeeBonding {
    /**
     * @notice Bond details.
     * @param rewardPerTokenCheckpoint The total rewards per token at bond creation.
     * @param depositAmount The amount of lp tokens deposited into the bond.
     * @param depositTimestamp The unix timestamp of the deposit.
     * @param termIndex The index into the terms array for the bond term.
     */
    struct FeeBond {
        uint256 rewardPerTokenCheckpoint;
        uint128 depositAmount;
        uint32 depositTimestamp;
        uint8 termIndex;
    }

    /// @notice The term duration options for bonds.
    uint256[] private terms = [0 days, 7 days, 30 days, 90 days, 180 days, 365 days];

    /// @notice The yield boost options for corresponding to each term.
    uint256[] private termBoosters = [1e18, 1.1e18, 1.2e18, 1.5e18, 2e18, 3e18];

    /// @notice The last calculated amount of rewards per token.
    uint256 public feeRewardPerTokenStored;

    /// @notice The total amount of bonds in existence.
    uint32 public feeTotalBondSupply;

    /// @notice The total amount of synthetic supply being staked.
    /// @dev Calculated by summing total lp tokens staked * yield booster.
    uint128 public feeStakedTotalSupply;

    /// @notice Mapping of bondId to bond details.
    mapping(uint256 => FeeBond) private _bonds;

    BondingNft public immutable feeBondingNft;
    MintBurnToken private immutable lpToken;
    LSSVMPairMissingEnumerableETH private pair;

    /**
     * @notice Emitted when LP tokens are staked.
     * @param bondId The tokenId of the new bond.
     * @param bond The bond details.
     */
    event FeeStake(uint256 bondId, FeeBond bond);

    /**
     * @notice Emitted when LP tokens are unstaked.
     * @param bondId The tokenId of the bond being unstaked.
     * @param bond The bond details.
     */
    event FeeUnstake(uint256 bondId, FeeBond bond);

    constructor(address _lpToken) {
        lpToken = MintBurnToken(_lpToken);
        feeBondingNft = new BondingNft("Wheyfu LP Fee Bonds", "WLPFB");
    }

    /**
     * @notice Sets the sudoswap pool address.
     * @param _pair The sudoswap pool.
     */
    function _setPair(address payable _pair) internal {
        pair = LSSVMPairMissingEnumerableETH(_pair);
    }

    /**
     * ~~~~~~~~~~~~~~~~~
     * STAKING FUNCTIONS
     * ~~~~~~~~~~~~~~~~~
     */

    /**
     * @notice Skims the fees from the sudoswap pool and distributes them to fee stakers.
     */
    function skim() public returns (uint256) {
        // skim the fees
        uint256 tokenReserves = pair.spotPrice();
        uint256 fees = address(pair).balance > tokenReserves ? address(pair).balance - tokenReserves : 0;
        pair.withdrawETH(fees);

        // distribute the fees to stakers
        if (fees > 0 && feeStakedTotalSupply > 0) {
            feeRewardPerTokenStored += (fees * 1e18) / feeStakedTotalSupply;
        }

        return fees;
    }

    /**
     * @notice Stakes an amount of lp tokens for a given term.
     * @param amount Amount of lp tokens to stake.
     * @param termIndex Index into the terms array which tells how long to stake for.
     */
    function feeStake(uint128 amount, uint256 termIndex) public returns (uint256 tokenId) {
        // update the rewards for everyone
        skim();

        // update the bond supply
        feeTotalBondSupply += 1;
        tokenId = feeTotalBondSupply;

        // set the bond parameters
        FeeBond storage bond = _bonds[tokenId];
        bond.rewardPerTokenCheckpoint = uint256(feeRewardPerTokenStored);
        bond.depositAmount = amount;
        bond.depositTimestamp = uint32(block.timestamp);
        bond.termIndex = uint8(termIndex);

        // update the staked total supply
        feeStakedTotalSupply += uint128((uint256(amount) * termBoosters[termIndex]) / 1e18);

        // transfer lp tokens from sender
        lpToken.transferFrom(msg.sender, address(this), amount);

        // mint the bond
        feeBondingNft.mint(msg.sender, tokenId);

        emit FeeStake(tokenId, bond);
    }

    /**
     * @notice Unstakes a bond, returns lp tokens and mints call option tokens.
     * @param tokenId The tokenId of the bond to unstake.
     */
    function feeUnstake(uint256 tokenId) public returns (uint256 rewardAmount) {
        // check that the user owns the bond
        require(msg.sender == feeBondingNft.ownerOf(tokenId), "Not owner");

        // check that the bond has matured
        FeeBond memory bond = _bonds[tokenId];
        require(block.timestamp >= bond.depositTimestamp + terms[bond.termIndex], "Bond not matured");

        // update the rewards for everyone
        skim();

        // burn the bond
        feeBondingNft.burn(tokenId);

        // update staked total supply
        uint256 amount = bond.depositAmount;
        feeStakedTotalSupply -= uint128((uint256(amount) * termBoosters[bond.termIndex]) / 1e18);

        // send lp tokens back to sender
        lpToken.transfer(msg.sender, amount);

        // send fee rewards to sender
        rewardAmount = feeEarned(tokenId);
        SafeTransferLib.safeTransferETH(msg.sender, rewardAmount);

        emit FeeUnstake(tokenId, bond);
    }

    /**
     * @notice Calculates how much fees a bond has earned.
     * @param tokenId The tokenId to fetch earned info for.
     * @return earned How much fees the bond has earned.
     */
    function feeEarned(uint256 tokenId) public view returns (uint256) {
        FeeBond storage bond = _bonds[tokenId];
        uint256 boostedAmount = bond.depositAmount * termBoosters[bond.termIndex];

        return ((boostedAmount) * (feeRewardPerTokenStored - bond.rewardPerTokenCheckpoint)) / 1e36;
    }

    /**
     * @notice Getter for fee bond details.
     * @param tokenId The tokenId to fetch info for.
     * @return bondDetails The bond details.
     */
    function feeBonds(uint256 tokenId) public view returns (FeeBond memory) {
        return _bonds[tokenId];
    }
}