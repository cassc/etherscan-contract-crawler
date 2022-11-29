// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CedarERC721Drop.sol";
import "../api/deploy/ICedarDeployer.sol";

contract CedarERC721DropFactory is Ownable, IDropFactoryEventsV0, ICedarImplementationVersionedV0 {
    /// ===============================================
    ///  ========== State variables - public ==========
    /// ===============================================
    CedarERC721Drop public implementation;

    /// =============================
    /// ========== Structs ==========
    /// =============================
    struct EventParams {
        address contractAddress;
        address defaultAdmin;
        string name;
        string symbol;
        string userAgreement;
        address saleRecipient;
        address royaltyRecipient;
        address platformFeeRecipient;
        uint128 royaltyBps;
        uint128 platformFeeBps;
        uint256 majorVersion;
        uint256 minorVersion;
        uint256 patchVersion;
    }

    constructor() {
        implementation = new CedarERC721Drop();

        implementation.initialize(
            _msgSender(),
            "default",
            "default",
            "",
            new address[](0),
            address(0),
            address(0),
            0,
            "0",
            0,
            address(0),
            address(0)
        );
        (uint256 major, uint256 minor, uint256 patch) = implementation.implementationVersion();
        emit CedarImplementationDeployed(address(implementation), major, minor, patch, "ICedarERC721DropV3");
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
        address _platformFeeRecipient,
        address _drop721DelegateLogic
    ) external onlyOwner returns (CedarERC721Drop newClone) {
        newClone = CedarERC721Drop(Clones.clone(address(implementation)));

        EventParams memory params;

        params.name = _name;
        params.symbol = _symbol;
        params.saleRecipient = _saleRecipient;
        params.royaltyRecipient = _royaltyRecipient;
        params.royaltyBps = _royaltyBps;
        params.userAgreement = _userAgreement;
        params.platformFeeBps = _platformFeeBps;
        params.platformFeeRecipient = _platformFeeRecipient;
        params.defaultAdmin = _defaultAdmin;

        newClone.initialize(
            params.defaultAdmin,
            params.name,
            params.symbol,
            _contractURI,
            _trustedForwarders,
            params.saleRecipient,
            params.royaltyRecipient,
            params.royaltyBps,
            params.userAgreement,
            params.platformFeeBps,
            _platformFeeRecipient,
            _drop721DelegateLogic
        );

        (uint256 major, uint256 minor, uint256 patch) = newClone.implementationVersion();

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
        emit DropContractDeployment(
            params.contractAddress,
            params.majorVersion,
            params.minorVersion,
            params.patchVersion,
            params.defaultAdmin,
            params.name,
            params.symbol,
            params.saleRecipient,
            params.royaltyRecipient,
            params.royaltyBps,
            params.userAgreement,
            params.platformFeeBps,
            params.platformFeeRecipient
        );
    }
}