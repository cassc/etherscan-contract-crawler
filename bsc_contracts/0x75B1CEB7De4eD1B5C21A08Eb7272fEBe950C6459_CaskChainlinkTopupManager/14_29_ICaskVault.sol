// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/**
 * @title  Interface for vault
  */

interface ICaskVault is IERC20MetadataUpgradeable {

    // whitelisted stablecoin assets supported by the vault
    struct Asset {
        address priceFeed;
        uint256 slippageBps;
        uint256 depositLimit;
        uint8 assetDecimals;
        uint8 priceFeedDecimals;
        bool allowed;
    }

    // sources for payments
    enum FundingSource {
        Cask,
        Personal
    }

    // funding profile for a given address
    struct FundingProfile {
        FundingSource fundingSource;
        address fundingAsset;
    }

    /**
      * @dev Get base asset of vault.
     */
    function getBaseAsset() external view returns (address);

    /**
      * @dev Get all the assets supported by the vault.
     */
    function getAllAssets() external view returns (address[] memory);

    /**
     * @dev Get asset details
     * @param _asset Asset address
     * @return Asset Asset details
     */
    function getAsset(address _asset) external view returns(Asset memory);

    /**
     * @dev Check if the vault supports an asset
     * @param _asset Asset address
     * @return bool `true` if asset supported, `false` otherwise
     */
    function supportsAsset(address _asset) external view returns (bool);

    /**
     * @dev Pay `_value` of `baseAsset` from `_from` to `_to` initiated by an authorized protocol
     * @param _from From address
     * @param _to To address
     * @param _value Amount of baseAsset value to transfer
     * @param _protocolFee Protocol fee to deduct from `_value`
     * @param _network Address of network fee collector
     * @param _networkFee Network fee to deduct from `_value`
     */
    function protocolPayment(
        address _from,
        address _to,
        uint256 _value,
        uint256 _protocolFee,
        address _network,
        uint256 _networkFee
    ) external;

    /**
     * @dev Pay `_value` of `baseAsset` from `_from` to `_to` initiated by an authorized protocol
     * @param _from From address
     * @param _to To address
     * @param _value Amount of baseAsset value to transfer
     * @param _protocolFee Protocol fee to deduct from `_value`
     */
    function protocolPayment(
        address _from,
        address _to,
        uint256 _value,
        uint256 _protocolFee
    ) external;

    /**
     * @dev Pay `_value` of `baseAsset` from `_from` to `_to` initiated by an authorized protocol
     * @param _from From address
     * @param _to To address
     * @param _value Amount of baseAsset value to transfer
     */
    function protocolPayment(
        address _from,
        address _to,
        uint256 _value
    ) external;

    /**
     * @dev Transfer the equivalent vault shares of base asset `value` to `_recipient`
     * @param _recipient To address
     * @param _value Amount of baseAsset value to transfer
     */
    function transferValue(
        address _recipient,
        uint256 _value
    ) external returns (bool);

    /**
     * @dev Transfer the equivalent vault shares of base asset `value` from `_sender` to `_recipient`
     * @param _sender From address
     * @param _recipient To address
     * @param _value Amount of baseAsset value to transfer
     */
    function transferValueFrom(
        address _sender,
        address _recipient,
        uint256 _value
    ) external returns (bool);

    /**
     * @dev Deposit `_assetAmount` of `_asset` into the vault and credit the equivalent value of `baseAsset`
     * @param _asset Address of incoming asset
     * @param _assetAmount Amount of asset to deposit
     */
    function deposit(address _asset, uint256 _assetAmount) external;

    /**
     * @dev Deposit `_assetAmount` of `_asset` into the vault and credit the equivalent value of `baseAsset`
     * @param _to Recipient of funds
     * @param _asset Address of incoming asset
     * @param _assetAmount Amount of asset to deposit
     */
    function depositTo(address _to, address _asset, uint256 _assetAmount) external;

