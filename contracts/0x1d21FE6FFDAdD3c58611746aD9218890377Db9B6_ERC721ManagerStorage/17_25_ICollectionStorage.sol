// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

interface ICollectionStorage {
    // Getter functions
    //
    function getName() external view returns (string memory);

    function getSymbol() external view returns (string memory);

    function getBaseURI() external view returns (string memory);

    function getCollectionMoved() external view returns (bool);

    function getMovementNoticeURI() external view returns (string memory);

    function getTotalSupply() external view returns (uint256);

    function getTokenIdsCount() external view returns (uint256);

    function getTokenIdByIndex(uint256 _index) external view returns (uint256);

    function getOwner(uint256 tokenId) external view returns (address);

    function getBalance(address _address) external view returns (uint256);

    function getTokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);

    function getTokenApproval(uint256 _tokenId) external view returns (address);

    function getOperatorApproval(address _owner, address _operator) external view returns (bool);

    function getRoyaltyReceiver() external view returns (address);

    function getRoyaltyFraction() external view returns (uint96);

    function getRoyaltyInfo() external view returns (address, uint96);

    function getCollectionManagerProxyAddress() external view returns (address);

    function getCollectionManagerHelperProxyAddress() external view returns (address);

    // Setter functions
    //
    function setName(string calldata _name) external;

    function setSymbol(string calldata _symbol) external;

    function setBaseURI(string calldata _baseURI) external;

    function setCollectionMoved(bool _collectionMoved) external;

    function setMovementNoticeURI(string calldata _movementNoticeURI) external;

    function setTotalSupply(uint256 _value) external;

    function setTokenIdByIndex(uint256 _tokenId, uint256 _index) external;

    function pushTokenId(uint256 _tokenId) external;

    function popTokenId() external;

    function setOwner(uint256 tokenId, address owner) external;

    function setTokenOfOwnerByIndex(address _owner, uint256 _index, uint256 _tokenId) external;

    function pushTokenOfOwner(address _owner, uint256 _tokenId) external;

    function popTokenOfOwner(address _owner) external;

    function setTokenApproval(uint256 _tokenId, address _address) external;

    function setOperatorApproval(address _owner, address _operator, bool _approved) external;

    function setRoyaltyInfo(address receiver, uint96 fraction) external;

    function setCollectionManagerProxyAddress(address _collectionManagerProxyAddress) external;

    function setCollectionManagerHelperProxyAddress(
        address _collectionManagerHelperProxyAddress
    ) external;
}