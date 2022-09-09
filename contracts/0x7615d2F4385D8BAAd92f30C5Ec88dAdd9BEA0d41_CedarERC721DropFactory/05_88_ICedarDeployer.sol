// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import "../impl/ICedarERC721Premint.sol";
import "../impl/ICedarERC721Drop.sol";
import "../impl/ICedarERC1155Drop.sol";
import "../impl/ICedarPaymentSplitter.sol";

interface ICedarDeployerEventsV0 {
    event CedarInterfaceDeployed(
        address indexed contractAddress,
        uint256 indexed majorVersion,
        uint256 indexed minorVersion,
        uint256 patchVersion,
        string interfaceName
    );

    // Primarily for the benefit of Etherscan verification
    event CedarImplementationDeployed(
        address indexed implementationAddress,
        uint256 indexed majorVersion,
        uint256 indexed minorVersion,
        uint256 patchVersion,
        string contractName
    );

    event CedarERC721PremintV0Deployment(
        address indexed contractAddress,
        uint256 indexed majorVersion,
        uint256 indexed minorVersion,
        uint256 patchVersion,
        address adminAddress,
        string name,
        string symbol,
        uint256 maxLimit,
        string userAgreement,
        string baseURI
    );

    event CedarERC721DropV0Deployment(
        address indexed contractAddress,
        uint256 indexed majorVersion,
        uint256 indexed minorVersion,
        uint256 patchVersion,
        address defaultAdmin,
        string name,
        string symbol,
        string contractURI,
        address[] trustedForwarders,
        address saleRecipient,
        address royaltyRecipient,
        uint128 royaltyBps,
        string userAgreement,
        address signatureVerifier,
        address greenlistManager
    );
}

// FIXME[Silas]: none of the events below belong to CedarDeployer. They are factory events so the name is misleading.
//   The factories omit them, not clear why they need to be in public API at all
interface ICedarDeployerEventsV1 is ICedarDeployerEventsV0 {
    event CedarERC1155DropV0Deployment(
        address indexed contractAddress,
        uint256 indexed majorVersion,
        uint256 indexed minorVersion,
        uint256 patchVersion,
        address defaultAdmin,
        string name,
        string symbol,
        string contractURI,
        address[] trustedForwarders,
        address saleRecipient,
        address royaltyRecipient,
        uint128 royaltyBps,
        uint128 platformFeeBps,
        address platformFeeRecipient
    );
}

interface ICedarDeployerEventsV2 is ICedarDeployerEventsV1 {
    event CedarERC721PremintV1Deployment(
        address indexed contractAddress,
        uint256 indexed majorVersion,
        uint256 indexed minorVersion,
        uint256 patchVersion,
        address adminAddress,
        string name,
        string symbol,
        uint256 maxLimit,
        string userAgreement,
        string baseURI
    );
}

interface ICedarDeployerEventsV3 is ICedarDeployerEventsV2 {
    event CedarPaymentSplitterDeployment(
        address indexed contractAddress,
        uint256 indexed majorVersion,
        uint256 indexed minorVersion,
        uint256 patchVersion,
        address[] payees,
        uint256[] shares
    );
}

interface ICedarDeployerEventsV4 is ICedarDeployerEventsV3 {
    event CedarERC721DropV1Deployment(
        address indexed contractAddress,
        uint256 indexed majorVersion,
        uint256 indexed minorVersion,
        uint256 patchVersion,
        address defaultAdmin,
        string name,
        string symbol,
        string contractURI,
        address[] trustedForwarders,
        address saleRecipient,
        address royaltyRecipient,
        uint128 royaltyBps,
        string userAgreement,
        address signatureVerifier,
        address greenlistManager
    );

    event CedarERC1155DropV1Deployment(
        address indexed contractAddress,
        uint256 indexed majorVersion,
        uint256 indexed minorVersion,
        uint256 patchVersion,
        address defaultAdmin,
        string name,
        string symbol,
        string contractURI,
        address[] trustedForwarders,
        address saleRecipient,
        address royaltyRecipient,
        uint128 royaltyBps,
        uint128 platformFeeBps,
        address platformFeeRecipient
    );
}

interface ICedarDeployerEventsV5 is ICedarDeployerEventsV4 {
    event CedarERC721DropV2Deployment(
        address indexed contractAddress,
        uint256 indexed majorVersion,
        uint256 indexed minorVersion,
        uint256 patchVersion
    );
}

