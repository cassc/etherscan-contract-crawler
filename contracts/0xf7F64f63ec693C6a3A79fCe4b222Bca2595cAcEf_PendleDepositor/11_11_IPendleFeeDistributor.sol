pragma solidity 0.8.7;

interface IPendleFeeDistributor {
    // ========================= STRUCT =========================
    struct UpdateProtocolStruct {
        address user;
        bytes32[] proof;
        address[] pools;
        uint256[] topUps;
    }

    // ========================= EVENTS =========================
    /// @notice Emit when a new merkleRoot is set & the fee is funded by the governance
    event SetMerkleRootAndFund(bytes32 indexed merkleRoot, uint256 amountFunded);

    /// @notice Emit when an user claims their fees
    event Claimed(address indexed user, uint256 amountOut);

    /// @notice Emit when the Pendle team populates data for a protocol
    event UpdateProtocolClaimable(address indexed user, uint256 sumTopUp);

    // ========================= FUNCTIONS =========================
    /**
     * @notice Submit total fee and proof to claim outstanding amount. Fee will be sent as raw ETH,
     so receiver should be an EOA or have receive() function.
     */
    function claimRetail(
        address receiver,
        uint256 totalAccrued,
        bytes32[] calldata proof
    ) external returns (uint256 amountOut);

    /**
    * @notice Claim all outstanding fees for the specified pools. This function is intended for use
    by protocols that have contacted the Pendle team. Note that the fee will be sent in raw ETH,
    so the receiver should be an EOA or have a receive() function.
    * @notice Protocols should not use claimRetail, as it can make getProtocolFeeData unreliable.
     */
    function claimProtocol(address receiver, address[] calldata pools)
        external
        returns (uint256 totalAmountOut, uint256[] memory amountsOut);

    ///@notice Returns the claimable fees per pool. This function is only available if the Pendle
    ///team has specifically set up the data.
    function getProtocolClaimables(address user, address[] calldata pools)
        external
        view
        returns (uint256[] memory claimables);

    ///@notice Returns the lifetime totalAccrued fees for protocols. This function is only available
    ///if the Pendle team has specifically set up the data.
    function getProtocolTotalAccrued(address user) external view returns (uint256);
}