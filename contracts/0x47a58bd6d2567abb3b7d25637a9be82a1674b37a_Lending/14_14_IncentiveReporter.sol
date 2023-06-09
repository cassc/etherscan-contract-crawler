library IncentiveReporter {
    event AddToClaim(address topic, address indexed claimant, uint256 amount);
    event SubtractFromClaim(
        address topic,
        address indexed claimant,
        uint256 amount
    );

    /// Start / increase amount of claim
    function addToClaimAmount(
        address topic,
        address recipient,
        uint256 claimAmount
    ) internal {
        emit AddToClaim(topic, recipient, claimAmount);
    }

    /// Decrease amount of claim
    function subtractFromClaimAmount(
        address topic,
        address recipient,
        uint256 subtractAmount
    ) internal {
        emit SubtractFromClaim(topic, recipient, subtractAmount);
    }
}