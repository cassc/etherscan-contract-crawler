// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

interface IETHStrategy {
    event Borrow(address[] _assets, uint256[] _amounts);
    event Repay(
        uint256 _withdrawShares,
        uint256 _totalShares,
        address[] _assets,
        uint256[] _amounts
    );
    event SetIsWantRatioIgnorable(bool _oldValue, bool _newValue);

    /// @notice Version of strategy
    function getVersion() external pure returns (string memory);

    /// @notice Name of strategy
    function name() external pure returns (string memory);

    /// @notice ID of protocol, it marks which third protocol does this strategy belong to
    function protocol() external pure returns (uint16);

    /// @notice Vault address
    function vault() external view returns (address);

    /// @notice Provide the strategy need underlying token and ratio
    function getWantsInfo()
        external
        view
        returns (address[] memory _assets, uint256[] memory _ratios);

    /// @notice Provide the strategy need underlying token
    function getWants() external view returns (address[] memory _wants);

    /// @notice Returns the position details or ETH value of the strategy.
    function getPositionDetail()
        external
        view
        returns (
            address[] memory _tokens,
            uint256[] memory _amounts,
            bool _isETH,
            uint256 _ethValue
        );

    /// @notice Total assets of strategy in ETH.
    function estimatedTotalAssets() external view returns (uint256);

    /// @notice 3rd protocol's pool total assets in ETH.
    function get3rdPoolAssets() external view returns (uint256);

    /// @notice Harvests the Strategy, recognizing any profits or losses and adjusting the Strategy's position.
    function harvest() external returns (address[] memory _rewardsTokens, uint256[] memory _claimAmounts);

    /// @notice Strategy borrow funds from vault, enable payable because it needs to receive ETH from vault
    /// @param _assets borrow token address
    /// @param _amounts borrow token amount
    function borrow(address[] memory _assets, uint256[] memory _amounts) external payable;

    /// @notice Strategy repay the funds to vault
    /// @param _withdrawShares Numerator
    /// @param _totalShares Denominator
    function repay(
        uint256 _withdrawShares,
        uint256 _totalShares,
        uint256 _ouputCode
    ) external returns (address[] memory _assets, uint256[] memory _amounts);

    /// @notice getter isWantRatioIgnorable
    function isWantRatioIgnorable() external view returns (bool);
}