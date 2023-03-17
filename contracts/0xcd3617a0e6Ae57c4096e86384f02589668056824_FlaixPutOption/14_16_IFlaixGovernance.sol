// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IFlaixGovernance {
    /// @notice Returns the address of the admin account. The admin account should be replaced
    ///         by a multisig contract or even better a DAO in the future.
    /// @return address The address of the admin account.
    function admin() external view returns (address);

    /// @notice Returns the minimal options maturity. When an option is issued, the issuer selects a maturity value, which is the
    /// point in time when the option can be exercised. The maturity period must be a
    /// minimum of three days, but the admin account has the ability to adjust the
    /// minimum maturity period.
    /// @return uint The minimal options maturity.
    function minimalOptionsMaturity() external view returns (uint);

    /// @notice Changes the minimal options maturity. The minimal options maturity is the minimal maturity of options
    ///         that can be issued by the vault.
    /// @param newMaturity The new minimal options maturity.
    function changeMinimalOptionsMaturity(uint newMaturity) external;

    /// @notice Changes the admin account of the vault. This function can only be called by
    ///         the previous admin account.
    /// @param newAdmin The new admin account.
    function changeAdmin(address newAdmin) external;

    /// @notice Adds an asset to the allowed asset list of the vault
    /// @param assetAddress The address of the asset to add to the allowed asset list.
    function allowAsset(address assetAddress) external;

    /// @notice This function removes an asset from the vault's list of allowed assets. It is
    ///         important to note that this action only prevents new assets from being added
    ///         to the vault, and does not remove any existing assets or the right to
    ///         withdraw existing assets.
    /// @param assetAddress  The address of the asset to remove from the allowed asset list.
    function disallowAsset(address assetAddress) external;

    /// @notice Checks if a certain asset is allowed to be added to the vault.
    /// @param assetAddress The address of the asset to check.
    /// @return True if the asset is allowed to be added to the vault, false otherwise.
    function isAssetAllowed(address assetAddress) external view returns (bool);

    /// @notice Returns the number of allowed assets
    /// @return uint256 The number of allowed assets
    function allowedAssets() external view returns (uint256);

    /// @notice Returns the address of an allowed asset at a certain index
    /// @param index The index of the asset to return.
    /// @return address The address of the asset at the given index.
    function allowedAsset(uint256 index) external view returns (address);

    /// @notice This function mints FLAIX call options to the recipient. A call option
    /// is a token that can be exchanged for shares of the vault at a specified
    /// time in the future. The call option is minted by exchanging a certain
    /// amount of shares for a specific amount of an underlying asset. Upon
    /// minting, the backing asset is transferred from the minter to the options
    /// contract, and the options contract is granted the right to mint an equal
    /// amount of vault shares. Subsequently, the call option contract should
    /// own the underlying assets and be prepared to mint shares. The recipient
    /// will receive all of the call option tokens in exchange for their assets.
    /// @param name The name of the call option.
    /// @param symbol The symbol of the call option.
    /// @param sharesAmount The amount of shares to be minted to the call option contract.
    /// @param recipient The address of the recipient of the call options.
    /// @param asset The address of the underlying asset.
    /// @param assetAmount The amount of underlying asset to be transferred from the issuer to the call option contract.
    /// @param maturityTimestamp The timestamp at which the call options can be exercised.
    /// @return address The address of the newly minted call options contract.
    function issueCallOptions(
        string memory name,
        string memory symbol,
        uint256 sharesAmount,
        address recipient,
        address asset,
        uint256 assetAmount,
        uint256 maturityTimestamp
    ) external returns (address);

    /// @notice This function mints FLAIX put options to the recipient. A put option
    /// is a token that can be exchanged for underlying assets from the vault
    /// at a specified time in the future. The put option is minted by exchanging
    /// a certain amount of underlying assets for a specific amount of vault shares.
    /// Upon minting, the vault shares are burned from the issuer, and the vault matches
    /// this by transferring a certain amount of underlying assets into the options
    /// contract. Subsequently, the put option contract should own the underlying assets
    /// from the vault and have the right to mint back the burned shares in case the
    /// options are revoked. The recipient will receive all of the put option tokens in
    /// exchange for their shares.
    /// @param name The name of the put option.
    /// @param symbol The symbol of the put option.
    /// @param sharesAmount The amount of shares to be transferred from the issuer to the contract.
    /// @param recipient The address of the recipient of the put options.
    /// @param asset The address of the underlying asset.
    /// @param assetAmount The amount of underlying asset to be transferred from the vault to the contract.
    /// @param maturityTimestamp The timestamp at which the put option can be exercised.
    /// @return address The address of the newly minted put option contract.
    function issuePutOptions(
        string memory name,
        string memory symbol,
        uint256 sharesAmount,
        address recipient,
        address asset,
        uint256 assetAmount,
        uint maturityTimestamp
    ) external returns (address);
}