// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "../dependencies/openzeppelin/contracts/IERC20.sol";

interface IP2PPairStaking {
    enum StakingType {
        BAYCStaking,
        MAYCStaking,
        BAKCPairStaking
    }

    enum ListingOrderStatus {
        Pending,
        Matched,
        Cancelled
    }

    struct ListingOrder {
        StakingType stakingType;
        address offerer;
        address token;
        uint32 tokenId;
        uint32 share;
        uint256 startTime;
        uint256 endTime;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct MatchedOrder {
        StakingType stakingType;
        address apeToken;
        uint32 apeTokenId;
        uint32 apeShare;
        uint32 bakcTokenId;
        uint32 bakcShare;
        address apeCoinOfferer;
        uint32 apeCoinShare;
        uint256 apePrincipleAmount;
        bytes32 apeCoinListingOrderHash;
    }

    /**
     * @dev Emit an event whenever an listing order is successfully cancelled.
     * @param orderHash The hash of the cancelled order.
     * @param offerer   The offerer of the cancelled order.
     */
    event OrderCancelled(bytes32 orderHash, address indexed offerer);

    /**
     * @dev Emitted when a order matched.
     * @param orderHash The hash of the matched order
     **/
    event PairStakingMatched(bytes32 orderHash);

    /**
     * @dev Emitted when a matched order break up.
     * @param orderHash The hash of the break up order
     **/
    event PairStakingBreakUp(bytes32 orderHash);

    /**
     * @dev Emitted when user claimed pending cApe reward.
     * @param user The address of the user
     * @param receiver The address of the cApe receiver
     * @param amount The amount of the cApe been claimed
     **/
    event CApeClaimed(address user, address receiver, uint256 amount);

    /**
     * @dev Emitted when we claimed pending reward for matched order and compound.
     * @param orderHash The hash of the break up order
     **/
    event OrderClaimedAndCompounded(bytes32 orderHash, uint256 totalReward);

    /**
     * @dev Emitted during rescueERC20()
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount being rescued
     **/
    event RescueERC20(
        address indexed token,
        address indexed to,
        uint256 amount
    );

    /**
     * @dev Emitted during setMatchingOperator()
     * @param oldOperator The address of the old matching operator
     * @param newOperator The address of the new matching operator
     **/
    event MatchingOperatorUpdated(address oldOperator, address newOperator);

    /**
     * @dev Emitted during setCompoundFee()
     * @param oldFee The value of the old compound fee
     * @param newFee The value of the new compound fee
     **/
    event CompoundFeeUpdated(uint256 oldFee, uint256 newFee);

    /**
     * @notice Cancel a listing order, order canceled cannot be matched.
     * @param listingOrder the detail info of the order to be canceled
     */
    function cancelListing(ListingOrder calldata listingOrder) external;

    /**
     * @notice match an apeOrder with an apeCoinOrder to pair staking
     * @param apeOrder the ape owner's listing order
     * @param apeCoinOrder the Ape Coin owner's listing order
     * @return orderHash matched order hash
     */
    function matchPairStakingList(
        ListingOrder calldata apeOrder,
        ListingOrder calldata apeCoinOrder
    ) external returns (bytes32 orderHash);

    /**
     * @notice match an apeOrder, an bakcOrder with an apeCoinOrder to pair staking
     * @param apeOrder the ape owner's listing order
     * @param bakcOrder the bakc owner's listing order
     * @param apeCoinOrder the Ape Coin owner's listing order
     * @return orderHash matched order hash
     */
    function matchBAKCPairStakingList(
        ListingOrder calldata apeOrder,
        ListingOrder calldata bakcOrder,
        ListingOrder calldata apeCoinOrder
    ) external returns (bytes32 orderHash);

    /**
     * @notice break up an matched pair staking order, only participant of the matched order can call.
     * @param orderHash the hash of the matched order to be break up
     */
    function breakUpMatchedOrder(bytes32 orderHash) external;

    /**
     * @notice claim pending reward for matched pair staking orders and deposit as cApe for user to compound.
     * @param orderHashes the hash of the matched orders to be break up
     */
    function claimForMatchedOrderAndCompound(bytes32[] calldata orderHashes)
        external;

    /**
     * @param user The address of the user
     * @return amount Returns the amount of cApe owned by user
     */
    function pendingCApeReward(address user)
        external
        view
        returns (uint256 amount);

    /**
     * @notice claim user compounded cApe
     * @param receiver The address of the cApe receiver
     */
    function claimCApeReward(address receiver) external;

    /**
     * @notice get Ape Coin Staking cap for every position.
     * @param stakingType the pair staking type
     * @return Ape Coin Staking cap
     */
    function getApeCoinStakingCap(StakingType stakingType)
        external
        returns (uint256);

    /**
     * @notice set a new matching operator, only owner can call this function
     * @param _matchingOperator The address of the new matching operator
     */
    function setMatchingOperator(address _matchingOperator) external;
}