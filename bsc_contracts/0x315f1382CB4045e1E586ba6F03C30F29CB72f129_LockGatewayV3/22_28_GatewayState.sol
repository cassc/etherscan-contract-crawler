// SPDX-License-Identifier: GPL-3.0

// solhint-disable-next-line
pragma solidity ^0.8.0;

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {IRenVMSignatureVerifier} from "../RenVMSignatureVerifier.sol";
import {StringV1} from "../../libraries/StringV1.sol";
import {RenVMHashes} from "./RenVMHashes.sol";

abstract contract GatewayStateV3 {
    // Selector hash details.
    string internal _asset;
    bytes32 internal _selectorHash;

    /// @notice Each signature can only be seen once.
    mapping(bytes32 => bool) internal _status;

    /// @notice Each Gateway is tied to a specific asset.
    address internal _token;

    IRenVMSignatureVerifier internal _signatureVerifier;

    address internal _previousGateway;

    uint256 internal _eventNonce;

    // Leave a gap so that storage values added in future upgrages don't corrupt
    // the storage of contracts that inherit from this contract.
    uint256[43] private __gap;
}

abstract contract GatewayStateManagerV3 is Initializable, ContextUpgradeable, GatewayStateV3 {
    event LogAssetUpdated(string asset, bytes32 indexed selectorHash);
    event LogTokenUpdated(address indexed token);
    event LogSignatureVerifierUpdated(address indexed oldSignatureVerifier, address indexed newSignatureVerifier);
    event LogPreviousGatewayUpdated(address indexed oldPreviousGateway, address indexed newPreviousGateway);

    function __GatewayStateManager_init(
        string calldata asset_,
        address signatureVerifier_,
        address token_
    ) public initializer {
        __Context_init();
        _updateSignatureVerifier(signatureVerifier_);
        _updateAsset(asset_);
        _updateToken(token_);
    }

    // GETTERS /////////////////////////////////////////////////////////////////

    function getAsset() public view returns (string memory) {
        return _asset;
    }

    function getSelectorHash() public view returns (bytes32) {
        require(_selectorHash != bytes32(0x0), "Gateway: not initialized");
        return _selectorHash;
    }

    function getToken() public view returns (address) {
        return _token;
    }

    function getSignatureVerifier() public view returns (IRenVMSignatureVerifier) {
        return _signatureVerifier;
    }

    function getPreviousGateway() public view returns (address) {
        return _previousGateway;
    }

    function getEventNonce() public view returns (uint256) {
        return _eventNonce;
    }

    // Backwards compatibility.
    function token() public view returns (address) {
        return getToken();
    }

    // GOVERNANCE //////////////////////////////////////////////////////////////

    /// @notice The Gateway is controlled by the owner of the SignatureVerifier.
    /// This allows for the owner of every Gateway to be updated with a single
    /// update to the SignatureVerifier contract.
    function owner() public view returns (address) {
        return OwnableUpgradeable(address(getSignatureVerifier())).owner();
    }

    modifier onlySignatureVerifierOwner() {
        require(owner() == _msgSender(), "Gateway: caller is not the owner");
        _;
    }

    /// @notice Allow the owner to update the asset.
    ///
    /// @param nextAsset The new asset.
    function updateAsset(string calldata nextAsset) public onlySignatureVerifierOwner {
        _updateAsset(nextAsset);
    }

    /// @notice Allow the owner to update the signature verifier contract.
    ///
    /// @param newSignatureVerifier The new verifier contract address.
    function updateSignatureVerifier(address newSignatureVerifier) public onlySignatureVerifierOwner {
        _updateSignatureVerifier(newSignatureVerifier);
    }

    /// @notice Allow the owner to update the ERC20 token contract.
    ///
    /// @param newToken The new ERC20 token contract's address.
    function updateToken(address newToken) public onlySignatureVerifierOwner {
        _updateToken(newToken);
    }

    /// @notice Allow the owner to update the previous gateway used for
    /// backwards compatibility.
    ///
    /// @param newPreviousGateway The new gateway contract's address.
    function updatePreviousGateway(address newPreviousGateway) external onlySignatureVerifierOwner {
        require(address(newPreviousGateway) != address(0x0), "Gateway: invalid address");
        address oldPreviousGateway = _previousGateway;
        _previousGateway = newPreviousGateway;
        emit LogPreviousGatewayUpdated(oldPreviousGateway, newPreviousGateway);
    }

    // PREVIOUS GATEWAY ////////////////////////////////////////////////////////

    modifier onlyPreviousGateway() {
        address previousGateway_ = getPreviousGateway();

        // If there's no previous gateway, the second require should also fail,
        // but this require will provide a more informative reason.
        require(previousGateway_ != address(0x0), "Gateway: no previous gateway");

        require(_msgSender() == previousGateway_, "Gateway: not authorized");
        _;
    }

    function status(bytes32 hash) public view returns (bool) {
        if (_status[hash]) {
            return true;
        }

        address previousGateway_ = getPreviousGateway();
        if (previousGateway_ != address(0x0)) {
            return GatewayStateManagerV3(previousGateway_).status(hash);
        }

        return false;
    }

    // INTERNAL ////////////////////////////////////////////////////////////////

    /// @notice Allow the owner to update the asset.
    ///
    /// @param nextAsset The new asset.
    function _updateAsset(string calldata nextAsset) internal {
        require(StringV1.isValidString(nextAsset), "Gateway: invalid asset");

        _asset = nextAsset;

        bytes32 newSelectorHash = RenVMHashes.calculateSelectorHash(nextAsset, getSignatureVerifier().getChain());
        _selectorHash = newSelectorHash;
        emit LogAssetUpdated(nextAsset, newSelectorHash);
    }

    /// @notice Allow the owner to update the signature verifier contract.
    ///
    /// @param newSignatureVerifier The new verifier contract address.
    function _updateSignatureVerifier(address newSignatureVerifier) internal {
        require(address(newSignatureVerifier) != address(0x0), "Gateway: invalid signature verifier");
        address oldSignatureVerifier = address(_signatureVerifier);
        _signatureVerifier = IRenVMSignatureVerifier(newSignatureVerifier);
        emit LogSignatureVerifierUpdated(oldSignatureVerifier, newSignatureVerifier);
    }

    /// @notice Allow the owner to update the ERC20 token contract.
    ///
    /// @param newToken The new ERC20 token contract's address.
    function _updateToken(address newToken) internal {
        require(address(newToken) != address(0x0), "Gateway: invalid token");
        _token = newToken;
        emit LogTokenUpdated(newToken);
    }
}