// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155HolderUpgradeable.sol";
import "../interfaces/IERC1155Burnable.sol";
import "../interfaces/IAuthorizationContract.sol";
import "../interfaces/IXTokenWrapper.sol";

/// @author Swarm Markets
/// @title Redemption Queue for Asset Tokens Contracts
/// @notice Contract to manage a queue of token deposits
contract RedemptionQueue is AccessControlUpgradeable, ERC1155HolderUpgradeable, ReentrancyGuardUpgradeable {
    // using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    /// @notice Address of the xTokenWrapper contract
    address public xTokenWrapperAddress;

    /// @notice Address of the Authorization contract
    address public authorizationContractAddress;

    /// @notice allowed Nft assets
    mapping(address => mapping(uint256 => bool)) public allowed1155Assets;

    /// @notice Structure to hold the Redemption Requests
    struct RedemptionRequest {
        address requester;
        string referenceTo;
        address assetAddress;
        uint256 asset1155Id;
        uint256 assetAmount;
        bool completed;
        address canceledBy;
        string cancelMotive;
    }
    /// @notice Redemption Requests mapping and last ID
    mapping(uint256 => RedemptionRequest) public redemptionRequests;
    uint256 public currentRedemptionRequestID;

    /// @notice Emitted when xTokenWrapperAddress is set
    event XTokenWrapperAddressSet(
        address indexed _caller,
        address indexed _previousAddress,
        address indexed _newAddress
    );

    /// @notice Emitted when authorizationContractAddress is set
    event AuthorizationAddressSet(
        address indexed _caller,
        address indexed _previousAddress,
        address indexed _newAddress
    );

    /// @notice Emitted when whitelisting an 1155 token
    event Whitelisted1155Token(address _asset, uint256 _assetId, address _caller);

    /// @notice Emitted when removing an 1155 token from the whitelist
    event RemovedFromWhitelist1155Token(address _asset, uint256 _assetId, address _caller);

    /// @notice Emitted when Requesting a Redemption
    event RedemptionRequested(
        uint256 indexed _redemptionRequestID,
        address _assetAddress,
        uint256 _assetId,
        uint256 _assetAmount,
        address indexed _caller
    );

    /// @notice Emitted when a Redemption request is canceled
    event RedemptionCanceled(uint256 indexed _redemptionRequestID, string _motive, address indexed _caller);

    /// @notice Emitted when a Redemption is executed
    event RedemptionExecuted(
        uint256 indexed _redemptionRequestID,
        address indexed _requester,
        address _assetAddress,
        uint256 _asset1155Id,
        uint256 _assetAmount,
        address _caller,
        bool indexed _success
    );

    /// @notice Emitted when Redemption is skipped from its execution
    event RedemptionNotExecuted(uint256 indexed _redemptionRequestID, address indexed _caller);

    /// @notice Check if sender has the DEFAULT_ADMIN_ROLE role
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not ADMIN");
        _;
    }

    /// @notice Check if asset 1155 is allowed
    modifier onlyAllowedAssets(address _assetAddress, uint256 _assetId) {
        bool isAssetAuthorized = false;
        if (_assetId == 0) {
            // it's a regular erc20 asset, check the wrapper for allowed assets
            IXTokenWrapper xTokenWrapperContract = IXTokenWrapper(xTokenWrapperAddress);
            address returnedAddress = xTokenWrapperContract.tokenToXToken(_assetAddress);
            if (returnedAddress != address(0)) {
                isAssetAuthorized = true;
            }
        } else {
            // it's an 1155 check the mapping for true
            isAssetAuthorized = allowed1155Assets[_assetAddress][_assetId];
        }
        require(isAssetAuthorized, "Asset is not authorized");
        _;
    }

    /**
     * @notice Initalize the contract.
     * @param _authorizationContractAddress sets the _authorizationContractAddress to check active accounts
     * @param _xTokenWrapperAddress sets the xTokenWrapper address
     */
    function initialize(address _authorizationContractAddress, address _xTokenWrapperAddress) external initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setAuthorizationContractAddress(_authorizationContractAddress);
        _setXTokenWrapperAddress(_xTokenWrapperAddress);
        currentRedemptionRequestID = 0;
    }

    /// @notice Grants DEFAULT_ADMIN_ROLE to set contract parameters.
    /// @param _account to be granted the admin role
    function grantAdminRole(address _account) external onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, _account);
    }

    /// @notice Whitelist an ERC1155 token
    /// @param _asset address of the contract who minted the token
    /// @param _assetId ID of the 1155 token
    function whitelist1155Token(address _asset, uint256 _assetId) external onlyAdmin {
        require(_asset != address(0), "A1155: Invalid Address for 1155 token provided");
        require(_assetId != 0, "A1155: Invalid ID for 1155 token provided");

        emit Whitelisted1155Token(_asset, _assetId, _msgSender());
        allowed1155Assets[_asset][_assetId] = true;
    }

    /// @notice Remove from Whitelist an ERC1155 token
    /// @param _asset address of the contract who minted the token
    /// @param _assetId ID of the 1155 token
    function removeFromWhitelist1155Token(address _asset, uint256 _assetId) external onlyAdmin {
        require(allowed1155Assets[_asset][_assetId], "RMV1155: Token is not whitelisted");

        emit RemovedFromWhitelist1155Token(_asset, _assetId, _msgSender());
        allowed1155Assets[_asset][_assetId] = false;
    }

    /// @notice Returns true if `account` is authorized in Swarm Ecosystem
    /// @param _account the address to be ckecked
    /// @return bool true if `account` is authorized
    function isAuthorized(address _account) public view returns (bool) {
        require(authorizationContractAddress != address(0), "Invalid permission address");
        IAuthorizationContract authorizationContract = IAuthorizationContract(authorizationContractAddress);
        return (authorizationContract.isAccountAuthorized(_account));
    }

    /// @notice Requests an amount to redeem of a certain asset
    /// @param _asset the address of Asset to be redeemed
    /// @param _assetId the ID of the Asset
    /// @param _amount the amount of the Token to be redeemed
    /// @param _referenceTo the off chain hash of the redemption transaction
    /// @return uint256 redemption request ID to be referenced in the mapping
    function requestRedemption(
        address _asset,
        uint256 _assetId,
        uint256 _amount,
        string calldata _referenceTo
    ) external nonReentrant onlyAllowedAssets(_asset, _assetId) returns (uint256) {
        require(_amount > 0, "RRD: invalid _amount");
        require(isAuthorized(_msgSender()), "RRD: caller not authorized in Swarm");

        currentRedemptionRequestID = currentRedemptionRequestID.add(1);
        emit RedemptionRequested(currentRedemptionRequestID, _asset, _assetId, _amount, _msgSender());

        redemptionRequests[currentRedemptionRequestID] = RedemptionRequest(
            _msgSender(),
            _referenceTo,
            _asset,
            _assetId,
            _amount,
            false,
            address(0),
            ""
        );

        _tokenTransfer(_asset, _assetId, _msgSender(), address(this), _amount);
        return currentRedemptionRequestID;
    }

    /// @notice Cancel Redemption Request
    /// @param _redemptionRequestID redemption request ID to be referenced in the mapping
    /// @param _motive motive of the cancelation
    function cancelRedemptionRequest(uint256 _redemptionRequestID, string calldata _motive) external nonReentrant {
        require(redemptionRequests[_redemptionRequestID].assetAmount != 0, "CRR: Invalid _redemptionRequestID");
        require(
            !redemptionRequests[_redemptionRequestID].completed &&
                redemptionRequests[_redemptionRequestID].canceledBy == address(0),
            "CRR: Redemption Request completed or canceled"
        );

        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            require(
                redemptionRequests[_redemptionRequestID].requester == _msgSender(),
                "CRR: caller is not request owner"
            );
        }

        require(
            isAuthorized(redemptionRequests[_redemptionRequestID].requester),
            "CRR: requester not authorized in Swarm"
        );

        emit RedemptionCanceled(_redemptionRequestID, _motive, _msgSender());

        redemptionRequests[_redemptionRequestID].canceledBy = _msgSender();
        redemptionRequests[_redemptionRequestID].cancelMotive = _motive;

        _tokenTransfer(
            redemptionRequests[_redemptionRequestID].assetAddress,
            redemptionRequests[_redemptionRequestID].asset1155Id,
            address(this),
            redemptionRequests[_redemptionRequestID].requester,
            redemptionRequests[_redemptionRequestID].assetAmount
        );
    }

    /// @notice Execute Redemption Requests
    /// @param _redemptionRequests array of redemption requests ID to be referenced in the mapping
    /// @param _referenceTo the transaction ID
    /// @return bool showing if there was an invalid ID involved
    function executeRedemption(uint256[] calldata _redemptionRequests, string calldata _referenceTo)
        external
        onlyAdmin
        nonReentrant
        returns (bool)
    {
        require(_redemptionRequests.length > 0, "ERR: Invalid _redemptionRequests array");
        uint256 rqId;
        bool foundInvalidID = false;

        for (uint256 i = 0; i < _redemptionRequests.length; i++) {
            rqId = _redemptionRequests[i];
            if (_isExecutableRequest(rqId)) {
                emit RedemptionExecuted(
                    rqId,
                    redemptionRequests[rqId].requester,
                    redemptionRequests[rqId].assetAddress,
                    redemptionRequests[rqId].asset1155Id,
                    redemptionRequests[rqId].assetAmount,
                    _msgSender(),
                    true
                );
                redemptionRequests[rqId].completed = true;
                redemptionRequests[rqId].referenceTo = _referenceTo;

                // burn tokens from the contract
                if (redemptionRequests[rqId].asset1155Id == 0) {
                    // it's a regular erc20 asset
                    // slither-disable-next-line calls-loop
                    ERC20BurnableUpgradeable(redemptionRequests[rqId].assetAddress).burn(
                        redemptionRequests[rqId].assetAmount
                    );
                } else {
                    // it's an erc1155
                    // slither-disable-next-line calls-loop
                    IERC1155Burnable(redemptionRequests[rqId].assetAddress).burn(
                        address(this),
                        redemptionRequests[rqId].asset1155Id,
                        redemptionRequests[rqId].assetAmount
                    );
                }
            } else {
                foundInvalidID = true;
                emit RedemptionNotExecuted(rqId, _msgSender());
            }
        }

        return foundInvalidID;
    }

    /**
     * @notice Get the Redemption Request by ID
     * @param _redemptionRequestID Id of the redemption request
     * @return RedemptionRequest structure (the redemption request structure)
     */
    function getRedemptionRequestByID(uint256 _redemptionRequestID) external view returns (RedemptionRequest memory) {
        require(redemptionRequests[_redemptionRequestID].assetAmount != 0, "GRR: Invalid _redemptionRequestID");
        return redemptionRequests[_redemptionRequestID];
    }

    /**
     * @notice Sets `_xTokenWrapperAddress` as the xToken Wrapper module.
     * @param _xTokenWrapperAddress  xTokenWrapperAddress contract
     */
    function setXTokenWrapper(address _xTokenWrapperAddress) external onlyAdmin {
        _setXTokenWrapperAddress(_xTokenWrapperAddress);
    }

    /**
     * @notice Sets `authorizationContractAddress` as the permission contract to check accounts
     * @param _authorizationContractAddress authorizationContractAddress
     */
    function setAuthorizationContractAddress(address _authorizationContractAddress) external onlyAdmin {
        _setAuthorizationContractAddress(_authorizationContractAddress);
    }

    /**
     * @notice Sets `xTokenWrapperAddress` as the xToken Wrapper module.
     * @param _xTokenWrapperAddress The address of the new xToken Wrapper module.
     */
    function _setXTokenWrapperAddress(address _xTokenWrapperAddress) internal {
        require(_xTokenWrapperAddress != address(0), "_xTokenWrapperAddress is zero address");
        emit XTokenWrapperAddressSet(_msgSender(), xTokenWrapperAddress, _xTokenWrapperAddress);
        xTokenWrapperAddress = _xTokenWrapperAddress;
    }

    /**
     * @notice Sets `_authorizationContractAddress` as the permission contract to check accounts
     * @param _authorizationContractAddress _authorizationContractAddress
     */
    function _setAuthorizationContractAddress(address _authorizationContractAddress) internal {
        require(_authorizationContractAddress != address(0), "_authorizationContractAddress is zero address");
        emit AuthorizationAddressSet(_msgSender(), authorizationContractAddress, _authorizationContractAddress);
        authorizationContractAddress = _authorizationContractAddress;
    }

    /**
     * @notice Makes the token transfer
     * @param _token The address of the token
     * @param _from   The address of the sender
     * @param _to The address of the receiver
     * @param _amount The amount
     * @return bool signaling the completiion of the function
     */
    function _tokenTransfer(
        address _token,
        uint256 _tokenId,
        address _from,
        address _to,
        uint256 _amount
    ) private returns (bool) {
        if (_tokenId != 0) {
            // it's an erc1155 token

            if (_from == address(this)) {
                IERC1155(_token).setApprovalForAll(_to, true);
            }
            IERC1155(_token).safeTransferFrom(_from, _to, _tokenId, _amount, bytes(""));
        } else {
            // it's an erc20 token

            if (_from == address(this)) {
                require(ERC20BurnableUpgradeable(_token).approve(address(this), _amount), "TTR: ERC20 approve failed");
            }
            require(ERC20BurnableUpgradeable(_token).transferFrom(_from, _to, _amount), "TTR: ERC20 transfer failed");
        }
        return true;
    }

    /**
     * @notice Checks if the request is executable (not canceled, valid id, not completed)
     * @param _redemptionRequestID permissionManagerAddress contract
       @return bool true if the request is executable
     */
    function _isExecutableRequest(uint256 _redemptionRequestID) internal view returns (bool) {
        if (
            redemptionRequests[_redemptionRequestID].assetAmount != 0 &&
            !redemptionRequests[_redemptionRequestID].completed &&
            redemptionRequests[_redemptionRequestID].canceledBy == address(0)
        ) {
            return true;
        }
        return false;
    }
}