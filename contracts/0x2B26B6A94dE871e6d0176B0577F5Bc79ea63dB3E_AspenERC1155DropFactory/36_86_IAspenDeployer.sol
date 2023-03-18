// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "../impl/IAspenERC721Drop.sol";
import "../impl/IAspenERC1155Drop.sol";
import "../impl/IAspenPaymentSplitter.sol";
import "./types/DropFactoryDataTypes.sol";

// Events deployed by AspenDeployer directly (not by factories)
interface IAspenDeployerOwnEventsV1 {
    event AspenInterfaceDeployed(
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
interface IAspenDeployerV2 is IAspenDeployerOwnEventsV1, IAspenVersionedV2 {
    function deployAspenERC1155Drop(
        IDropFactoryDataTypesV0.TokenDetails memory _tokenDetails,
        IDropFactoryDataTypesV0.FeeDetails memory _feeDetails,
        bytes32 _operatorFiltererType
    ) external payable returns (IAspenERC1155DropV2);

    function deployAspenERC721Drop(
        IDropFactoryDataTypesV0.TokenDetails memory _tokenDetails,
        IDropFactoryDataTypesV0.FeeDetails memory _feeDetails,
        bytes32 _operatorFiltererType
    ) external payable returns (IAspenERC721DropV2);

    function deployAspenPaymentSplitter(address[] memory payees, uint256[] memory shares)
        external
        returns (IAspenPaymentSplitterV1);

    function getDeploymentFeeDetails() external view returns (uint256 _deploymentFee, address _feeReceiver);

    /// Versions
    function aspenERC721DropVersion()
        external
        view
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        );

    function aspenERC1155DropVersion()
        external
        view
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        );

    function aspenPaymentSplitterVersion()
        external
        view
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        );

    /// Features

    function aspenERC721DropFeatures() external view returns (string[] memory features);

    function aspenERC1155DropFeatures() external view returns (string[] memory features);

    function aspenPaymentSplitterFeatures() external view returns (string[] memory features);

    /// Interface Ids

    function aspenERC721DropInterfaceId() external view returns (string memory interfaceId);

    function aspenERC1155DropInterfaceId() external view returns (string memory interfaceId);

    function aspenPaymentSplitterInterfaceId() external view returns (string memory interfaceId);
}

interface ICedarFactoryEventsV0 {
    // Primarily for the benefit of Etherscan verification
    event AspenImplementationDeployed(
        address indexed implementationAddress,
        uint256 indexed majorVersion,
        uint256 indexed minorVersion,
        uint256 patchVersion,
        string contractName
    );
}

interface IAspenFactoryEventsV0 {
    // Primarily for the benefit of Etherscan verification
    event AspenImplementationDeployed(
        address indexed implementationAddress,
        uint256 indexed majorVersion,
        uint256 indexed minorVersion,
        uint256 patchVersion,
        string contractName
    );
}

/// Factory specific events (emitted by factories, but included in ICedarDeployer interfaces because they can be
/// expected to be emitted on transactions that call the deploy functions

interface IAspenERC721PremintFactoryEventsV1 is IAspenFactoryEventsV0 {
    event AspenERC721PremintDeployment(
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

interface IAspenERC721DropFactoryEventsV0 is IAspenFactoryEventsV0 {
    event AspenERC721DropV2Deployment(
        address indexed contractAddress,
        uint256 indexed majorVersion,
        uint256 indexed minorVersion,
        uint256 patchVersion
    );
}

interface IAspenERC1155DropFactoryEventsV0 is IAspenFactoryEventsV0 {
    event AspenERC1155DropV2Deployment(
        address indexed contractAddress,
        uint256 indexed majorVersion,
        uint256 indexed minorVersion,
        uint256 patchVersion
    );
}

interface IAspenPaymentSplitterEventsV0 is IAspenFactoryEventsV0 {
    event AspenPaymentSplitterDeployment(
        address indexed contractAddress,
        uint256 indexed majorVersion,
        uint256 indexed minorVersion,
        uint256 patchVersion,
        address[] payees,
        uint256[] shares
    );
}

interface IDropFactoryEventsV0 is IAspenFactoryEventsV0 {
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
        address saleRecipient,
        address defaultRoyaltyRecipient,
        uint128 defaultRoyaltyBps,
        string userAgreement,
        uint128 platformFeeBps,
        address platformFeeRecipient
    );
}

interface IDropFactoryEventsV1 is IAspenFactoryEventsV0 {
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
        bytes32 operatorFiltererId
    );
}