// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

interface IClaimEmitter {
    /// @notice some liquidity has been claimed as principal plus interests or share of liquidation
    /// @param claimant who received the liquidity
    /// @param claimed amount sent
    /// @param loanId loan identifier where the claim rights come from
    event Claim(address indexed claimant, uint256 indexed claimed, uint256 indexed loanId);
}

interface IClaimFacet is IClaimEmitter {
    function claim(uint256[] calldata positionIds) external returns (uint256 sent);

    function claimAsBorrower(uint256[] calldata loanIds) external returns (uint256 sent);
}