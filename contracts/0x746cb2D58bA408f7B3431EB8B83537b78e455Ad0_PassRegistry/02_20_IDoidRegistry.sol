// SPDX-License-Identifier: None
pragma solidity >=0.8.4;

interface IDoidRegistry {
    event NameMigrated(uint256 indexed id, address indexed owner, uint256 expires);
    event NameRegistered(uint256 indexed id, string indexed name, address indexed owner);
    event NameRenewed(uint256 indexed id, uint256 expires);

    struct DoidInfo {
        uint256 tokenId;
        string name;
    }

    /**
     * @dev Request user's tokens
     * @return tokenIds.
     */
    function tokensOfOwner(address _user) external view returns (uint256[] memory);

    /**
     * @dev Request user's names
     * @return names with tokenId.
     */
    function namesOfOwner(address _user) external view returns (DoidInfo[] memory);

    /**
     * @dev Request status of a name
     * @return status 'available' or 'registered' or 'locked', or 'reserved'.
     * @return owner address that owns or locks this name
     * @return id token id of name (if registered) or pass (if locked) or 0 (if available or reserved).
     */
    function statusOfName(
        string memory name
    ) external view returns (string memory status, address owner, uint id);

    function nameHash(string memory name) external view returns (bytes32);

    function valid(string memory name) external pure returns (bool);

    function available(string memory name) external view returns (bool);

    function available(uint256 id) external view returns (bool);

    function makeCommitment(
        string memory name,
        address owner,
        bytes32 secret,
        bytes[] calldata data
    ) external pure returns (bytes32);

    function commit(bytes32 commitment) external;

    function register(
        string calldata name,
        address owner,
        bytes32 secret,
        bytes[] calldata data
    ) external;

    /**
     * @dev Claim a locked name for PassRegistry.
     * @notice Can only be called by PassRegistry.
     */
    function claimLockedName(string memory name, address owner) external;
}