// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IFeeStrategy {
    /// @notice Address of the fee token.
    function feeToken() external view returns (IERC20Upgradeable);

    /// @notice Computes the fees while minting given amount of perp tokens.
    /// @dev The mint fee can be either positive or negative. When positive it's paid by the minting users to the reserve.
    ///      When negative its paid to the minting users by the reserve.
    ///      The protocol fee is always non-negative and is paid by the users minting to the
    ///      perp contract's fee collector.
    /// @param amount The amount of perp tokens to be minted.
    /// @return reserveFee The fee paid to the reserve to mint perp tokens.
    /// @return protocolFee The fee paid to the protocol to mint perp tokens.
    function computeMintFees(uint256 amount) external view returns (int256 reserveFee, uint256 protocolFee);

    /// @notice Computes the fees while burning given amount of perp tokens.
    /// @dev The burn fee can be either positive or negative. When positive it's paid by the burning users to the reserve.
    ///      When negative its paid to the burning users by the reserve.
    ///      The protocol fee is always non-negative and is paid by the users burning to the
    ///      perp contract's fee collector.
    /// @param amount The amount of perp tokens to be burnt.
    /// @return reserveFee The fee paid to the reserve to burn perp tokens.
    /// @return protocolFee The fee paid to the protocol to burn perp tokens.
    function computeBurnFees(uint256 amount) external view returns (int256 reserveFee, uint256 protocolFee);

    /// @notice Computes the fees while rolling over given amount of perp tokens.
    /// @dev The rollover fee can be either positive or negative. When positive it's paid by the users rolling over to the reserve.
    ///      When negative its paid to the users rolling over by the reserve.
    ///      The protocol fee is always positive and is paid by the users rolling over to the
    ///      perp contract's fee collector.
    /// @param amount The Perp-denominated value of the tranches being rolled over.
    /// @return reserveFee The fee paid to the reserve to rollover tokens.
    /// @return protocolFee The fee paid to the protocol to rollover tokens.
    function computeRolloverFees(uint256 amount) external view returns (int256 reserveFee, uint256 protocolFee);
}