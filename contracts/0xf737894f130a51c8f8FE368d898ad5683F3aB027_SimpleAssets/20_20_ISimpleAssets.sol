pragma solidity ^0.8.13;

import "IERC721MetadataUpgradeable.sol";

/**
    @title SimpleAsssets port following Voice internal data structure
  */
interface ISimpleAssets is IERC721MetadataUpgradeable {

    struct AssetsData {
        bytes32 category;
        mapping(bytes32 => bytes32) idata;
        bytes32[] idataKey;
        bytes32 jsonMeta;
    }

    event ImmutableValueAssigned(address indexed caller, uint256 indexed tokenId, string indexed key, string value);

    function burn(uint256 tokenId) external;

    function create(
        address owner,
        string memory jsonMeta)
    external;

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    function setBaseUri(string memory baseUri) external;

    function getBaseUri() external view virtual returns (string memory);
}