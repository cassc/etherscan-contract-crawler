// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {SafeERC20, IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {OpenExchangeToken} from "./OpenExchangeToken.sol";
import {VotingEscrow} from "./VotingEscrow.sol";

/**
 * @title FlexMinter
 * @notice Contract for converting FLEX tokens to OX tokens at a 1 FLEX : 100 OX ratio.
 * @author opnxj
 */
contract FlexMinter is Ownable {
    using SafeERC20 for IERC20;

    OpenExchangeToken public immutable oxToken;
    VotingEscrow public immutable votingEscrow;
    IERC20 public immutable flexToken;

    uint256 public immutable oxMaxMintableSupply;
    uint256 public conversionDeadline; // Deadline for converting FLEX to OX
    uint256 public constant LOCK_DURATION = 91 days; // 3 months, 91 to be divisible by 7

    event ConversionDeadlineUpdated(uint256 newDeadline);

    error Error_ConversionDeadlinePassed();
    error Error_WillExceedMaxSupply();
    error Error_LockAlreadyExists();

    constructor(
        address _oxAddr,
        address _votingEscrowAddr,
        address _flexAddr,
        uint256 _conversionDeadline
    ) {
        oxToken = OpenExchangeToken(_oxAddr);
        votingEscrow = VotingEscrow(_votingEscrowAddr);
        flexToken = IERC20(_flexAddr);

        oxMaxMintableSupply = oxToken.MAX_MINTABLE_SUPPLY();

        conversionDeadline = _conversionDeadline;
        emit ConversionDeadlineUpdated(_conversionDeadline);
    }

    /**
     * @notice Sets a new conversion deadline.
     * @dev Only the contract owner can call this function.
     * @param newDeadline The new conversion deadline timestamp.
     */
    function setConversionDeadline(uint256 newDeadline) external onlyOwner {
        conversionDeadline = newDeadline;
        emit ConversionDeadlineUpdated(newDeadline);
    }

    /**
     * @notice Calculates the expected unlock time based on the given timestamp and the contract's fixed lock duration.
     * @dev The unlock time is calculated by adding the duration to the current epoch's end, which is rounded up to the
     *      nearest week. Thus the total lock duration will be 91 days < duration <= 98 days.
     * @param ts The timestamp for which to calculate the unlock time.
     * @return The expected unlock time based on the given timestamp.
     */
    function calculateExpectedUnlock(uint256 ts) public pure returns (uint256) {
        return ((ts / 1 weeks) + 1) * 1 weeks + LOCK_DURATION;
    }

    /**
     * @notice Mints veOX tokens by converting FLEX tokens at a 1 FLEX : 100 veOX ratio.
     * @dev The caller must have approved this contract to spend the specified amount of FLEX tokens.
     * @param amountFlex The amount of FLEX tokens to convert.
     * @dev User can only mint veOX with FLEX if there isn't an existing veOX balance.
     *      If there is an existing balance, the user should withdraw the expired lock
     *      first or transfer the FLEX to a fresh address to mint the new veOX.
     */
    function mintWithFlex(uint256 amountFlex) external {
        if (block.timestamp > conversionDeadline)
            revert Error_ConversionDeadlinePassed();

        uint256 amountOx = 100 * amountFlex;
        if (oxToken.totalSupply() + amountOx > oxMaxMintableSupply)
            revert Error_WillExceedMaxSupply();

        (int128 lockedAmount, ) = votingEscrow.locked(msg.sender);
        if (lockedAmount != 0) {
            revert Error_LockAlreadyExists();
        }

        flexToken.safeTransferFrom(msg.sender, address(this), amountFlex);

        uint256 expectedUnlock = calculateExpectedUnlock(block.timestamp);
        votingEscrow.create_lock_as_minter(
            msg.sender,
            amountOx,
            expectedUnlock
        );
    }
}