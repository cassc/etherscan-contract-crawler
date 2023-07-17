// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import './IERC20.sol';
import './IERC5095.sol';
import './IJoin.sol';

interface IFYToken is IERC20, IERC5095 {
    /// @dev Asset that is returned on redemption.
    function base() external view returns (address);

    /// @dev Source of redemption funds.
    function join() external view returns (IJoin);

    /// @dev Unix time at which redemption of FYToken for base are possible
    function maturity() external view returns (uint256);

    /// @dev Record price data at maturity
    function mature() external;

    /// @dev Mint FYToken providing an equal amount of base to the protocol
    function mintWithbase(address to, uint256 amount) external;

    /// @dev Burn FYToken after maturity for an amount of base.
    function redeem(address to, uint256 amount) external returns (uint256);

    /// @dev Mint FYToken.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param to Wallet to mint the FYToken in.
    /// @param FYTokenAmount Amount of FYToken to mint.
    function mint(address to, uint256 FYTokenAmount) external;

    /// @dev Burn FYToken.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param from Wallet to burn the FYToken from.
    /// @param FYTokenAmount Amount of FYToken to burn.
    function burn(address from, uint256 FYTokenAmount) external;
}