// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SignatureVerifier.sol";
import "./CedarERC721PremintV1.sol";
import "./api/deploy/ICedarDeployer.sol";

contract CedarERC721PremintV1Factory is Ownable, ICedarERC721PremintFactoryEventsV0, ICedarImplementationVersionedV0 {
    CedarERC721PremintV1 public implementation;
    address public greenlistManagerAddress;

    constructor(address _greenlistManagerAddress) {
        // Deploy the implementation contract
        greenlistManagerAddress = _greenlistManagerAddress;
        implementation = new CedarERC721PremintV1();
        implementation.initialize("default", "default", 0, address(0), address(0), "", "");
        (uint256 major, uint256 minor, uint256 patch) = implementation.implementationVersion();
        emit CedarImplementationDeployed(address(implementation), major, minor, patch, "CedarERC721PremintV1");
    }

    function deploy(
        address adminAddress,
        string memory _name,
        string memory _symbol,
        uint256 _maxLimit,
        string memory _userAgreement,
        string memory baseURI_
    ) external onlyOwner returns (CedarERC721PremintV1 newClone) {
        newClone = CedarERC721PremintV1(Clones.clone(address(implementation)));
        SignatureVerifier signatureVerifier = new SignatureVerifier(_userAgreement, "_", "_");

        newClone.initialize(
            _name,
            _symbol,
            _maxLimit,
            greenlistManagerAddress,
            address(signatureVerifier),
            _userAgreement,
            baseURI_
        );
        newClone.setGreenlistStatus(false);
        newClone.setTermsStatus(true);
        newClone.transferOwnership(adminAddress);

        (uint256 major, uint256 minor, uint256 patch) = newClone.implementationVersion();
        emit CedarERC721PremintV1Deployment(
            address(newClone),
            major,
            minor,
            patch,
            adminAddress,
            _name,
            _symbol,
            _maxLimit,
            _userAgreement,
            baseURI_
        );
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