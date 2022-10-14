// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "../impl/ICedarERC721Premint.sol";
import "../impl/ICedarERC721Drop.sol";
import "../impl/ICedarERC1155Drop.sol";
import "../impl/ICedarPaymentSplitter.sol";

// Events deployed by CedarDeployer directly (not by factories)
interface ICedarDeployerOwnEventsV0 {
    event CedarInterfaceDeployed(
        address indexed contractAddress,
        uint256 indexed majorVersion,
        uint256 indexed minorVersion,
        uint256 patchVersion,
        string interfaceName
    );
}

// Update this interface by bumping the version then updating in-place.
// Previous versions will be immortalised in manifest but do not need to be kept around to clutter
// solidity code
interface ICedarDeployerV8 is ICedarDeployerOwnEventsV0, ICedarVersionedV0 {
    function deployCedarERC721PremintV1(
        address adminAddress,
        string memory _name,
        string memory _symbol,
        uint256 _maxLimit,
        string memory _userAgreement,
        string memory baseURI_
    ) external returns (ICedarERC721PremintV1);

    function deployCedarERC1155DropV3(
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
    ) external returns (ICedarERC1155DropV3);

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
    ) external returns (ICedarERC721DropV5);

    function deployCedarPaymentSplitterV0(address[] memory payees, uint256[] memory shares)
        external
        returns (ICedarPaymentSplitterV0);

    /// Versions

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

    function cedarPaymentSplitterVersion()
        external
        view
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        );

    /// Features

    function cedarERC721PremintFeatures() external view returns (string[] memory features);

    function cedarERC721DropFeatures() external view returns (string[] memory features);

    function cedarERC1155DropFeatures() external view returns (string[] memory features);

    function cedarPaymentSplitterFeatures() external view returns (string[] memory features);
}

interface ICedarFactoryEventsV0 {
    // Primarily for the benefit of Etherscan verification
    event CedarImplementationDeployed(
        address indexed implementationAddress,
        uint256 indexed majorVersion,
        uint256 indexed minorVersion,
        uint256 patchVersion,
        string contractName
    );
}

/// Factory specific events (emitted by factories, but included in ICedarDeployer interfaces because they can be
/// expected to be emitted on transactions that call the deploy functions

interface ICedarERC721PremintFactoryEventsV0 is ICedarFactoryEventsV0 {
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

interface ICedarERC721DropFactoryEventsV0 is ICedarFactoryEventsV0 {
    event CedarERC721DropV2Deployment(
        address indexed contractAddress,
        uint256 indexed majorVersion,
        uint256 indexed minorVersion,
        uint256 patchVersion
    );
}

interface ICedarERC1155DropFactoryEventsV0 is ICedarFactoryEventsV0 {
    event CedarERC1155DropV2Deployment(
        address indexed contractAddress,
        uint256 indexed majorVersion,
        uint256 indexed minorVersion,
        uint256 patchVersion
    );
}

interface ICedarPaymentSplitterEventsV0 is ICedarFactoryEventsV0 {
    event CedarPaymentSplitterDeployment(
        address indexed contractAddress,
        uint256 indexed majorVersion,
        uint256 indexed minorVersion,
        uint256 patchVersion,
        address[] payees,
        uint256[] shares
    );
}

interface ICedarDeployerEventsV7 is
    ICedarDeployerOwnEventsV0,
    ICedarERC721PremintFactoryEventsV0,
    ICedarERC721DropFactoryEventsV0,
    ICedarERC1155DropFactoryEventsV0,
    ICedarPaymentSplitterEventsV0
{

}

/// TODO[giorgos]: To be added at a later stage...
//interface ICedarDeployerEventsV6 is ICedarDeployerEventsV4 {
//    /// @dev Unified interface for drop contract deployment through the factory contracts
//    ///     Emitted when the `deploy()` from Factory contracts is called
//    ///     Works for both ERC721 and ERC1155, therefore the name of `NFT` instead of ERC-XXX
//    event CedarNFTDropV1Deployment(
//        address indexed contractAddress,
//        uint256 indexed majorVersion,
//        uint256 indexed minorVersion,
//        uint256 patchVersion,
//        address defaultAdmin,
//        string name,
//        string symbol,
//        string contractURI,
//        address[] trustedForwarders,
//        address saleRecipient,
//        address royaltyRecipient,
//        uint128 royaltyBps,
//        uint128 platformFeeBps,
//        address platformFeeRecipient
//    );
//}