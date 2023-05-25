// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface IAntfarmPairDerivedState {
    /// @notice Get position LP tokens
    /// @param operator Position owner
    /// @param positionId ID of the position
    /// @return uint128 LP tokens owned by the operator
    function getPositionLP(address operator, uint256 positionId)
        external
        view
        returns (uint128);

    /// @notice Get pair reserves
    /// @return reserve0 Reserve for token0
    /// @return reserve1 Reserve for token1
    /// @return blockTimestampLast Last block proceeded
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    /// @notice Get Dividend from a specific position
    /// @param operator The address used to get dividends
    /// @param positionId Specific position
    /// @return amount Dividends owned by the address
    function claimableDividends(address operator, uint256 positionId)
        external
        view
        returns (uint256 amount);
}