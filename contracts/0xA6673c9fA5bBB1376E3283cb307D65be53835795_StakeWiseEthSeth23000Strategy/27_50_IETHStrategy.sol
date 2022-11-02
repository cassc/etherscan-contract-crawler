// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "../vault/IETHVault.sol";

/// @title IETHStrategy interface
interface IETHStrategy {

    /// @param _assets The address list of tokens borrow
    /// @param _amounts The amount list of tokens borrow
    event Borrow(address[] _assets, uint256[] _amounts);

    /// @param _withdrawShares The amount of shares to withdraw. Numerator
    /// @param _totalShares The total amount of shares owned by the strategy. Denominator
    /// @param _assets The address list of the assets repaying
    /// @param _amounts The amount list of the assets repaying
    event Repay(
        uint256 _withdrawShares,
        uint256 _totalShares,
        address[] _assets,
        uint256[] _amounts
    );

    /// @param _strategy The specified strategy emitted this event
    /// @param _rewards The address list of reward tokens
    /// @param _rewardAmounts The amount list of of reward tokens
    /// @param _wants The address list of wantted tokens
    /// @param _wantAmounts The amount list of wantted tokens
    event SwapRewardsToWants(
        address _strategy,
        address[] _rewards,
        uint256[] _rewardAmounts,
        address[] _wants,
        uint256[] _wantAmounts
    );

    /// @param _oldValue the old value of `isWantRatioIgnorable` flag
    /// @param _newValue the new value of `isWantRatioIgnorable` flag
    event SetIsWantRatioIgnorable(bool _oldValue, bool _newValue);

    /// @notice Return the version of strategy
    function getVersion() external pure returns (string memory);

    /// @notice Return the name of strategy
    function name() external view returns (string memory);

    /// @notice Return the ID of protocol, it marks which third protocol does this strategy belong to
    function protocol() external view returns (uint16);

    /// @notice Return the vault address
    function vault() external view returns (IETHVault);

    /// @notice Return the underlying token list and ratio list needed by the strategy
    /// @return _assets the address list of token to deposit
    /// @return _ratios the ratios list of `_assets`. 
    ///     The ratio is the proportion of each asset to total assets
    function getWantsInfo()
        external
        view
        returns (address[] memory _assets, uint256[] memory _ratios);

    /// @notice Return the underlying token list needed by the strategy
    function getWants() external view returns (address[] memory _wants);

    /// @notice Returns the position details of the strategy.
    /// @return _tokens The list of the position token
    /// @return _amounts The list of the position amount
    /// @return _isETH Whether to count in ETH
    /// @return _ethValue The ETH value of positions held
    function getPositionDetail()
        external
        view
        returns (
            address[] memory _tokens,
            uint256[] memory _amounts,
            bool _isETH,
            uint256 _ethValue
        );

    /// @notice Return the total assets of strategy in ETH.
    function estimatedTotalAssets() external view returns (uint256);

    /// @notice Return the 3rd protocol's pool total assets in ETH.
    function get3rdPoolAssets() external view returns (uint256);

    /// @notice Harvests by the Strategy, 
    ///     recognizing any profits or losses and adjusting the Strategy's position.
    /// @return _rewardsTokens The list of the reward token
    /// @return _claimAmounts The list of the reward amount claimed
    function harvest() external returns (address[] memory _rewardsTokens, uint256[] memory _claimAmounts);

    /// @notice Strategy borrow funds from vault, 
    ///     enable payable because it needs to receive ETH from vault
    /// @param _assets borrow token address
    /// @param _amounts borrow token amount
    function borrow(address[] memory _assets, uint256[] memory _amounts) external payable;

    /// @notice Strategy repay the funds to ETH vault
    /// @param _withdrawShares The amount of shares to withdraw
    /// @param _totalShares The total amount of shares owned by this strategy
    /// @param _outputCode The code of output
    /// @return _assets The address list of the assets repaying
    /// @return _amounts The amount list of the assets repaying
    function repay(
        uint256 _withdrawShares,
        uint256 _totalShares,
        uint256 _outputCode
    ) external returns (address[] memory _assets, uint256[] memory _amounts);

    /// @notice Return the boolean value of `isWantRatioIgnorable`
    function isWantRatioIgnorable() external view returns (bool);
}