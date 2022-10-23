// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./CedarERC721PremintFactory.sol";
import "./drop/CedarERC721DropFactory.sol";
import "./drop/CedarERC1155DropFactory.sol";
import "./paymentSplit/CedarPaymentSplitterFactory.sol";
import "./generated/deploy/BaseCedarDeployerV9.sol";

contract CedarDeployer is Initializable, UUPSUpgradeable, OwnableUpgradeable, BaseCedarDeployerV9 {
    CedarERC721PremintFactory premintFactory;
    CedarERC721DropFactory drop721Factory;
    CedarERC1155DropFactory drop1155Factory;
    CedarPaymentSplitterFactory paymentSplitterFactory;

    using ERC165CheckerUpgradeable for address;

    error IllegalVersionUpgrade(
        uint256 existingMajorVersion,
        uint256 existingMinorVersion,
        uint256 existingPatchVersion,
        uint256 newMajorVersion,
        uint256 newMinorVersion,
        uint256 newPatchVersion
    );

    error ImplementationNotVersioned(address implementation);

    function initialize(
        CedarERC721PremintFactory _premintFactory,
        CedarERC721DropFactory _drop721Factory,
        CedarERC1155DropFactory _drop1155Factory,
        CedarPaymentSplitterFactory _paymentSplitterFactory
    ) public virtual initializer {
        premintFactory = _premintFactory;
        drop721Factory = _drop721Factory;
        drop1155Factory = _drop1155Factory;
        paymentSplitterFactory = _paymentSplitterFactory;

        __Ownable_init();
    }

    function reinitialize(
        CedarERC721PremintFactory _premintFactory,
        CedarERC721DropFactory _drop721Factory,
        CedarERC1155DropFactory _drop1155Factory,
        CedarPaymentSplitterFactory _paymentSplitterFactory
    ) public virtual onlyOwner {
        premintFactory = _premintFactory;
        drop721Factory = _drop721Factory;
        drop1155Factory = _drop1155Factory;
        paymentSplitterFactory = _paymentSplitterFactory;
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner {
        (uint256 major, uint256 minor, uint256 patch) = this.implementationVersion();
        if (!newImplementation.supportsInterface(type(ICedarVersionedV0).interfaceId)) {
            revert ImplementationNotVersioned(newImplementation);
        }
        (uint256 newMajor, uint256 newMinor, uint256 newPatch) = ICedarVersionedV0(newImplementation)
            .implementationVersion();
        // Do not permit a breaking change via an UUPS proxy upgrade - this requires a new proxy. Otherwise, only allow
        // minor/patch versions to increase
        if (major != newMajor || minor > newMinor || (minor == newMinor && patch > newPatch)) {
            revert IllegalVersionUpgrade(major, minor, patch, newMajor, newMinor, newPatch);
        }
    }

    function deployCedarERC721PremintV2(
        address adminAddress,
        string memory _name,
        string memory _symbol,
        uint256 _maxLimit,
        string memory _userAgreement,
        string memory baseURI_
    ) external override returns (ICedarERC721PremintV2) {
        CedarERC721Premint newContract = premintFactory.deploy(
            adminAddress,
            _name,
            _symbol,
            _maxLimit,
            _userAgreement,
            baseURI_
        );

        (uint256 major, uint256 minor, uint256 patch) = newContract.implementationVersion();
        string memory interfaceName = newContract.implementationInterfaceName();
        emit CedarInterfaceDeployed(address(newContract), major, minor, patch, interfaceName);
        return newContract;
    }

    function deployCedarERC721DropV5(
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
    ) external override returns (ICedarERC721DropV6) {
        CedarERC721Drop newContract = drop721Factory.deploy(
            _defaultAdmin,
            _name,
            _symbol,
            _contractURI,
            _trustedForwarders,
            _saleRecipient,
            _royaltyRecipient,
            _royaltyBps,
            _userAgreement,
            _platformFeeBps,
            _platformFeeRecipient
        );

        (uint256 major, uint256 minor, uint256 patch) = newContract.implementationVersion();
        string memory interfaceName = newContract.implementationInterfaceName();
        emit CedarInterfaceDeployed(address(newContract), major, minor, patch, interfaceName);
        return newContract;
    }

    function deployCedarERC1155DropV4(
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
    ) external override returns (ICedarERC1155DropV4) {
        CedarERC1155Drop newContract = drop1155Factory.deploy(
            _defaultAdmin,
            _name,
            _symbol,
            _contractURI,
            _trustedForwarders,
            _saleRecipient,
            _royaltyRecipient,
            _royaltyBps,
            _userAgreement,
            _platformFeeBps,
            _platformFeeRecipient
        );

        (uint256 major, uint256 minor, uint256 patch) = newContract.implementationVersion();
        string memory interfaceName = newContract.implementationInterfaceName();
        emit CedarInterfaceDeployed(address(newContract), major, minor, patch, interfaceName);
        return newContract;
    }

    function cedarERC721PremintVersion()
        external
        view
        override
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        )
    {
        return premintFactory.implementationVersion();
    }

    function cedarERC721DropVersion()
        external
        view
        override
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        )
    {
        return drop721Factory.implementationVersion();
    }

    function cedarERC1155DropVersion()
        external
        view
        override
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        )
    {
        return drop1155Factory.implementationVersion();
    }

    function cedarERC721PremintFeatures() public view override returns (string[] memory features) {
        return premintFactory.implementation().supportedFeatures();
    }

    function cedarERC721DropFeatures() public view override returns (string[] memory features) {
        return drop721Factory.implementation().supportedFeatures();
    }

    function cedarERC1155DropFeatures() public view override returns (string[] memory features) {
        return drop1155Factory.implementation().supportedFeatures();
    }

    // Concrete implementation semantic version - provided for completeness but not designed to be the point of dispatch
    function minorVersion() public pure virtual override returns (uint256 minor, uint256 patch) {
        minor = 0;
        patch = 0;
    }

    function deployCedarPaymentSplitterV1(address[] memory payees, uint256[] memory shares_)
        external
        override
        returns (ICedarPaymentSplitterV1)
    {
        CedarPaymentSplitter newContract = paymentSplitterFactory.deploy(payees, shares_);
        string memory interfaceName = newContract.implementationInterfaceName();
        (uint256 major, uint256 minor, uint256 patch) = newContract.implementationVersion();
        emit CedarInterfaceDeployed(address(newContract), major, minor, patch, interfaceName);
        return newContract;
    }

    function cedarPaymentSplitterVersion()
        external
        view
        override
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        )
    {
        return paymentSplitterFactory.implementationVersion();
    }

    function cedarPaymentSplitterFeatures() external view override returns (string[] memory features) {
        return paymentSplitterFactory.implementation().supportedFeatures();
    }
}