// Each CedarERC721 contract should implement a maximal version of the interfaces it supports and should itself carry
// the version major version suffix, in this case CedarERC721V0
interface ICedarDeployerV0 is ICedarVersionedV0, ICedarDeployerEventsV0 {
    function deployCedarERC721PremintV0(
        address adminAddress,
        string memory _name,
        string memory _symbol,
        uint256 _maxLimit,
        string memory _userAgreement,
        string memory baseURI_
    ) external returns (ICedarERC721PremintV0);

    function deployCedarERC721DropV0(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _saleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        string memory _userAgreement
    ) external returns (ICedarERC721DropV0);

    function cedarERC721PremintVersion()
        external
        view
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        );

    function cedarERC721DropVersion()
        external
        view
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        );
}

interface ICedarDeployerAddedV1 {
    function deployCedarERC1155DropV0(
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
    ) external returns (ICedarERC1155DropV0);

    function cedarERC1155DropVersion()
        external
        view
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        );

    function cedarERC721PremintFeatures() external view returns (string[] memory features);

    function cedarERC721DropFeatures() external view returns (string[] memory features);

    function cedarERC1155DropFeatures() external view returns (string[] memory features);
}

interface ICedarDeployerV1 is ICedarDeployerAddedV1, ICedarDeployerV0 {}

interface ICedarDeployerAddedV2 {
    function deployCedarERC721PremintV1(
        address adminAddress,
        string memory _name,
        string memory _symbol,
        uint256 _maxLimit,
        string memory _userAgreement,
        string memory baseURI_
    ) external returns (ICedarERC721PremintV1);
}

interface ICedarDeployerV2 is ICedarDeployerAddedV2, ICedarDeployerAddedV1, ICedarDeployerV0 {}

interface ICedarDeployerAddedV3 {
    function deployCedarPaymentSplitterV0(address[] memory payees, uint256[] memory shares_)
        external
        returns (ICedarPaymentSplitterV0);

    function cedarPaymentSplitterVersion()
        external
        view
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        );

    function cedarPaymentSplitterFeatures() external view returns (string[] memory features);
}

interface ICedarDeployerV3 is ICedarDeployerAddedV3, ICedarDeployerAddedV2, ICedarDeployerAddedV1, ICedarDeployerV0 {}

interface ICedarDeployerIntrospectionV0 is ICedarVersionedV0 {
    function cedarERC721PremintVersion()
        external
        view
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        );

    function cedarERC721DropVersion()
        external
        view
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        );

    function cedarERC1155DropVersion()
        external
        view
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        );

    function cedarERC721PremintFeatures() external view returns (string[] memory features);

    function cedarERC721DropFeatures() external view returns (string[] memory features);

    function cedarERC1155DropFeatures() external view returns (string[] memory features);
}

interface ICedarDeployerAddedV4 {
    function deployCedarERC1155DropV1(
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
    ) external returns (ICedarERC1155DropV1);

    function deployCedarERC721DropV1(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _saleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        string memory _userAgreement
    ) external returns (ICedarERC721DropV1);
}

interface ICedarDeployerV4 is
    ICedarDeployerEventsV4,
    ICedarDeployerAddedV4,
    ICedarDeployerAddedV3,
    ICedarDeployerAddedV2,
    ICedarDeployerIntrospectionV0
{}

interface ICedarDeployerAddedV5 {
    function deployCedarERC1155DropV1(
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
    ) external returns (ICedarERC1155DropV1);

    function deployCedarERC721DropV2(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _saleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        string memory _userAgreement
    ) external returns (ICedarERC721DropV2);
}

interface ICedarDeployerAddedV6 {
    function deployCedarERC1155DropV1(
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
    ) external returns (ICedarERC1155DropV1);

    function deployCedarERC721DropV2(
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
    ) external returns (ICedarERC721DropV2);
}

interface ICedarDeployerAddedV7 {
    function deployCedarERC1155DropV1(
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
    ) external returns (ICedarERC1155DropV1);

    function deployCedarERC721DropV3(
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
    ) external returns (ICedarERC721DropV3);
}

interface ICedarDeployerV5 is
    ICedarDeployerEventsV4,
    ICedarDeployerAddedV5,
    ICedarDeployerAddedV3,
    ICedarDeployerAddedV2,
    ICedarDeployerIntrospectionV0
{}

interface ICedarDeployerV6 is
    ICedarDeployerEventsV5,
    ICedarDeployerAddedV7,
    ICedarDeployerAddedV3,
    ICedarDeployerAddedV2,
    ICedarDeployerIntrospectionV0
{}