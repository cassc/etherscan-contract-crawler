// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { FixedPointMathLib } from "solmate/utils/FixedPointMathLib.sol";
import { TokenVesting } from "@moleculeprotocol/token-vesting/TokenVesting.sol";
import { TimelockedToken } from "../TimelockedToken.sol";
import { LockingCrowdSale, UnsupportedInitializer, InvalidDuration } from "./LockingCrowdSale.sol";
import { CrowdSale, Sale, BadDecimals } from "./CrowdSale.sol";

struct StakingInfo {
    //e.g. VITA DAO token
    IERC20Metadata stakedToken;
    TokenVesting stakesVestingContract;
    //fix price (always expressed at 1e18): stake tokens / bid token
    //see https://github.com/moleculeprotocol/IPNFT/pull/100
    uint256 wadFixedStakedPerBidPrice;
}

error IncompatibleVestingContract();
error UnmanageableVestingContract();
error UnsupportedVestingContract();
error BadPrice();

/**
 * @title StakedLockingCrowdSale
 * @author molecule.to
 * @notice a fixed price sales contract that locks the sold tokens in a configured locking contract and requires vesting another ("dao") token for a certain period of time to participate
 * @dev see https://github.com/moleculeprotocol/IPNFT
 */
contract StakedLockingCrowdSale is LockingCrowdSale, Ownable {
    using SafeERC20 for IERC20Metadata;
    using FixedPointMathLib for uint256;

    mapping(uint256 => StakingInfo) public salesStaking;
    mapping(uint256 => mapping(address => uint256)) internal stakes;
    mapping(address => bool) public trustedVestingContracts;

    event Started(
        uint256 indexed saleId,
        address indexed issuer,
        Sale sale,
        StakingInfo staking,
        TimelockedToken lockingToken,
        uint256 lockingDuration,
        uint256 stakingDuration
    );
    event Staked(uint256 indexed saleId, address indexed bidder, uint256 stakedAmount, uint256 price);
    event ClaimedStakes(uint256 indexed saleId, address indexed claimer, uint256 stakesClaimed, uint256 stakesRefunded);
    event UpdatedTrustedTokenVestings(TokenVesting indexed tokenVesting, bool trusted);

    /// @dev disable parent sale starting functions
    function startSale(Sale calldata, uint256) public pure override returns (uint256) {
        revert UnsupportedInitializer();
    }

    constructor() Ownable() { }

    /**
     * [H-01]
     * @notice this contract can only vest stakes for contracts that it knows so unknown actors cannot start crowdsales with malicious contracts
     * @param stakesVestingContract the TokenVesting contract to trust
     */
    function trustVestingContract(TokenVesting stakesVestingContract) external onlyOwner {
        if (!stakesVestingContract.hasRole(stakesVestingContract.ROLE_CREATE_SCHEDULE(), address(this))) {
            revert UnmanageableVestingContract();
        }
        trustedVestingContracts[address(stakesVestingContract)] = true;
        emit UpdatedTrustedTokenVestings(stakesVestingContract, true);
    }

    function untrustVestingContract(TokenVesting stakesVestingContract) external onlyOwner {
        trustedVestingContracts[address(stakesVestingContract)] = false;
        emit UpdatedTrustedTokenVestings(stakesVestingContract, false);
    }

    /**
     * @notice starts a new crowdsale
     * @param sale sale configuration (see CrowdSale.sol)
     * @param stakedToken the ERC20 contract for staking tokens
     * @param stakesVestingContract the TokenVesting contract for vested staking tokens. Will revert when not trusted.
     * @param wadFixedStakedPerBidPrice the 10e18 based float price for stakes/bid tokens
     * @param lockingDuration duration in seconds until stakes and auction tokens are vested or locked after the sale has settled
     *        NOTE: If `lockingDuration` is < 7 days, the the vesting contract schedules will stil have a 7 days cliff as required by the underlying TokenVesting contract.
     *        timelocks for auction tokens can be >= 0
     * @return saleId
     */
    function startSale(
        Sale calldata sale,
        IERC20Metadata stakedToken,
        TokenVesting stakesVestingContract,
        uint256 wadFixedStakedPerBidPrice,
        uint256 lockingDuration
    ) public returns (uint256 saleId) {
        if (IERC20Metadata(address(stakedToken)).decimals() != 18) {
            revert BadDecimals();
        }

        // [H-01] we only open crowdsales with vesting contracts that we trust
        if (!trustedVestingContracts[address(stakesVestingContract)]) {
            revert UnsupportedVestingContract();
        }

        if (address(stakesVestingContract.nativeToken()) != address(stakedToken)) {
            revert IncompatibleVestingContract();
        }

        if (wadFixedStakedPerBidPrice == 0) {
            revert BadPrice();
        }

        //if the bidding token (eg USDC) does not come with 18 decimals, we're adjusting the price here.
        //see https://github.com/moleculeprotocol/IPNFT/pull/100
        if (sale.biddingToken.decimals() != 18) {
            wadFixedStakedPerBidPrice = (wadFixedStakedPerBidPrice * 10 ** 18) / 10 ** sale.biddingToken.decimals();
        }

        saleId = uint256(keccak256(abi.encode(sale)));
        salesStaking[saleId] = StakingInfo(stakedToken, stakesVestingContract, wadFixedStakedPerBidPrice);
        super.startSale(sale, lockingDuration);
    }

    /**
     * @return uint256 how many stakingTokens `bidder` has staked into sale `saleId`
     */
    function stakesOf(uint256 saleId, address bidder) external view returns (uint256) {
        return stakes[saleId][bidder];
    }

    /**
     * @dev emits a custom event for this crowdsale class
     */
    function _afterSaleStarted(uint256 saleId) internal virtual override {
        uint256 stakingDuration = salesLockingDuration[saleId] < 7 days ? 7 days : salesLockingDuration[saleId];
        emit Started(
            saleId,
            msg.sender,
            _sales[saleId],
            salesStaking[saleId],
            lockingContracts[address(_sales[saleId].auctionToken)],
            salesLockingDuration[saleId],
            stakingDuration
        );
    }

    /**
     * @dev computes stake returns for a bidder
     *
     * @param saleId sale id
     * @param refunds amount of bidding tokens being refunded
     * @return refundedStakes wei value of refunded staking tokens
     * @return vestedStakes wei value of staking tokens returned wrapped as vesting tokens
     */
    function getClaimableStakes(uint256 saleId, uint256 refunds) public view virtual returns (uint256 refundedStakes, uint256 vestedStakes) {
        StakingInfo storage staking = salesStaking[saleId];

        refundedStakes = refunds.mulWadDown(staking.wadFixedStakedPerBidPrice);
        vestedStakes = stakes[saleId][msg.sender] - refundedStakes;
    }

    /**
     * @dev calculates the amount of required staking tokens using the provided fix price
     *      will revert if bidder hasn't approved / owns a sufficient amount of staking tokens
     */
    function _bid(uint256 saleId, uint256 biddingTokenAmount) internal virtual override {
        StakingInfo storage staking = salesStaking[saleId];

        uint256 stakedTokenAmount = biddingTokenAmount.mulWadDown(staking.wadFixedStakedPerBidPrice);

        stakes[saleId][msg.sender] += stakedTokenAmount;

        staking.stakedToken.safeTransferFrom(msg.sender, address(this), stakedTokenAmount);

        super._bid(saleId, biddingTokenAmount);
        emit Staked(saleId, msg.sender, stakedTokenAmount, staking.wadFixedStakedPerBidPrice);
    }

    /**
     * @notice refunds stakes and locks active stakes in vesting contract
     * @dev super.claim transitively calls LockingCrowdSale:_claimAuctionTokens
     * @inheritdoc CrowdSale
     */
    function claim(uint256 saleId, uint256 tokenAmount, uint256 refunds) internal virtual override {
        uint256 duration = salesLockingDuration[saleId];
        StakingInfo storage staking = salesStaking[saleId];
        (uint256 refundedStakes, uint256 vestedStakes) = getClaimableStakes(saleId, refunds);

        //EFFECTS
        //this prevents msg.sender to claim twice
        stakes[saleId][msg.sender] = 0;

        // INTERACTIONS
        super.claim(saleId, tokenAmount, refunds);

        if (refundedStakes != 0) {
            staking.stakedToken.safeTransfer(msg.sender, refundedStakes);
        }

        emit ClaimedStakes(saleId, msg.sender, vestedStakes, refundedStakes);

        if (vestedStakes == 0) {
            return;
        }

        //the minimum vesting duration of `TokenVesting` is 7 days
        uint256 _duration = duration < 7 days ? 7 days : duration;
        if (block.timestamp > _sales[saleId].closingTime + _duration) {
            //no need for vesting when duration already expired.
            staking.stakedToken.safeTransfer(msg.sender, vestedStakes);
        } else {
            staking.stakedToken.safeTransfer(address(staking.stakesVestingContract), vestedStakes);
            staking.stakesVestingContract.createVestingSchedule(msg.sender, _sales[saleId].closingTime, _duration, _duration, 60, false, vestedStakes);
        }
    }

    /**
     * @notice will additionally charge back all staked tokens
     * @inheritdoc CrowdSale
     */
    function claimFailed(uint256 saleId) internal override returns (uint256 auctionTokens, uint256 refunds) {
        uint256 refundableStakes = stakes[saleId][msg.sender];
        stakes[saleId][msg.sender] = 0;

        (auctionTokens, refunds) = super.claimFailed(saleId);
        emit ClaimedStakes(saleId, msg.sender, 0, refundableStakes);

        salesStaking[saleId].stakedToken.safeTransfer(msg.sender, refundableStakes);
    }
}