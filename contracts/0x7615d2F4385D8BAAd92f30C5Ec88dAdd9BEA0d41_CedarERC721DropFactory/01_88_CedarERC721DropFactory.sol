// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CedarERC721Drop.sol";
import "../api/deploy/ICedarDeployer.sol";
import "../SignatureVerifier.sol";

contract CedarERC721DropFactory is Ownable, ICedarDeployerEventsV5, ICedarImplementationVersionedV0 {
    CedarERC721Drop public implementation;
    address public greenlistManagerAddress;

    struct EventParams {
        address contractAddress;
        uint256 majorVersion;
        uint256 minorVersion;
        uint256 patchVersion;
    }

    constructor(address _greenlistManagerAddress) {
        greenlistManagerAddress = _greenlistManagerAddress;

        implementation = new CedarERC721Drop();

        implementation.initialize(_msgSender(), "default", "default", "", new address[](0), address(0), address(0), 0, CedarERC721Drop.FeaturesInput("0", address(0), address(0)), 0, address(0));
        (uint256 major, uint256 minor, uint256 patch) = implementation.implementationVersion();
        emit CedarImplementationDeployed(address(implementation), major, minor, patch, "ICedarERC721DropV3");
    }

    function emitEvent(
        EventParams memory params
    ) private {
        emit CedarERC721DropV2Deployment(
            params.contractAddress, 
            params.majorVersion,
            params.minorVersion,
            params.patchVersion
        );
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
        string memory _userAgreement,
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external onlyOwner returns (CedarERC721Drop newClone) {
        newClone = CedarERC721Drop(Clones.clone(address(implementation)));
        SignatureVerifier signatureVerifier = new SignatureVerifier(_userAgreement, "_", "_");
        CedarERC721Drop.FeaturesInput memory input = CedarERC721Drop.FeaturesInput(_userAgreement, address(signatureVerifier), greenlistManagerAddress);

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

        (uint major, uint minor, uint patch) = newClone.implementationVersion();

        EventParams memory params;
        params.contractAddress = address(newClone);
        params.majorVersion = major;
        params.minorVersion = minor;
        params.patchVersion = patch;

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