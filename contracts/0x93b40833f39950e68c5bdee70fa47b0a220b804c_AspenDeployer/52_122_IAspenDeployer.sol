// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "../impl/IAspenERC721Drop.sol";
import "../impl/IAspenERC1155Drop.sol";
import "../impl/IAspenPaymentSplitter.sol";
import "./types/DropFactoryDataTypes.sol";
import "../config/types/TieredPricingDataTypes.sol";

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
interface IAspenDeployerV3 is IAspenDeployerOwnEventsV1, IAspenVersionedV2 {
    event DeploymentFeePaid(
        address indexed from,
        address indexed to,
        address indexed dropContractAddress,
        address currency,
        uint256 feeAmount
    );

    function deployAspenERC1155Drop(
        IDropFactoryDataTypesV2.TokenDetails memory _tokenDetails,
        IDropFactoryDataTypesV2.FeeDetails memory _feeDetails,
        bytes32 _operatorFiltererType
    ) external payable returns (IAspenERC1155DropV3);

    function deployAspenERC721Drop(
        IDropFactoryDataTypesV2.TokenDetails memory _tokenDetails,
        IDropFactoryDataTypesV2.FeeDetails memory _feeDetails,
        bytes32 _operatorFiltererType
    ) external payable returns (IAspenERC721DropV3);

    function deployAspenSBT721Drop(
        IDropFactoryDataTypesV2.TokenDetails memory _tokenDetails,
        IDropFactoryDataTypesV2.FeeDetails memory _feeDetails,
        bytes32 _operatorFiltererType
    ) external payable returns (IAspenERC721DropV3);

    function deployAspenPaymentSplitter(address[] memory payees, uint256[] memory shares)
        external
        returns (IAspenPaymentSplitterV2);

    function getDeploymentFeeDetails(address _account)
        external
        view
        returns (
            address feeReceiver,
            uint256 price,
            address currency
        );

    function getDefaultDeploymentFeeDetails()
        external
        view
        returns (
            address feeReceiver,
            uint256 price,
            address currency
        );

    /// Versions
    function aspenERC721DropVersion()
        external
        view
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        );

    function aspenSBT721DropVersion()
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

    function aspenERC721DropFeatureCodes() external view returns (uint256[] memory codes);

    function aspenSBT721DropFeatureCodes() external view returns (uint256[] memory codes);

    function aspenERC1155DropFeatureCodes() external view returns (uint256[] memory codes);

    function aspenPaymentSplitterFeatureCodes() external view returns (uint256[] memory codes);

    /// Interface Ids

    function aspenERC721DropInterfaceId() external view returns (string memory interfaceId);

    function aspenSBT721DropInterfaceId() external view returns (string memory interfaceId);

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