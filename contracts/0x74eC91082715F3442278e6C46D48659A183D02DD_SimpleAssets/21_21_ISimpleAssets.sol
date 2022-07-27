pragma solidity ^0.8.13;

import "IERC721MetadataUpgradeable.sol";

/**
    @title SimpleAsssets port following Voice internal data structure
  */
interface ISimpleAssets is IERC721MetadataUpgradeable {
    struct KeyValue
    {
        string key;
        string value;
    }

    struct AssetsData {
        bytes32 category;
        mapping(bytes32 => bytes32) idata;
        bytes32[] idataKey;
    }

    event ImmutableValueAssigned(address indexed caller, uint256 indexed tokenId, string indexed key, string value);

    function burn(uint256 tokenId) external;

    function create(
        address owner,
        string memory category,
        bytes32 jsonMeta,
        string memory baseUri)
    external;

    function getAssetsCategory(uint256 tokenId) external view returns (string memory category);

    function getAssetsIDataByIndex(
        uint256 tokenId,
        uint256 index
    )
    external
    view
    returns (
        string memory key,
        string memory value
    );

    function getAssetsIDataByKey(uint256 tokenId, string memory key) external view returns (string memory value);

    function getAssetsIDataLength(uint256 tokenId) external view returns (uint256 iDataLength);

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);
}