    /**
     * @dev Withdraw an amount of shares from the vault in the form of `_asset`
     * @param _asset Address of outgoing asset
     * @param _shares Amount of shares to withdraw
     */
    function withdraw(address _asset, uint256 _shares) external;

    /**
     * @dev Withdraw an amount of shares from the vault in the form of `_asset`
     * @param _recipient Recipient who will receive the withdrawn assets
     * @param _asset Address of outgoing asset
     * @param _shares Amount of shares to withdraw
     */
    function withdrawTo(address _recipient, address _asset, uint256 _shares) external;

    /**
     * @dev Retrieve the funding source for an address
     * @param _address Address for lookup
     */
    function fundingSource(address _address) external view returns(FundingProfile memory);

    /**
     * @dev Set the funding source and, if using a personal wallet, the asset to use for funding payments
     * @param _fundingSource Funding source to use
     * @param _fundingAsset Asset to use for payments (if using personal funding source)
     */
    function setFundingSource(FundingSource _fundingSource, address _fundingAsset) external;

    /**
     * @dev Get current vault value of `_address` denominated in `baseAsset`
     * @param _address Address to check
     */
    function currentValueOf(address _address) external view returns(uint256);

    /**
     * @dev Get current vault value a vault share
     */
    function pricePerShare() external view returns(uint256);

    /**
     * @dev Get the number of vault shares that represents a given value of the base asset
     * @param _value Amount of value
     */
    function sharesForValue(uint256 _value) external view returns(uint256);

    /**
     * @dev Get total value in vault and managed by admin - denominated in `baseAsset`
     */
    function totalValue() external view returns(uint256);

    /**
     * @dev Get total amount of an asset held in vault and managed by admin
     * @param _asset Address of asset
     */
    function totalAssetBalance(address _asset) external view returns(uint256);


    /************************** EVENTS **************************/

    /** @dev Emitted when `sender` transfers `baseAssetValue` (denominated in vault baseAsset) to `recipient` */
    event TransferValue(address indexed from, address indexed to, uint256 baseAssetAmount, uint256 shares);

    /** @dev Emitted when an amount of `baseAsset` is paid from `from` to `to` within the vault */
    event Payment(address indexed from, address indexed to, uint256 baseAssetAmount, uint256 shares,
        uint256 protocolFee, uint256 protocolFeeShares,
        address indexed network, uint256 networkFee, uint256 networkFeeShares);

    /** @dev Emitted when `asset` is added as a new supported asset */
    event AllowedAsset(address indexed asset);

    /** @dev Emitted when `asset` is disallowed t */
    event DisallowedAsset(address indexed asset);

    /** @dev Emitted when `participant` deposits `asset` */
    event AssetDeposited(address indexed participant, address indexed asset, uint256 assetAmount,
        uint256 baseAssetAmount, uint256 shares);

    /** @dev Emitted when `participant` withdraws `asset` */
    event AssetWithdrawn(address indexed participant, address indexed asset, uint256 assetAmount,
        uint256 baseAssetAmount, uint256 shares);

    /** @dev Emitted when `participant` sets their funding source */
    event SetFundingSource(address indexed participant, FundingSource fundingSource, address fundingAsset);

    /** @dev Emitted when a new protocol is allowed to use the vault */
    event AddProtocol(address indexed protocol);

    /** @dev Emitted when a protocol is no longer allowed to use the vault */
    event RemoveProtocol(address indexed protocol);

    /** @dev Emitted when the vault fee distributor is changed */
    event SetFeeDistributor(address indexed feeDistributor);

    /** @dev Emitted when minDeposit is changed */
    event SetMinDeposit(uint256 minDeposit);

    /** @dev Emitted when maxPriceFeedAge is changed */
    event SetMaxPriceFeedAge(uint256 maxPriceFeedAge);

    /** @dev Emitted when the trustedForwarder address is changed */
    event SetTrustedForwarder(address indexed feeDistributor);
}