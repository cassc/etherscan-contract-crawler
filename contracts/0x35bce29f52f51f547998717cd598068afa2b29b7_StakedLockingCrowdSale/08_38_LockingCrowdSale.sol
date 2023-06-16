// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { TimelockedToken } from "../TimelockedToken.sol";
import { CrowdSale, Sale } from "./CrowdSale.sol";

error UnsupportedInitializer();
error InvalidDuration();

/**
 * @title LockingCrowdSale
 * @author molecule.to
 * @notice a fixed price sales base contract that locks the sold tokens for a configurable duration
 */
contract LockingCrowdSale is CrowdSale {
    using SafeERC20 for IERC20Metadata;

    mapping(uint256 => uint256) public salesLockingDuration;

    /// @notice map from token address to reusable TimelockedToken contracts
    mapping(address => TimelockedToken) public lockingContracts;

    address immutable lockingTokenImplementation = address(new TimelockedToken());

    event Started(uint256 indexed saleId, address indexed issuer, Sale sale, TimelockedToken lockingToken, uint256 lockingDuration);
    event LockingContractCreated(TimelockedToken indexed lockingContract, IERC20Metadata indexed underlyingToken);

    /// @dev disable parent sale starting functions
    function startSale(Sale calldata) public pure override returns (uint256) {
        revert UnsupportedInitializer();
    }

    /**
     * @notice allows anyone to create a timelocked token that's controlled by this sale contract
     *         helpful if you want to reuse the timelocked token for your own custom schedules
     *         before having created any crowdsale on it.
     * @param underlyingToken the token a timelocked token contract is created for
     * @return lockedTokenContract the timelocked token contract either having been created or already existing
     */
    function createOrReturnTimelockContract(IERC20Metadata underlyingToken) public returns (TimelockedToken lockedTokenContract) {
        lockedTokenContract = lockingContracts[address(underlyingToken)];

        if (address(lockedTokenContract) == address(0)) {
            lockedTokenContract = _makeNewLockedTokenContract(underlyingToken);
            lockingContracts[address(underlyingToken)] = lockedTokenContract;
        }
    }

    /**
     * @notice will instantiate a new TimelockedToken when none exists yet
     *
     * @param sale sale configuration
     * @param lockingDuration duration after which the receiver can release their tokens
     * @return saleId the newly created sale's id
     */
    function startSale(Sale calldata sale, uint256 lockingDuration) public virtual returns (uint256 saleId) {
        saleId = uint256(keccak256(abi.encode(sale)));

        if (lockingDuration > 366 days) {
            revert InvalidDuration();
        }
        createOrReturnTimelockContract(sale.auctionToken);

        salesLockingDuration[saleId] = lockingDuration;
        saleId = super.startSale(sale);
    }

    function _afterSaleStarted(uint256 saleId) internal virtual override {
        emit Started(saleId, msg.sender, _sales[saleId], lockingContracts[address(_sales[saleId].auctionToken)], salesLockingDuration[saleId]);
    }

    function _afterSaleSettled(uint256 saleId) internal override {
        Sale storage sale = _sales[saleId];
        TimelockedToken lockingContract = lockingContracts[address(sale.auctionToken)];
        uint256 currentAllowance = sale.auctionToken.allowance(address(this), address(lockingContract));
        sale.auctionToken.forceApprove(address(lockingContract), currentAllowance + sale.salesAmount);
    }

    /**
     * @dev will send auction tokens to the configured timelock contract or release them directly when already past sale locking duration
     *
     * @param saleId sale id
     * @param tokenAmount amount of tokens to lock
     */
    function _claimAuctionTokens(uint256 saleId, uint256 tokenAmount) internal virtual override {
        uint256 duration = salesLockingDuration[saleId];
        TimelockedToken lockingContract = lockingContracts[address(_sales[saleId].auctionToken)];

        //the vesting start time is the official auction closing time
        if (block.timestamp > _sales[saleId].closingTime + duration) {
            //no need for vesting when cliff already expired.
            _sales[saleId].auctionToken.safeTransfer(msg.sender, tokenAmount);
        } else {
            lockingContract.lock(msg.sender, tokenAmount, SafeCast.toUint64(_sales[saleId].closingTime + duration));
        }
    }

    /**
     * @dev deploys a new timelocked token contract for the `auctionToken`
     *      to save on gas and improve UX, this is only called once per `auctionToken`
     * @param auctionToken the auction token that a timelocked token contract is created for
     * @return lockedTokenContract address of the new timelocked token contract
     */
    function _makeNewLockedTokenContract(IERC20Metadata auctionToken) private returns (TimelockedToken lockedTokenContract) {
        lockedTokenContract = TimelockedToken(Clones.clone(lockingTokenImplementation));
        lockedTokenContract.initialize(auctionToken);
        emit LockingContractCreated(lockedTokenContract, auctionToken);
    }
}