// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "../interfaces/AddressBookInterface.sol";
import { WhitelistInterface } from "../interfaces/WhitelistInterface.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Whitelist Module
 * @notice The whitelist module keeps track of all valid onToken addresses, product hashes, collateral addresses.
 */
contract Whitelist is WhitelistInterface, Ownable {
    /// @notice AddressBook module address
    address public addressBook;
    /// @dev mapping to track whitelisted products
    mapping(bytes32 => bool) internal whitelistedProduct;
    /// @dev mapping to track whitelisted collaterals
    mapping(bytes32 => bool) internal whitelistedCollaterals;
    /// @dev mapping to track whitelisted onTokens
    mapping(address => bool) internal whitelistedONtoken;

    /**
     * @dev constructor
     * @param _addressBook AddressBook module address
     */
    constructor(address _addressBook) {
        require(_addressBook != address(0), "Invalid address book");

        addressBook = _addressBook;
    }

    /// @notice emits an event a product is whitelisted by the owner address
    event ProductWhitelisted(
        bytes32 productHash,
        address indexed underlying,
        address indexed strike,
        address[] indexed collaterals,
        bool isPut
    );
    /// @notice emits an event a product is blacklisted by the owner address
    event ProductBlacklisted(
        bytes32 productHash,
        address indexed underlying,
        address indexed strike,
        address[] indexed collateral,
        bool isPut
    );
    /// @notice emits an event when a collateral address is whitelisted by the owner address
    event CollateralWhitelisted(address[] indexed collateral);
    /// @notice emits an event when a collateral address is blacklist by the owner address
    event CollateralBlacklisted(address[] indexed collateral);
    /// @notice emits an event when an onToken is whitelisted by the ONtokenFactory module
    event ONtokenWhitelisted(address indexed onToken);
    /// @notice emits an event when an onToken is blacklisted by the ONtokenFactory module
    event ONtokenBlacklisted(address indexed onToken);

    /**
     * @notice check if the sender is the onTokenFactory module
     */
    modifier onlyFactory() {
        require(
            msg.sender == AddressBookInterface(addressBook).getONtokenFactory(),
            "Whitelist: Sender is not ONtokenFactory"
        );

        _;
    }

    /**
     * @notice check if a product is whitelisted
     * @dev product is the hash of underlying asset, strike asset, collateral asset, and isPut
     * @param _underlying asset that the option references
     * @param _strike asset that the strike price is denominated in
     * @param _collateral asset that is held as collateral against short/written options
     * @param _isPut True if a put option, False if a call option
     * @return boolean, True if product is whitelisted
     */
    function isWhitelistedProduct(
        address _underlying,
        address _strike,
        address[] calldata _collateral,
        bool _isPut
    ) external view returns (bool) {
        bytes32 productHash = keccak256(abi.encode(_underlying, _strike, _collateral, _isPut));

        return whitelistedProduct[productHash];
    }

    /**
     * @notice check if a collateral asset is whitelisted
     * @param _collaterals assets that is held as collateral against short/written options
     * @return boolean, True if the collateral is whitelisted
     */
    function isWhitelistedCollaterals(address[] calldata _collaterals) external view returns (bool) {
        return whitelistedCollaterals[keccak256(abi.encode(_collaterals))];
    }

    /**
     * @notice check if an onToken is whitelisted
     * @param _onToken onToken address
     * @return boolean, True if the onToken is whitelisted
     */
    function isWhitelistedONtoken(address _onToken) external view returns (bool) {
        return whitelistedONtoken[_onToken];
    }

    /**
     * @notice allows the owner to whitelist a product
     * @dev product is the hash of underlying asset, strike asset, collateral asset, and isPut
     * can only be called from the owner address
     * @param _underlying asset that the option references
     * @param _strike asset that the strike price is denominated in
     * @param _collaterals assets that is held as collateral against short/written options
     * @param _isPut True if a put option, False if a call option
     */
    function whitelistProduct(
        address _underlying,
        address _strike,
        address[] calldata _collaterals,
        bool _isPut
    ) external onlyOwner {
        require(
            whitelistedCollaterals[keccak256(abi.encode(_collaterals))],
            "Whitelist: Collateral is not whitelisted"
        );

        bytes32 productHash = keccak256(abi.encode(_underlying, _strike, _collaterals, _isPut));

        whitelistedProduct[productHash] = true;

        emit ProductWhitelisted(productHash, _underlying, _strike, _collaterals, _isPut);
    }

    /**
     * @notice allow the owner to blacklist a product
     * @dev product is the hash of underlying asset, strike asset, collateral asset, and isPut
     * can only be called from the owner address
     * @param _underlying asset that the option references
     * @param _strike asset that the strike price is denominated in
     * @param _collaterals assets that is held as collateral against short/written options
     * @param _isPut True if a put option, False if a call option
     */
    function blacklistProduct(
        address _underlying,
        address _strike,
        address[] calldata _collaterals,
        bool _isPut
    ) external onlyOwner {
        bytes32 productHash = keccak256(abi.encode(_underlying, _strike, _collaterals, _isPut));

        whitelistedProduct[productHash] = false;

        emit ProductBlacklisted(productHash, _underlying, _strike, _collaterals, _isPut);
    }

    /**
     * @notice allows the owner to whitelist a collateral address
     * @dev can only be called from the owner address. This function is used to whitelist any asset other than ONtoken as collateral. WhitelistONtoken() is used to whitelist ONtoken contracts.
     * @param _collaterals collateral assets addresses
     */
    function whitelistCollaterals(address[] calldata _collaterals) external onlyOwner {
        whitelistedCollaterals[keccak256(abi.encode(_collaterals))] = true;

        emit CollateralWhitelisted(_collaterals);
    }

    /**
     * @notice allows the owner to blacklist a collateral address
     * @dev can only be called from the owner address
     * @param _collaterals collateral assets addresses
     */
    function blacklistCollateral(address[] calldata _collaterals) external onlyOwner {
        whitelistedCollaterals[keccak256(abi.encode(_collaterals))] = false;

        emit CollateralBlacklisted(_collaterals);
    }

    /**
     * @notice allows the ONtokenFactory module to whitelist a new option
     * @dev can only be called from the ONtokenFactory address
     * @param _onTokenAddress onToken
     */
    function whitelistONtoken(address _onTokenAddress) external onlyFactory {
        whitelistedONtoken[_onTokenAddress] = true;

        emit ONtokenWhitelisted(_onTokenAddress);
    }

    /**
     * @notice allows the owner to blacklist an option
     * @dev can only be called from the owner address
     * @param _onTokenAddress onToken
     */
    function blacklistONtoken(address _onTokenAddress) external onlyOwner {
        whitelistedONtoken[_onTokenAddress] = false;

        emit ONtokenBlacklisted(_onTokenAddress);
    }
}