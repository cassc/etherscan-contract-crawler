// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/ICollateralOracle.sol";

/**
 * @title Static Collateral Oracle
 */
contract StaticCollateralOracle is AccessControl, ICollateralOracle {
    /**************************************************************************/
    /* Constants */
    /**************************************************************************/

    /**
     * @notice Implementation version
     */
    string public constant IMPLEMENTATION_VERSION = "1.0";

    /**************************************************************************/
    /* Access Control Roles */
    /**************************************************************************/

    /**
     * @notice Parameter admin role
     */
    bytes32 public constant PARAMETER_ADMIN_ROLE = keccak256("PARAMETER_ADMIN");

    /**************************************************************************/
    /* Errors */
    /**************************************************************************/

    /**
     * @notice Invalid address (e.g. zero address)
     */
    error InvalidAddress();

    /**************************************************************************/
    /* Events */
    /**************************************************************************/

    /**
     * @notice Emitted when collateral value for a collateral token is updated
     * @param collateralToken Address of collateral token
     * @param collateralValue Collateral value
     */
    event CollateralValueUpdated(address indexed collateralToken, uint256 collateralValue);

    /**************************************************************************/
    /* State */
    /**************************************************************************/

    /**
     * @dev Mapping of collateral token contract to collateral value
     */
    mapping(address => uint256) private _collateralValue;

    /**
     * @inheritdoc ICollateralOracle
     */
    IERC20 public immutable override currencyToken;

    /**************************************************************************/
    /* Constructor */
    /**************************************************************************/

    /**
     * @notice CollateralOracle constructor
     * @param currencyToken_ Currency token used for pricing
     */
    constructor(IERC20 currencyToken_) {
        currencyToken = currencyToken_;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PARAMETER_ADMIN_ROLE, msg.sender);
    }

    /**************************************************************************/
    /* Getters */
    /**************************************************************************/

    /**
     * @inheritdoc ICollateralOracle
     */
    function collateralValue(address collateralToken, uint256 collateralTokenId) external view returns (uint256) {
        collateralTokenId;

        if (_collateralValue[collateralToken] == 0) revert UnsupportedCollateral();

        return _collateralValue[collateralToken];
    }

    /**************************************************************************/
    /* Setters */
    /**************************************************************************/

    /**
     * @notice Set collateral value
     *
     * Emits a {CollateralValueUpdated} event.
     *
     * @param collateralToken Collateral token contract
     * @param collateralValue_ Collateral value
     */
    function setCollateralValue(address collateralToken, uint256 collateralValue_)
        external
        onlyRole(PARAMETER_ADMIN_ROLE)
    {
        if (collateralToken == address(0)) revert InvalidAddress();

        _collateralValue[collateralToken] = collateralValue_;

        emit CollateralValueUpdated(collateralToken, collateralValue_);
    }
}