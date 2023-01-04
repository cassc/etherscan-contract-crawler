// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC721Registry {
    struct TokenInfo {
        // Source address (target/implementation) used to create a new token instance.
        address source;
        // New clone address created by using the source contract address.
        address clone;
    }

    event TokenCreated(
        address indexed clone,
        address indexed source,
        uint256 maxCap,
        bytes32 key,
        string name,
        string symbol
    );

    event SourceChanged(address indexed source, bool added);

    function createToken(
        address source,
        bytes32 key,
        string calldata name,
        string calldata symbol,
        string calldata baseUri,
        uint256 maxCap,
        address admin,
        address minter
    ) external returns (address clonedToken);

    function updateSources(address[] calldata newSources, bool add) external;

    /** View Functions */

    function ADMIN_ROLE() external view returns (bytes32);

    function CONFIGURATOR_ROLE() external view returns (bytes32);

    function tokensInfoByKey(bytes32 key) external view returns (TokenInfo memory);

    function sources(address source) external view returns (bool);

    function keys() external view returns (bytes32[] memory);

    function containsKey(bytes32 key) external view returns (bool);

    function getTokenAddresses() external view returns (address[] memory addresses);

    function tokensBySource(address source) external view returns (address[] memory);
}