// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CedarERC1155Drop.sol";
import "../api/deploy/ICedarDeployer.sol";
import "../SignatureVerifier.sol";

contract CedarERC1155DropFactory is Ownable, ICedarDeployerEventsV4, ICedarImplementationVersionedV0 {
    CedarERC1155Drop public implementation;

    struct EventParams {
        address contractAddress;
        uint256 majorVersion;
        uint256 minorVersion;
        uint256 patchVersion;
        address defaultAdmin;
        string name;
        string symbol;
        string contractURI;
        address[] trustedForwarders;
        address saleRecipient;
        address royaltyRecipient;
        uint128 royaltyBps;
        uint128 platformFeeBps;
        address platformFeeRecipient;
    }

    constructor() {
        // Deploy the implementation contract and set implementationAddress
        implementation = new CedarERC1155Drop();

        implementation.initialize(_msgSender(), "default", "default", "", new address[](0), address(0), address(0), 0, 0, address(0));

        (uint256 major, uint256 minor, uint256 patch) = implementation.implementationVersion();
        emit CedarImplementationDeployed(address(implementation), major, minor, patch, "DropERC1155V1");
    }

    function emitEvent(
        EventParams memory params
    ) private {
        emit CedarERC1155DropV1Deployment(params.contractAddress, params.majorVersion, params.minorVersion, params.patchVersion, params.defaultAdmin, params.name, params.symbol, params.contractURI, params.trustedForwarders, params.saleRecipient, params.royaltyRecipient, params.royaltyBps, params.platformFeeBps, params.platformFeeRecipient);
    }

    function deploy(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _saleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external onlyOwner returns (CedarERC1155Drop newClone) {
        newClone = CedarERC1155Drop(Clones.clone(address(implementation)));
        newClone.initialize(_defaultAdmin, _name, _symbol, _contractURI, _trustedForwarders, _saleRecipient, _royaltyRecipient, _royaltyBps, _platformFeeBps, _platformFeeRecipient);

        (uint major, uint minor, uint patch) = newClone.implementationVersion();

        EventParams memory params;
        params.contractAddress = address(newClone);
        params.majorVersion = major;
        params.minorVersion = minor;
        params.patchVersion = patch;
        params.defaultAdmin = _defaultAdmin;
        params.name = _name;
        params.symbol = _symbol;
        params.contractURI = _contractURI;
        params.trustedForwarders = _trustedForwarders;
        params.saleRecipient = _saleRecipient;
        params.royaltyRecipient = _royaltyRecipient;
        params.royaltyBps = _royaltyBps;
        params.platformFeeBps = _platformFeeBps;
        params.platformFeeRecipient = _platformFeeRecipient;

        emitEvent(params);
    }

    function implementationVersion()
    external override
    view
    returns (
        uint256 major,
        uint256 minor,
        uint256 patch
    ) {
        return implementation.implementationVersion();
    }
}