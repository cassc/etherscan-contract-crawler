// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {PuttyV2} from "putty-v2/PuttyV2.sol";

import {MintBurnToken} from "./lib/MintBurnToken.sol";
import {BondingNft} from "./lib/BondingNft.sol";

/**
 * @notice Option bonding stufffff.
 *
 * LP's stake their LP tokens for preset bond durations. In return they receive
 * call option token rewards which are distributed linearly over time. Option token
 * rewards can be claimed after the bond matures. The longer the bond duration, the
 * higher the yield boost.
 *
 * The option ERC20 tokens can be converted for actual call option contracts on putty via the
 * convertToOption() method. Each call option has a strike of 0.1 ether per NFT and expires
 * in 5 years from now. When the option is exercised, the wheyfus are minted to your wallet.
 *
 * @author 0xacedia
 */
contract OptionBonding is IERC1271, Owned {
    /**
     * @notice Bond details.
     * @param rewardPerTokenCheckpoint The total rewards per token at bond creation.
     * @param depositAmount The amount of lp tokens deposited into the bond.
     * @param depositTimestamp The unix timestamp of the deposit.
     * @param termIndex The index into the terms array for the bond term.
     */
    struct OptionBond {
        uint256 rewardPerTokenCheckpoint;
        uint128 depositAmount;
        uint32 depositTimestamp;
        uint8 termIndex;
    }

    /// @notice The term duration options for bonds.
    uint256[] public terms = [0, 7 days, 30 days, 90 days, 180 days, 365 days];

    /// @notice The yield boost options for corresponding to each term.
    uint256[] public termBoosters = [1e18, 1.1e18, 1.2e18, 1.5e18, 2e18, 3e18];

    /// @notice The total amount of call option tokens to give out in bond rewards.
    uint256 public constant TOTAL_REWARDS = 18_000 * 1e18;

    /// @notice The duration over which bond rewards are distributed.
    uint256 public constant REWARD_DURATION = 900 days;

    /// @notice The emission rate for call option tokens.
    /// @dev Calculated by taking the total rewards and dividing it by the reward duration.
    uint256 public immutable rewardRate = TOTAL_REWARDS / REWARD_DURATION;

    /// @notice The strike price for each call option.
    uint256 public constant STRIKE = 0.1 ether;

    /// @notice The expiration date of each option.
    /// @dev The expiration date is set to be 1825 days from the deployment date (approx. 5 years).
    uint256 public immutable optionExpiration = block.timestamp + 1825 days;

    /// @notice The date at which rewards will stop being distributed.
    /// @dev Set to be the deploy timestamp + the reward duration.
    uint256 public immutable finishAt = block.timestamp + REWARD_DURATION;

    /// @notice The date at which rewards started being distributed.
    uint256 public immutable startAt = block.timestamp;

    /// @notice The last calculated amount of rewards per token.
    uint256 public optionRewardPerTokenStored;

    /// @notice The last time at which staking rewards were calculated.
    uint32 public lastUpdateTime = uint32(block.timestamp);

    /// @notice The total amount of bonds in existence.
    uint32 public optionBondTotalSupply;

    /// @notice The total amount of synthetic supply being staked.
    /// @dev Calculated by summing total lp tokens staked * yield booster.
    uint128 public optionStakedTotalSupply;

    /// @notice Mapping of bondId to bond details.
    mapping(uint256 => OptionBond) private _bonds;

    MintBurnToken public immutable callOptionToken;
    MintBurnToken public immutable lpToken;
    BondingNft public immutable optionBondingNft;
    PuttyV2 public immutable putty;
    IERC20 public immutable weth;

    /**
     * @notice Emitted when LP tokens are staked.
     * @param bondId The tokenId of the new bond.
     * @param bond The bond details.
     */
    event OptionStake(uint256 bondId, OptionBond bond);

    /**
     * @notice Emitted when LP tokens are unstaked.
     * @param bondId The tokenId of the bond being unstaked.
     * @param bond The bond details.
     */
    event OptionUnstake(uint256 bondId, OptionBond bond);

    constructor(address _lpToken, address _callOptionToken, address _putty, address _weth) Owned(msg.sender) {
        lpToken = MintBurnToken(_lpToken);
        callOptionToken = MintBurnToken(_callOptionToken);
        putty = PuttyV2(_putty);
        weth = IERC20(_weth);
        optionBondingNft = new BondingNft("Wheyfu LP Option Bonds", "WLPOB");
    }

    /**
     * ~~~~~~~~~~~~~~~~~
     * STAKING FUNCTIONS
     * ~~~~~~~~~~~~~~~~~
     */

    /**
     * @notice Stakes an amount of lp tokens for a given term.
     * @param amount Amount of lp tokens to stake.
     * @param termIndex Index into the terms array which tells how long to stake for.
     */
    function optionStake(uint128 amount, uint256 termIndex) public returns (uint256 tokenId) {
        // update the rewards for everyone
        optionRewardPerTokenStored = uint256(rewardPerToken());

        // update bond supply
        optionBondTotalSupply += 1;
        tokenId = optionBondTotalSupply;

        // set the bond parameters
        OptionBond storage bond = _bonds[tokenId];
        bond.rewardPerTokenCheckpoint = uint256(optionRewardPerTokenStored);
        bond.depositAmount = amount;
        bond.depositTimestamp = uint32(block.timestamp);
        bond.termIndex = uint8(termIndex);

        // update last update time and staked total supply
        lastUpdateTime = uint32(block.timestamp);
        optionStakedTotalSupply += uint128((uint256(amount) * termBoosters[termIndex]) / 1e18);

        // transfer lp tokens from sender
        lpToken.transferFrom(msg.sender, address(this), amount);

        // mint the bond
        optionBondingNft.mint(msg.sender, tokenId);

        emit OptionStake(tokenId, bond);
    }

    /**
     * @notice Unstakes a bond, returns lp tokens and mints call option tokens.
     * @param tokenId The tokenId of the bond to unstake.
     */
    function optionUnstake(uint256 tokenId) public returns (uint256 callOptionAmount) {
        // check that the user owns the bond
        require(msg.sender == optionBondingNft.ownerOf(tokenId), "Not owner");

        // check that the bond has matured
        OptionBond memory bond = _bonds[tokenId];
        require(block.timestamp >= bond.depositTimestamp + terms[bond.termIndex], "Bond not matured");

        // update the rewards for everyone
        optionRewardPerTokenStored = uint256(rewardPerToken());

        // burn the bond
        optionBondingNft.burn(tokenId);

        // update last update time and staked total supply
        lastUpdateTime = uint32(block.timestamp);
        uint256 amount = bond.depositAmount;
        optionStakedTotalSupply -= uint128((uint256(amount) * termBoosters[bond.termIndex]) / 1e18);

        // send lp tokens back to sender
        lpToken.transfer(msg.sender, amount);

        // mint call option rewards to sender
        callOptionAmount = optionEarned(tokenId);
        callOptionToken.mint(msg.sender, callOptionAmount);

        emit OptionUnstake(tokenId, bond);
    }

    /**
     * @notice Gets the total amount of token rewards earned per token staked.
     * Should not accrue any more rewards if we are past the finishAt timestamp.
     */
    function rewardPerToken() public view returns (uint256) {
        if (optionStakedTotalSupply == 0) {
            return optionRewardPerTokenStored;
        }

        uint256 delta = Math.min(block.timestamp, finishAt) - Math.min(lastUpdateTime, finishAt);

        return optionRewardPerTokenStored + ((delta * rewardRate * 1e18) / optionStakedTotalSupply);
    }

    /**
     * @notice Gets the total amount of option tokens earned for a bond.
     * @param tokenId The id of the bond.
     */
    function optionEarned(uint256 tokenId) public view returns (uint256) {
        OptionBond storage bond = _bonds[tokenId];
        uint256 boostedAmount = bond.depositAmount * termBoosters[bond.termIndex];

        return (boostedAmount * (rewardPerToken() - bond.rewardPerTokenCheckpoint)) / 1e36;
    }

    /**
     * ~~~~~~~~~~~~~~~~
     * OPTION FUNCTIONS
     * ~~~~~~~~~~~~~~~~
     */

    /**
     * @notice Burns call option tokens and converts them into an actual call option contract via putty.
     * @param numAssets The amount of assets to put into the call option.
     * @param nonce The nonce for the call option (prevents hash collisions).
     */
    function convertToOption(uint256 numAssets, uint256 nonce)
        public
        returns (uint256 longTokenId, PuttyV2.Order memory shortOrder)
    {
        require(numAssets > 0, "Must convert at least one asset");
        require(numAssets <= 50, "Must convert 50 or less assets");

        // set the option parameters
        shortOrder.maker = address(this);
        shortOrder.isCall = true;
        shortOrder.isLong = false;
        shortOrder.baseAsset = address(weth);
        shortOrder.strike = STRIKE * numAssets;
        shortOrder.duration = optionExpiration - block.timestamp;
        shortOrder.expiration = block.timestamp + 1;
        shortOrder.nonce = nonce;
        shortOrder.erc721Assets = new PuttyV2.ERC721Asset[](1);
        shortOrder.erc721Assets[0] = PuttyV2.ERC721Asset({
            token: address(this),
            tokenId: type(uint256).max - numAssets // this value is used to determine how many tokens to mint in onExercise
        });

        // burn the call option tokens from the sender
        callOptionToken.burn(msg.sender, numAssets * 1e18);

        // mint the option and send the long option to the sender
        longTokenId = _mintOption(shortOrder);
        putty.transferFrom(address(this), msg.sender, longTokenId);
    }

    // @notice Guard variable that tells us whether or not we are minting an option.
    uint256 public mintingOption = 1;

    /**
     * @notice Whether or not an order from putty can be filled.
     * @dev This should only return true when mintingOption is set to 2.
     */
    function isValidSignature(bytes32, bytes memory) external view returns (bytes4 magicValue) {
        magicValue = mintingOption == 2 ? IERC1271.isValidSignature.selector : bytes4(0);
    }

    /**
     * @notice Mints a new putty option.
     * @param order The order details to mint.
     */
    function _mintOption(PuttyV2.Order memory order) internal returns (uint256 tokenId) {
        mintingOption = 2;
        uint256[] memory empty = new uint256[](0);
        bytes memory signature;

        tokenId = putty.fillOrder(order, signature, empty);
        mintingOption = 1;
    }

    /**
     * @notice Withdraws the eth earned from exercised call options.
     * @param orders The options that were exercised.
     * @param recipient Who to send the weth to.
     */
    function withdrawWeth(PuttyV2.Order[] memory orders, address recipient) public onlyOwner {
        for (uint256 i = 0; i < orders.length; i++) {
            // withdraw all the strike weth form exercised options
            putty.withdraw(orders[i]);
        }

        // transfer all of the earned weth to the recipient
        weth.transfer(recipient, weth.balanceOf(address(this)));
    }

    /**
     * ~~~~~~~~~~~~~~~~~
     * MISC. FUNCTIONS
     * ~~~~~~~~~~~~~~~~~
     */

    /**
     * @notice Getter for bond details.
     * @param tokenId The tokenId to fetch info for.
     * @return bondDetails The bond details.
     */
    function bonds(uint256 tokenId) public view returns (OptionBond memory) {
        return _bonds[tokenId];
    }
}