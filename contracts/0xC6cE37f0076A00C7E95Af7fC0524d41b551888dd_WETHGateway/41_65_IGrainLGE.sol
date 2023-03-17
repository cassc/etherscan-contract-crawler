// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IGrainLGE {

    /// @notice Allows a user to buy a share of the Grain LGE using {amount} of {token} and vesting for {numberOfReleases}
    /// @dev numberOfReleases has a max
    function buy(address token, uint256 amount, uint256 minUsdcAmountOut, uint256 numberOfReleases, address onBehalfOf) external returns (uint256 usdcValue, uint256 vestingPremium);

    function buy(address token, uint256 amount, uint256 minUsdcAmountOut, uint256 numberOfReleases, address onBehalfOf, address nft, uint256 nftId) external returns (uint256 usdcValue,uint256 vp);

    /// @notice Allows a user to claim all the tokens he can according to his share and the vesting duration he chose
    function claim() external returns (uint256 amountReleased);

    /// @notice Get how much GRAIN a user can claim
    // We may be able to get rid of this one as claim() and a static call can return the same value
    function pending(address user) external view returns (uint256 claimableAmount);

    /// @notice Get how much GRAIN a user is still owed by the end of his vesting
    function totalOwed(address user) external view returns (uint256 userTotal);

    /// @notice Get how much USDC has been raised
    function totalRaisedUsdc() external view returns (uint256 total);

    /// @notice Set how many grain are to be distributed across the buyers
    function setTotalChainShare(uint256 grainAmount) external;
}