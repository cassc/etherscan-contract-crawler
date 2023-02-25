// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IRTriV2.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Escrow contract for users to claim USDC fractionally, according to their
 *        share of the Aequinox USDC/USDT/BUSD gauge
 * @author Kama#3842, Prisma Shield, https://prismashield.com
 * @notice The Vertek team sends USDC directly to this contract, and users simply
 *         call the claim() function to receive their portion based on their rTriV2
 *         balance. Any USDC added to this contract will always be available for users
 *         to claim, so there is no rush to claim. The fewer times you claim, the more
 *         gas you save
 */
contract Escrow {
    IERC20 public constant USDC =
        IERC20(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d);
    IERC20 public immutable RTRIV2;
    uint256 public constant RTRIV2_TOTAL_SUPPLY_INITIAL = 587000e18;

    /**
     * @notice totalUsdcAddedExcludingNewlyAddedUsdc contains the total amount of USDC
     *         that has been sent to this contract excluding any newly added USDC
     */
    uint256 public totalUsdcAddedExcludingNewlyAddedUsdc;
    /**
     * @notice totalUsdcLeftToAddExcludingNewlyAddedUsdc contains he total amount of USDC
     *         that still needs to be sent to this contract (excluding any newly added
     *         USDC) to complete the refund
     */
    int256 public totalUsdcLeftToAddExcludingNewlyAddedUsdc = 587000e18;
    /**
     * @notice totalAccumulatedPerShare contains the ratio of USDC added to this contract
     *         over the total amount of rTriV2 tokens, which is used to calculate how much
     *         USDC each user can claim based on their rTriV2 balance
     */
    uint256 public totalAccumulatedPerShare;
    /**
     * @notice totalUsdcClaimed contains the total amount of USDC that has been claimed
     *         so far
     */
    uint256 public totalUsdcClaimed;
    /**
     * @notice claimedPerUser contains the amount of USDC claimed by each user so far
     */
    mapping(address => uint256) public claimedPerUser;
    /**
     * @notice rTriV2InitialPerUser contains the initial RTriV2 balance for each user
     */
    mapping(address => uint256) public rTriV2InitialPerUser;

    event USDCAddedToEscrow(
        uint256 newAmountAdded,
        uint256 totalAmountAdded,
        int256 amountLeftToAddToCompleteRefund
    );
    event USDCClaimed(
        address indexed user,
        uint256 userAmountClaimed,
        uint256 userTotalClaimed,
        int256 userAmountLeftToClaimToCompleteRefund
    );

    constructor(IERC20 rTriV2) {
        RTRIV2 = rTriV2;
    }

    /**
     * @notice Claim any USDC you are owed from what is added to this contract
     * @dev Stores the user's initial RTriV2 balance, and updates the state for
     *      any newly added USDC before claiming. This allows sending USDC directly
     *      to this contract without having to call any extra functions. All USDC
     *      sent to this contract is fairly claimable by all users with RTriV2 tokens
     */
    function claim() external {
        if (
            rTriV2InitialPerUser[msg.sender] == 0 &&
            RTRIV2.balanceOf(msg.sender) != 0
        ) {
            rTriV2InitialPerUser[msg.sender] = RTRIV2.balanceOf(msg.sender);
        }
        uint256 rTriV2UserBalance = rTriV2InitialPerUser[msg.sender];

        // Update totalAccumulatedPerShare for any new USDC added
        (
            uint256 toAddToTotalAccumulatedPerShare,
            uint256 newUsdcAdded
        ) = addableToTotalAccumulatedPerShare();
        if (toAddToTotalAccumulatedPerShare > 0) {
            totalAccumulatedPerShare += toAddToTotalAccumulatedPerShare;
            emit USDCAddedToEscrow(
                newUsdcAdded,
                totalUsdcAddedExcludingNewlyAddedUsdc += newUsdcAdded,
                totalUsdcLeftToAddExcludingNewlyAddedUsdc -= int256(
                    newUsdcAdded
                )
            );
        }

        // Calculate how much USDC is owed and send it to the user
        uint256 newUserClaimed = (rTriV2UserBalance *
            totalAccumulatedPerShare) / 1e18;
        uint256 claimed = claimedPerUser[msg.sender];
        require(newUserClaimed > claimed, "Escrow: nothing to claim");
        uint256 amtToUser = newUserClaimed - claimed;
        if (amtToUser > USDC.balanceOf(address(this))) {
            amtToUser = USDC.balanceOf(address(this));
        }
        USDC.transfer(msg.sender, amtToUser);
        uint256 amtToBurn = amtToUser;
        if (amtToBurn > RTRIV2.balanceOf(msg.sender)) {
            amtToBurn = RTRIV2.balanceOf(msg.sender);
        }
        IRTriV2(address(RTRIV2)).burn(msg.sender, amtToBurn);
        emit USDCClaimed(
            msg.sender,
            amtToUser,
            newUserClaimed,
            int256(rTriV2UserBalance) - int(newUserClaimed)
        );
        totalUsdcClaimed += amtToUser;
        claimedPerUser[msg.sender] = newUserClaimed;
    }

    /**
     * @notice Check how much USDC the user address can claim
     * @param user Address of the user to check how much USDC they can claim
     * @dev This is a convenience function to display the amount of USDC claimable for
     *      users in the UI
     */
    function userClaimable(address user) public view returns (uint256) {
        uint256 rTriV2UserBalance = rTriV2InitialPerUser[user];
        if (rTriV2UserBalance == 0 && RTRIV2.balanceOf(user) != 0) {
            rTriV2UserBalance = RTRIV2.balanceOf(user);
        }
        (
            uint256 toAddToTotalAccumulatedPerShare,

        ) = addableToTotalAccumulatedPerShare();
        uint256 newTotalAccumulatedPerShare = totalAccumulatedPerShare +
            toAddToTotalAccumulatedPerShare;
        uint256 userTotalToClaim = (rTriV2UserBalance *
            newTotalAccumulatedPerShare) / 1e18;
        uint256 claimed = claimedPerUser[user];
        if (claimed >= userTotalToClaim) {
            return 0;
        }
        return userTotalToClaim - claimed;
    }

    /**
     * @notice Calculates how much new USDC is added to this contract, and what
     *         should be added to totalAccumulatedPerShare
     * @return toAddToTotalAccumulatedPerShare How much should be added to
     *         totalAccumulatedPerShare
     * @return addedUsdc The amount of newly added USDC that has not yet been
     *                   accounted for in totalAccumulatedPerShare (it will be once
     *                   any user claims)
     */
    function addableToTotalAccumulatedPerShare()
        public
        view
        returns (uint256 toAddToTotalAccumulatedPerShare, uint256 addedUsdc)
    {
        uint256 toClaim = totalClaimableExcludingNewlyAddedUsdc();
        uint256 usdcBalance = USDC.balanceOf(address(this));
        if (toClaim >= usdcBalance) {
            return (0, 0);
        }
        addedUsdc = usdcBalance - toClaim;
        return ((addedUsdc * 1e18) / RTRIV2_TOTAL_SUPPLY_INITIAL, addedUsdc);
    }

    /**
     * @notice The total amount of USDC claimable, excluding any newly added USDC
     */
    function totalClaimableExcludingNewlyAddedUsdc()
        public
        view
        returns (uint256)
    {
        uint256 toClaim = (RTRIV2_TOTAL_SUPPLY_INITIAL *
            totalAccumulatedPerShare) / 1e18;
        if (totalUsdcClaimed >= toClaim) {
            return 0;
        }
        return toClaim - totalUsdcClaimed;
    }

    /**
     * @notice The total amount of USDC claimable, including any newly added USDC
     * @dev This is a convenience function to display the total amount of USDC claimable
     *      for users in the UI
     */
    function totalClaimableIncludingNewlyAddedUsdc()
        public
        view
        returns (uint256)
    {
        (
            uint256 toAddToTotalAccumulatedPerShare,

        ) = addableToTotalAccumulatedPerShare();
        uint256 newTotalAccumulatedPerShare = totalAccumulatedPerShare +
            toAddToTotalAccumulatedPerShare;
        uint256 totalToClaim = (RTRIV2_TOTAL_SUPPLY_INITIAL *
            newTotalAccumulatedPerShare) / 1e18;
        if (totalUsdcClaimed >= totalToClaim) {
            return 0;
        }
        return totalToClaim - totalUsdcClaimed;
    }

    /**
     * @notice The total amount of USDC that has been sent to this contract
     * @dev This is a convenience function to display the total amount of USDC that
     *      has been added to this contract in the UI
     */
    function totalUsdcAddedIncludingNewlyAddedUsdc()
        external
        view
        returns (uint256)
    {
        (, uint256 newUsdcAdded) = addableToTotalAccumulatedPerShare();
        return totalUsdcAddedExcludingNewlyAddedUsdc + newUsdcAdded;
    }

    /**
     * @notice The total amount of USDC that still needs to be sent to this contract to
     *         complete the refund
     * @dev This is a convenience function to display the remaining amount of USDC left
     *      to add to this contract to complete the refund in the UI
     */
    function totalUsdcLeftToAddIncludingNewlyAddedUsdc()
        external
        view
        returns (int256)
    {
        (, uint256 newUsdcAdded) = addableToTotalAccumulatedPerShare();
        return totalUsdcLeftToAddExcludingNewlyAddedUsdc - int256(newUsdcAdded);
    }
}