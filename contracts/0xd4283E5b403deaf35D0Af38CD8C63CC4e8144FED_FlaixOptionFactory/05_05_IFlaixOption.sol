// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

interface IFlaixOption is IERC20MetadataUpgradeable {
    /// @notice Error emitted when the option contract is not matured yet.
    error OptionNotMaturedYet();

    /// @notice Emitted when this option contract is issued.
    event Issue(address indexed recipient, uint256 amount, uint maturityTimestamp);

    /// @notice Emitted when this option contract is exercised.
    event Exercise(address indexed recipient, uint256 amount, uint256 assetAmount);

    /// @notice Emitted when this option contract is revoked.
    event Revoke(address indexed recipient, uint256 amount);

    /// @notice Initializes the option contract.
    function initialize(
        string memory name,
        string memory symbol,
        address asset_,
        address minter_,
        address vault_,
        uint256 totalSupply_,
        uint maturityTimestamp_
    ) external;

    /// @notice Returns the address of the vault that issued the options.
    function vault() external view returns (address);

    /// @notice Returns the timestamp when the options mature.
    function maturityTimestamp() external view returns (uint);

    /// @notice Returns the address of the underlying asset.
    function asset() external view returns (address);

    /// @notice This function should implement the logic to exercise the given
    ///         amount of options and transfer the result to the recipient.
    function exercise(uint256 amount, address recipient) external;

    /// @notice Returns the amount of underlying assets for the given amount of
    ///         options.
    function convertToAssets(uint256 amount) external view returns (uint256);

    /// @notice Revoke the given amount of options and transfers the result to
    ///         the recipient.
    function revoke(uint256 amount, address recipient) external;
}