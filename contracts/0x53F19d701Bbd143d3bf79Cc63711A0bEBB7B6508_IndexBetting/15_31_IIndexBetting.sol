// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.13;

import "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "./IIndexRouter.sol";
import "./IIndexHelper.sol";

interface IIndexBetting {
    /// @notice Initializes indexBetting
    /// @param _name Name of the index betting contract token
    /// @param _symbol Symbol of the index betting contract token
    /// @param _maxTVLAmountInBase Maximum amount of staking token in base units(6 decimals)
    function initialize(string calldata _name, string calldata _symbol, uint256 _maxTVLAmountInBase) external;

    /// @notice Deposits staking token
    /// @param _assets Amount of staking token to deposit
    function deposit(uint256 _assets) external;

    /// @notice Withdraws staked tokens and rewards
    function withdraw() external;

    /// @notice Mints PDI with deposited DPI and withdraws PDI with rewards
    /// @param _quotes Quotes to pass for conversion from DPI to PDI
    function withdrawAndMint(IIndexRouter.MintQuoteParams[] memory _quotes) external;

    /// @notice Swaps deposited DPI for PDI and withdraws PDI with rewards
    /// @param _swapTarget Address to execute swap
    /// @param _assetQuote Quote for swap execution
    /// @param _minBuyAmount Minimum amount of PDI to receive
    function withdrawAndSwap(address _swapTarget, bytes memory _assetQuote, uint256 _minBuyAmount) external;

    /// @notice Sets challenge outcome if it has ended
    function setChallengeOutcome() external;

    /// @notice Sets challenge outcome for a specific round id
    /// @dev Needed only for case when `setChallengeOutcome` was called but DPI price feed has not been updated after the epoch end
    function setChallengeOutcomeForRoundId() external;
}