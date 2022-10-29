// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../interfaces/IPermissionManager.sol";
import "../interfaces/IEurPriceFeed.sol";
import "../interfaces/IAssetTokenFactory.sol";

/// @author Swarm Markets
/// @title Swarm Authorization for AssetToken Token Contract
/// @notice Contract to perform validation on swarm ecosystem
contract AssetTokenAuthorization is AccessControlUpgradeable {
    using SafeMathUpgradeable for uint256;

    /// @notice role to be able to call isTxAuthorized
    bytes32 public constant AUTHORIZED_CALLER_ROLE = keccak256("AUTHORIZED_CALLER_ROLE");

    /// @notice permissionManagerAddress of Swarm Ecosystem
    address public permissionManagerAddress;

    /// @notice EurPriceFeed module address
    address public eurPriceFeedAddress;

    /// @notice AsetTokenFactory address
    address public assetTokenFactoryAddress;

    /// @notice fiatAmountValidation for security tokens (in EUR)
    uint256 public fiatAmountValidation;

    /// @notice tells this contract if the security check should take place or not
    bool public validateAsSecurityToken;

    /// @notice Emitted when the permission manager address is set
    event PermissionAddressSet(address indexed _previousAddress, address indexed _newAddress, address indexed _caller);

    /// @notice Emitted when the euro price feed address is set
    event EurPriceFeedAddressSet(
        address indexed _previousAddress,
        address indexed _newAddress,
        address indexed _caller
    );

    /// @notice Emitted when the asset token factory address is set
    event AssetTokenFactoryAddressSet(
        address indexed _previousAddress,
        address indexed _newAddress,
        address indexed _caller
    );

    /// @notice Emitted when the validateAsSecurityToken variable is set and/or the fiatAmountValidation is set
    event ValidationAsSecurityAndAmountChangedTo(bool _value, uint256 _amount, address indexed _caller);

    /// @notice Check if sender has the DEFAULT_ADMIN_ROLE role
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not ADMIN");
        _;
    }

    /// @notice Contract constructor
    /// @param _permissionManagerAddress permission manager address
    /// @param _eurPriceFeedAddress eurPriceFeed address
    /// @param _assetTokenFactoryAddress assetTokenFactory address
    /// @param _fiatAmountValidation amount to validate as a security token (18 digits)
    /// @param _validateAsSecurityToken how this will contract validates asset token (regular or security)
    function initialize(
        address _permissionManagerAddress,
        address _eurPriceFeedAddress,
        address _assetTokenFactoryAddress,
        uint256 _fiatAmountValidation,
        bool _validateAsSecurityToken
    ) external initializer {
        require(_permissionManagerAddress != address(0), "invalid permissionManagerAddress");
        require(_eurPriceFeedAddress != address(0), "invalid eurPriceFeedAddress");
        require(_assetTokenFactoryAddress != address(0), "invalid assetTokenFactoryAddress");

        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        setValidationAsSecurityAndAmount(_validateAsSecurityToken, _fiatAmountValidation);

        permissionManagerAddress = _permissionManagerAddress;
        eurPriceFeedAddress = _eurPriceFeedAddress;
        assetTokenFactoryAddress = _assetTokenFactoryAddress;
    }

    /// @notice Grants DEFAULT_ADMIN_ROLE to set contract parameters.
    /// @param _account to be granted the admin role
    function grantAdminRole(address _account) external onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, _account);
    }

    /// @notice Returns true if `account` is authorized in Swarm Ecosystem
    /// @param _account the address to be checked
    /// @return bool true if `account` is authorized
    function regularAssetValidation(address _account) internal view returns (bool) {
        IPermissionManager permissionManager = IPermissionManager(permissionManagerAddress);

        bool hasTier2 = permissionManager.hasTier2(_account);
        bool isSuspended = permissionManager.isSuspended(_account);
        bool isRejected = permissionManager.isRejected(_account);

        return (hasTier2 && !isSuspended && !isRejected);
    }

    /// @notice Returns true if `account` is authorized in Swarm Ecosystem
    /// @param _account the address to be checked
    /// @return bool true if `account` is authorized
    function isAccountAuthorized(address _account) external view returns (bool) {
        require(_account != address(0), "IAU: not authorized");
        return (regularAssetValidation(_account));
    }

    /// @notice Checks if the tx amount is larger than the parametrized amount in EUR
    /// @param _tokenAddress the address of the current token
    /// @param _amount the amount of asset tokens
    /// @return bool true if the amount is larger than the fiatAmountValidation amount
    function checkAmount(address _tokenAddress, uint256 _amount) public view returns (bool) {
        IEurPriceFeed eurPriceFeed = IEurPriceFeed(eurPriceFeedAddress);
        // this returns the amount in EUR with 18 decimals. It needs an
        // _amount as a parameter with the asset decimals qty
        uint256 amountInEur = eurPriceFeed.calculateAmount(_tokenAddress, _amount);
        if (amountInEur >= fiatAmountValidation) return true;
        return false;
    }

    /// @notice Returns true if `account` can operates with security tokens
    /// @param _account the address to be checked
    /// @param _amount the amount to be checked
    /// @param _tokenAddress the address of the current token
    /// @return bool true if `account` is authorized
    function securityAssetValidation(
        address _account,
        uint256 _amount,
        address _tokenAddress
    ) internal returns (bool) {
        require(hasRole(AUTHORIZED_CALLER_ROLE, _msgSender()), "SAV: invalid Security caller");
        IPermissionManager permissionManager = IPermissionManager(permissionManagerAddress);
        // check if token exists
        uint256 idToken = permissionManager.getSecurityTokenId(_tokenAddress);
        // check if account has the token
        bool hasSecurityToken = permissionManager.hasSecurityToken(_account, idToken);
        // check amount
        bool isTxAmountLarger = checkAmount(_tokenAddress, _amount);

        if (!hasSecurityToken) {
            // account does not have
            if (isTxAmountLarger) {
                // tx amount is larger than validation amount
                if (idToken == 0) {
                    // token does not 1155 exist
                    // never has been a transfer over fiatValidationAmount
                    // generate the new 1155 token
                    idToken = permissionManager.generateSecurityTokenId(_tokenAddress);
                }
                // token 1155 exists
                // mint the 1155 token
                address[] memory accountTocheck = new address[](1);
                accountTocheck[0] = _account;
                permissionManager.assignItem(idToken, accountTocheck);
                // amount is larger
                return true;
            } else {
                // account does not have 1155
                // amount is smaller than fiatValidationAmount
                // cannot create 1155 token
                return false;
            }
        } else {
            // account have security token
            // amount does not matter
            return true;
        }
    }

    /// @notice This is called from the Asset Token contract to check if the accounts are authorized
    /// @param _tokenAddress the address of the current token
    /// @param _from the sender
    /// @param _to the receiver
    /// @param _amount the amount to be checked
    /// @return bool true if the transaction is authorized
    function isTxAuthorized(
        address _tokenAddress,
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool) {
        IAssetTokenFactory assetTokenFactory = IAssetTokenFactory(assetTokenFactoryAddress);
        require(assetTokenFactory.isTokenEnabled(_tokenAddress), "ITXA: tokenAddress not enabled");

        bool regularValidationFrom;
        bool regularValidationTo;
        bool securityValidation;
        if (_from != address(0)) {
            // it is not a mint
            regularValidationFrom = regularAssetValidation(_from);
        } else {
            regularValidationFrom = true;
        }

        if (regularValidationFrom) {
            if (_to != address(0)) {
                regularValidationTo = regularAssetValidation(_to);
            } else {
                regularValidationTo = true;
            }
        } else {
            return false;
        }

        if (regularValidationFrom && regularValidationTo) {
            if (validateAsSecurityToken && _to != address(0)) {
                securityValidation = securityAssetValidation(_to, _amount, _tokenAddress);
            } else {
                securityValidation = true;
            }
        } else {
            return false;
        }
        return securityValidation;
    }

    /// @notice Sets PermissionManager contract address as the permission manager from swarm ecosystem
    /// @param _permissionManagerAddress permissionManagerAddress contract
    function setPermissionManagerAddress(address _permissionManagerAddress) external onlyAdmin {
        require(_permissionManagerAddress != address(0), "SPM: invalid permissionManagerAddress");
        emit PermissionAddressSet(permissionManagerAddress, _permissionManagerAddress, _msgSender());
        permissionManagerAddress = _permissionManagerAddress;
    }

    /// @notice Sets the EurPriceFeed contract address
    /// @param _eurPriceFeedAddress The address of the EUR Price feed module.
    function setEurPriceFeedAddress(address _eurPriceFeedAddress) external onlyAdmin {
        require(_eurPriceFeedAddress != address(0), "SEP: invalid eurPriceFeedAddress");
        emit EurPriceFeedAddressSet(eurPriceFeedAddress, _eurPriceFeedAddress, _msgSender());
        eurPriceFeedAddress = _eurPriceFeedAddress;
    }

    /// @notice Sets the AssetTokenFactory contract address
    /// @param _assetTokenFactoryAddress The address of the asset token factory
    function setAssetTokenFactoryAddress(address _assetTokenFactoryAddress) external onlyAdmin {
        require(_assetTokenFactoryAddress != address(0), "SAF: invalid assetTokenFactoryAddress");
        emit AssetTokenFactoryAddressSet(assetTokenFactoryAddress, _assetTokenFactoryAddress, _msgSender());
        assetTokenFactoryAddress = _assetTokenFactoryAddress;
    }

    /// @notice Sets the if this contract should validate the token as a security asset
    /// @notice and/or changes the _fiatAmountValidation to compare to
    /// @param _validateAsSecurityToken The new value to set
    /// @param _fiatAmountValidation The new fiat amount to compare to
    function setValidationAsSecurityAndAmount(bool _validateAsSecurityToken, uint256 _fiatAmountValidation)
        public
        onlyAdmin
    {
        if (_validateAsSecurityToken) {
            require(_fiatAmountValidation > 0, "SVSA: fiatAmountValidation needs to be larger than ZERO");
        } else {
            require(_fiatAmountValidation == 0, "SVSA: fiatAmountValidation needs to be ZERO");
        }
        emit ValidationAsSecurityAndAmountChangedTo(_validateAsSecurityToken, _fiatAmountValidation, _msgSender());
        validateAsSecurityToken = _validateAsSecurityToken;
        fiatAmountValidation = _fiatAmountValidation;
    }
}