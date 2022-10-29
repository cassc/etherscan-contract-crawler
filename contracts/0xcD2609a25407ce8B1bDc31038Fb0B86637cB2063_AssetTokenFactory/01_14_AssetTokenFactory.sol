// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./AssetToken.sol";
import "../interfaces/IAssetTokenData.sol";
import "../interfaces/IAssetTokenFactory.sol";

/// @author Swarm Markets
/// @title Asset Token Factory for Asset Token Contract
/// @notice Contract to deploy Asset Token contracts
contract AssetTokenFactory is AccessControlUpgradeable {
    /// @notice deployer role to be able to execute the deploy function
    bytes32 public constant ASSET_DEPLOYER_ROLE = keccak256("ASSET_DEPLOYER_ROLE");

    /// @notice struct to hold asset token data
    struct AssetTokenContract {
        string name;
        bool enabled;
    }
    /// @notice mapping holding all the deployed asset tokens
    mapping(address => AssetTokenContract) public assetTokenContracts;

    /// @notice AssetTokenData Address
    address public assetTokenDataAddress;

    /// @notice Emitted when an asset token is deployed
    event AssetTokenDeployed(string _name, address indexed _assetTokenAddress, address indexed _deployer);

    /// @notice Emitted when the address of the asset token data is set
    event AssetTokenDataChanged(address indexed _oldAddress, address indexed _newAddress, address indexed _caller);

    /// @notice Emitted when the asset token gets its enabled structure to false (only infomarional)
    event AssetTokenInfoDisabled(address indexed _assetTokenAddress, address indexed _caller);

    /**
     * @dev Initalize the contract.
     */
    function initialize(address _assetTokenDataAddress) external initializer {
        require(_assetTokenDataAddress != address(0), "AssetTokenData 0x0");

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        assetTokenDataAddress = _assetTokenDataAddress;
    }

    /// @notice Deploy an Asset Token Contract
    /// @notice Required: the caller should have ASSET_DEPLOYER_ROLE from this contract
    /// @notice Required: this contract should have ASSET_DEPLOYER_ROLE from Asset Token Data contract
    /// @param _issuer the issuer of the contract
    /// @param _guardian the guardian
    /// @param _statePercent the state percent to check the safeguard convertion
    /// @param _kya verification link
    /// @param _minimumRedemptionAmount less than this value is not allowed
    /// @param _name name of the token
    /// @param _symbol symbol of the token
    /// @return address the address of the new asset token contract deployed
    function deployAssetToken(
        address _issuer,
        address _guardian,
        uint256 _statePercent,
        string memory _kya,
        uint256 _minimumRedemptionAmount,
        string memory _name,
        string memory _symbol
    ) external returns (address) {
        require(_issuer != address(0), "DAT Issuer 0x0");
        require(_guardian != address(0), "DAT Guardian 0x0");
        require(bytes(_name).length >= 4, "DAT Err name");
        require(bytes(_symbol).length >= 3, "DAT Err symbol");
        require(hasRole(ASSET_DEPLOYER_ROLE, _msgSender()), "DAT Not allowed");

        AssetToken assetToken = new AssetToken(
            assetTokenDataAddress,
            _statePercent,
            _kya,
            _minimumRedemptionAmount,
            _name,
            _symbol
        );

        emit AssetTokenDeployed(_name, address(assetToken), _msgSender());
        assetTokenContracts[address(assetToken)].name = _name;
        assetTokenContracts[address(assetToken)].enabled = true;

        IAssetTokenData assetTknDtaContract = IAssetTokenData(assetTokenDataAddress);
        bool success = assetTknDtaContract.registerAssetToken(address(assetToken), _issuer, _guardian);
        require(success, "DAT Error deploying");
        return address(assetToken);
    }

    /// @notice Sets Asset Token Data Address
    /// @param _newAddress value to be set
    function setAssetTokenData(address _newAddress) external {
        require(_newAddress != address(0), "SAT Err newAddress");
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "SAT not authorized");
        emit AssetTokenDataChanged(assetTokenDataAddress, _newAddress, _msgSender());
        assetTokenDataAddress = _newAddress;
    }

    /// @notice Gets the Token Name
    /// @param _tokenAddress the address of the token to get the name from
    /// @return string the asset token name
    function getTokenName(address _tokenAddress) external view returns (string memory) {
        return assetTokenContracts[_tokenAddress].name;
    }

    /// @notice Gets if the Token is enabled. This is used in the Authorization Contract
    /// @param _tokenAddress the address of the token to get if it is enabled (if it exists)
    /// @return bool true if the token exists
    function isTokenEnabled(address _tokenAddress) external view returns (bool) {
        return assetTokenContracts[_tokenAddress].enabled;
    }

    /// @notice Set the Token as NOT enabled (this is just for information purposes, it does not disable the token)
    /// @param _tokenAddress the address of the token
    function disableAssetTokenInfo(address _tokenAddress) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "DAS not authorized");
        require(assetTokenContracts[_tokenAddress].enabled, "DAS already disabled");
        emit AssetTokenInfoDisabled(_tokenAddress, _msgSender());
        assetTokenContracts[_tokenAddress].enabled = false;
    }
}