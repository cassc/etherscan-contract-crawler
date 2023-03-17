// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./IFlaixGovernance.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IFlaixVault is IFlaixGovernance, IERC20Metadata {
    /// @notice Error code for when the new Admin is the null address
    error AdminCannotBeNull();

    /// @notice Error code for when a function is restricted for the admin.
    error OnlyAllowedForAdmin();

    /// @notice Error code for when the maturity is changed below the hard coded limit.
    error MaturityChangeBelowLimit();

    /// @notice Error code for when an option is issued with a maturity below the current minimum.
    error MaturityTooLow();

    /// @notice Error code for when a minter has minted all allowed shares.
    error MinterBudgetExceeded();

    /// @notice Error code for when an asset is already on the allow list.
    error AssetAlreadyOnAllowList();

    /// @notice Error code for when an asset is not on the allow list.
    error AssetNotOnAllowList();

    /// @notice Error code for when an asset is not on the allow list.
    error AssetCannotBeNull();

    /// @notice Error code for when index is after last asset in allow list.
    error AssetIndexOutOfBounds();

    /// @notice Error code for when an recipient is null.
    error RecipientCannotBeNullAddress();

    /// @notice Emitted when admin account is changed.
    event AdminChanged(address newAdmin, address oldAdmin);

    /// @notice Emitted when an asset is added to the allow list.
    event AssetAllowed(address asset);

    /// @notice Emitted when an asset is added to the allow list.
    event AssetDisallowed(address asset);

    /// @notice Emitted when call options are issued.
    event IssueCallOptions(
        address indexed options,
        address indexed recipient,
        string name,
        string symbol,
        uint256 amount,
        address indexed asset,
        uint256 assetAmount,
        uint256 maturity
    );

    /// @notice Emitted when put options are issued.
    event IssuePutOptions(
        address indexed options,
        address indexed recipient,
        string name,
        string symbol,
        uint256 amount,
        address indexed asset,
        uint256 assetAmount,
        uint256 maturity
    );

    /// @notice This function pertains to the minting budget of an account, and only allows
    ///         CallOptions or PutOptions to mint shares. The minting budget represents the
    ///         maximum number of shares that can be minted by the account, and is reduced by
    ///         the amount of shares that the account has already minted.
    /// @param minter The address of the account that is allowed to mint shares.
    /// @return uint The amount of shares that the account is allowed to mint.
    function minterBudgetOf(address minter) external view returns (uint);

    /// @notice This function burns shares from the sender and in exchange, sends the
    ///         recipient a proportional amount of each vault asset.
    /// @param amount The amount of shares to burn.
    /// @param recipient The address to send the vault assets to.
    function redeemShares(uint256 amount, address recipient) external;

    /// @notice Burns shares from the sender.
    /// @param amount The amount of shares to burn.
    function burn(uint256 amount) external;

    /// @notice Mints shares to the recipient. Minting shares is only possible
    ///         if the sender has a minting budget which is equal or greater than the amount.
    function mint(uint amount, address recipient) external;
}