// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "../impl/ICedarERC721Drop.sol";
import "../impl/ICedarERC1155Drop.sol";
import "../impl/ICedarPaymentSplitter.sol";

// Events deployed by CedarDeployer directly (not by factories)
interface ICedarDeployerOwnEventsV1 {
    event CedarInterfaceDeployed(
        address indexed contractAddress,
        uint256 indexed majorVersion,
        uint256 indexed minorVersion,
        uint256 patchVersion,
        string implementationInterfaceId
    );
}

// Update this interface by bumping the version then updating in-place.
// Previous versions will be immortalised in manifest but do not need to be kept around to clutter
// solidity code
interface ICedarDeployerV10 is ICedarDeployerOwnEventsV1, ICedarVersionedV2 {
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
    ) external payable returns (ICedarERC1155DropV5);

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
    ) external payable returns (ICedarERC721DropV7);

    function deployCedarPaymentSplitterV2(address[] memory payees, uint256[] memory shares)
        external
        returns (ICedarPaymentSplitterV2);

    /// Versions
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

interface ICedarERC721PremintFactoryEventsV1 is ICedarFactoryEventsV0 {
    event CedarERC721PremintDeployment(
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

interface IDropFactoryEventsV0 is ICedarFactoryEventsV0 {
    /// @dev Unified interface for drop contract deployment through the factory contracts
    ///     Emitted when the `deploy()` from Factory contracts is called
    event DropContractDeployment(
        address indexed contractAddress,
        uint256 indexed majorVersion,
        uint256 indexed minorVersion,
        uint256 patchVersion,
        address adminAddress,
        string name,
        string symbol,
        //        string contractURI,
        //        address[] trustedForwarders,
        address saleRecipient,
        address defaultRoyaltyRecipient,
        uint128 defaultRoyaltyBps,
        string userAgreement,
        uint128 platformFeeBps,
        address platformFeeRecipient
    );
}