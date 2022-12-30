// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title  CollateralWhitelist
 * @author Solarr
 * @notice
 */
contract CollateralWhitelist is Ownable {
    /* ********** */
    /* DATA TYPES */
    /* ********** */

    /**
     * @param collateralAddress - The address of the smart contract of the Collateral.
     * @param name - The name the nft Collateral.
     * @param activeDate - The date that the Collateral is listed.
     */
    struct Collateral {
        address collateralAddress;
        string name;
        uint256 activeDate;
    }

    /* ********** */
    /* STORAGE */
    /* ********** */

    bool private INITIALIZED = false;

    mapping(address => Collateral) public whitelistedCollaterals; // Collaterals information that have been added to whitelist

    /* *********** */
    /* EVENTS */
    /* *********** */

    /**
     * @notice This event is fired whenever the Collateral is listed to Whitelist.
     */
    event CollateralWhitelisted(address, string, uint256);

    /**
     * @notice This event is fired whenever the Collateral is unlisted from Whitelist.
     */
    event CollateralUnwhitelisted(address, string, uint256);

    /* *********** */
    /* MODIFIERS */
    /* *********** */

    modifier whenNotZeroCollateralAddress(address _collateralAddress) {
        require(
            _collateralAddress != address(0),
            "Collateral address must not be zero address"
        );
        _;
    }

    modifier whenCollateralNotWhitelisted(address _collateralAddress) {
        require(
            !_isCollateralWhitelisted(_collateralAddress),
            "Collateral already whitelisted"
        );
        _;
    }

    modifier whenCollateralWhitelisted(address _collateralAddress) {
        require(
            _isCollateralWhitelisted(_collateralAddress),
            "Collateral is not whitelisted"
        );
        _;
    }

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    /* *********** */
    /* RECEIVE FUNCTIONS */
    /* *********** */

    /* *********** */
    /* EXTERNAL FUNCTIONS */
    /* *********** */

    function initialize() external {
        require(!INITIALIZED, "Contract is already initialized");
        _transferOwnership(msg.sender);
        INITIALIZED = true;
    }

    /**
     * @notice This function can be called by Owner to list Collateral to Whitelist.
     *
     * @param _collateralAddress - The address of the Collateral contract.
     * @param _name - The name of the Collateral.
     */
    function whitelistCollateral(
        address _collateralAddress,
        string calldata _name
    ) external {
        _whitelistCollateral(_collateralAddress, _name);
    }

    /**
     * @notice This function can be called by Owner to unlist Collateral from Whitelist.
     *
     * @param _collateralAddress - The address of the Collateral contract.
     */
    function unwhitelistCollateral(address _collateralAddress) external {
        _unwhitelistCollateral(_collateralAddress);
    }

    /**
     * @notice This function can be called by Anyone to know the Collateral is listed in Whitelist or not.
     *
     * @param _collateralAddress - The address of the Collateral contract.
     *
     * @return Returns whether the Collateral is whitelisted
     */
    function isCollateralWhitelisted(address _collateralAddress)
        external
        view
        returns (bool)
    {
        return _isCollateralWhitelisted(_collateralAddress);
    }

    /* *********** */
    /* PUBLIC FUNCTIONS */
    /* *********** */

    /* *********** */
    /* INTERNAL FUNCTIONS */
    /* *********** */

    /**
     * @notice This function can be called by Owner to list Collateral to Whitelist.
     *
     * @param _collateralAddress - The address of the Collateral contract.
     * @param _name - The name of the Collateral.
     */
    function _whitelistCollateral(
        address _collateralAddress,
        string calldata _name
    )
        internal
        whenNotZeroCollateralAddress(_collateralAddress)
        onlyOwner
        whenCollateralNotWhitelisted(_collateralAddress)
    {
        // create Collateral instance and list to whitelist
        whitelistedCollaterals[_collateralAddress] = Collateral(
            _collateralAddress,
            _name,
            block.timestamp
        );

        emit CollateralWhitelisted(_collateralAddress, _name, block.timestamp);
    }

    /**
     * @notice This function can be called by Owner to unlist Collateral from Whitelist.
     *
     * @param _collateralAddress - The address of the Collateral contract.
     */
    function _unwhitelistCollateral(address _collateralAddress)
        internal
        whenNotZeroCollateralAddress(_collateralAddress)
        onlyOwner
        whenCollateralWhitelisted(_collateralAddress)
    {
        // remove Collateral instance and unlist from whitelist
        Collateral memory collateral = whitelistedCollaterals[
            _collateralAddress
        ];
        string memory name = collateral.name;
        delete whitelistedCollaterals[_collateralAddress];

        emit CollateralUnwhitelisted(_collateralAddress, name, block.timestamp);
    }

    /**
     * @notice This function can be called by Anyone to know the Collateral is listed in Whitelist or not.
     *
     * @param _collateralAddress - The address of the Collateral contract.
     *
     * @return Returns whether the Collateral is whitelisted
     */
    function _isCollateralWhitelisted(address _collateralAddress)
        internal
        view
        returns (bool)
    {
        return
            whitelistedCollaterals[_collateralAddress].collateralAddress !=
            address(0);
    }

    /* *********** */
    /* PRIVATE FUNCTIONS */
    /* *********** */
}