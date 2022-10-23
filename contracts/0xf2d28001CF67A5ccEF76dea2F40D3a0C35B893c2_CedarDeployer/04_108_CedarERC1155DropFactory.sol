// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CedarERC1155Drop.sol";
import "../api/deploy/ICedarDeployer.sol";
import "../SignatureVerifier.sol";

contract CedarERC1155DropFactory is Ownable, ICedarERC1155DropFactoryEventsV0, ICedarImplementationVersionedV0 {
    /// ===============================================
    ///  ========== State variables - public ==========
    /// ===============================================
    CedarERC1155Drop public implementation;

    /// =============================
    /// ========== Structs ==========
    /// =============================
    struct EventParams {
        address contractAddress;
        uint256 majorVersion;
        uint256 minorVersion;
        uint256 patchVersion;
    }

    constructor() {
        // Deploy the implementation contract and set implementationAddress
        implementation = new CedarERC1155Drop();

        implementation.initialize(
            _msgSender(),
            "default",
            "default",
            "",
            new address[](0),
            address(0),
            address(0),
            0,
            CedarERC1155Drop.FeaturesInput("0", address(0)),
            0,
            address(0)
        );

        (uint256 major, uint256 minor, uint256 patch) = implementation.implementationVersion();
        emit CedarImplementationDeployed(address(implementation), major, minor, patch, "ICedarERC1155DropV1");
    }

    /// ==================================
    /// ========== Public methods ========
    /// ==================================
    function deploy(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _saleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        string memory _userAgreement,
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external onlyOwner returns (CedarERC1155Drop newClone) {
        newClone = CedarERC1155Drop(Clones.clone(address(implementation)));
        SignatureVerifier signatureVerifier = new SignatureVerifier(_userAgreement, "_", "_");
        CedarERC1155Drop.FeaturesInput memory input = CedarERC1155Drop.FeaturesInput(
            _userAgreement,
            address(signatureVerifier)
        );

        newClone.initialize(
            _defaultAdmin,
            _name,
            _symbol,
            _contractURI,
            _trustedForwarders,
            _saleRecipient,
            _royaltyRecipient,
            _royaltyBps,
            input,
            _platformFeeBps,
            _platformFeeRecipient
        );

        (uint256 major, uint256 minor, uint256 patch) = newClone.implementationVersion();

        EventParams memory params;
        params.contractAddress = address(newClone);
        params.majorVersion = major;
        params.minorVersion = minor;
        params.patchVersion = patch;

        _emitEvent(params);
    }

    /// ===========================
    /// ========== Getters ========
    /// ===========================
    function implementationVersion()
        external
        view
        override
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        )
    {
        return implementation.implementationVersion();
    }

    /// ===================================
    /// ========== Private methods ========
    /// ===================================
    function _emitEvent(EventParams memory params) private {
        emit CedarERC1155DropV2Deployment(
            params.contractAddress,
            params.majorVersion,
            params.minorVersion,
            params.patchVersion
        );
    }
}