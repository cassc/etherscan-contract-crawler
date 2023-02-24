// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;

import "../../type/ITokenTypes.sol";

interface IPropertyV2 is ITokenTypes {
    enum PropertyAccessType {
        OPERATOR_ONLY,
        WALLET_ONLY,
        MIXED,
        CUSTOM
    }

    struct Property {
        PropertyAccessType accessType;
        TokenStandart feeTokenStandart;
        TransferredToken feeToken;
        string metadataURI;
        bool isActive;
    }

    event CreateProperty(address indexed sender, uint256 propertyId, Property propertySettings, uint256 timestamp);

    event EditProperty(address indexed sender, uint256 propertyId, Property propertySettings, uint256 timestamp);

    event SetPropertyValue(
        address indexed sender,
        uint256 indexed profileId,
        uint256 indexed propertyId,
        bytes32 newValue,
        bytes signature,
        uint256 timestamp
    );

    function createProperty(Property memory propertySettings) external returns (uint256 propertyId);

    function editProperty(uint256 propertyId, Property memory propertySettings) external;

    function setPropertyValue(
        uint256 profileId,
        uint256 propertyId,
        bytes32 newValue,
        bytes memory signature
    ) external;

    function propertyDetails(uint256 propertyId) external view returns (Property memory);

    function getPropertyValue(uint256 profileId, uint256 propertyId) external view returns (bytes32);

    function totalProperties() external view returns (uint256);
}