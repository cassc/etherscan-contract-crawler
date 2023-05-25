// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

interface IFragmentMiniGame {
    /// @notice Emitted when a fragment group has been registered.
    event FragmentGroupRegistered(bytes16 groupId);

    /// @notice Emitted when an object group has been registered.
    event ObjectGroupRegistered(bytes16 groupId);

    /// @notice Emitted when a group has been deregistered.
    event GroupDeregistered(bytes16 groupId);

    /// @notice Emitted when the base URI has been set.
    event UriSet(string newUri);

    /// @notice Emitted when a fragment group has been minted.
    event FragmentMinted(address account, uint256 tokenId);

    /// @notice Emitted when an object group has been minted.
    event ObjectMinted(address account, uint256 tokenId);

    /// @notice Thrown when the Object group at a given groupId does not exist.
    error ObjectGroupShouldExist(bytes16 groupId);

    /// @notice Thrown when attempting to perform operations on a group that is not registered.
    error GroupDoesNotExist(bytes16 groupId);

    /// @notice Thrown when the group at a given groupId exists but it shouldn't.
    error GroupShouldNotExist(bytes16 groupId);

    /// @notice Thrown when the Fragment group at a given groupId does not exist.
    error FragmentGroupShouldExist(bytes16 groupId);

    /// @notice Thrown when expecting the group to have support for the tokenIndex but it does not support it.
    error UnsupportedTokenIndex(bytes16 groupId, uint128 tokenIndex);

    /// @notice Thrown when the max supply cannot be met for a given tokenId.
    error ImpossibleExpectedSupply(uint256 tokenId, uint256 necessarySupply);

    /// @notice Thrown when the fragment secret is already used for another fragment group.
    error FragmentSecretAlreadyRegistered();

    /// @notice Thrown when the supply of a fragment is larger than 0.
    error FragmentSupplyMustBeGreaterThanZero();

    /// @notice Thrown when the fragment groups account cap is specified at 0.
    error AccountCapCannotBeZero();

    /// @notice Thrown when all fragments have been already minted.
    error AllItemsDiscovered(bytes16 groupId);

    /// @notice Thrown when a user has minted the allowed amount of fragments in his a group.
    error MintingCapReached(address account, bytes16 groupId, uint256 accountCap);

    /// @notice Mint requirements are defined for object groups, they define the dependant
    ///         tokenIds and their corresponding amounts to be able to mint a given object NFT.
    struct MintRequirement {
        uint256 tokenId; // key
        uint128 necessaryTokenCount; // value
    }

    /// @notice Register a new Fragment group that can be discovered with a secret phrase.
    /// @param groupName A unique name for the group.
    /// @param fragmentSupply The amount of fragments that can be minted. The index of the item determines the token ID.
    /// @param secretHash The keccak256 hash of the secret that is used to discover the fragments.
    /// @param accountCap The maximum amount of fragments that can be minted by a single account.
    function registerFragmentGroup(
        string calldata groupName,
        uint128[] calldata fragmentSupply,
        bytes32 secretHash,
        uint128 accountCap
    ) external;

    /// @notice Register a new Object group that can created by owning all of the required tokenIds.
    /// @param groupName A unique name for the group.
    /// @param mintingRequirements The minting requirements for the group.
    function registerObjectGroup(string calldata groupName, MintRequirement[] calldata mintingRequirements) external;

    /// @notice Deregister a group.
    /// @param groupName The name of the group that already has been registered.
    function deregisterGroup(string calldata groupName) external;

    /// @notice Try to mint a new fragment NFT by providing a secret.
    /// @param fragmentSecret The secret phrase that is used to discover the fragments.
    function discover(string calldata fragmentSecret) external;

    /// @notice Combine all of the necessary fragments or subgroup NFTs to create an object NFT.
    /// @param groupName The name of the group for which we need to check the requirements and attempt to mint.
    function collect(string calldata groupName) external;

    /// @notice Set the base URI for the tokens.
    /// @param baseURI The base URI for the tokens.
    function setBaseURI(string calldata baseURI) external;

    /// @notice Get the name of the contract
    /// @return The name of the contract.
    function name() external view returns (string memory);

    /// @notice Get the symbol of the contract
    /// @return The symbol of the contract.
    function symbol() external view returns (string memory);

    /// @notice Get the owner of the contract.
    /// @return The owner of the contract.
    function owner() external view returns (address);

    /// @notice Check if the given account is able to mint the given object group.
    /// @param account The account that is trying to mint the object group.
    /// @param groupName The name of the group that is being minted.
    /// @return True if the NFT can be minted.
    function canCollect(address account, string calldata groupName) external view returns (bool);

    /// @notice Burn an arbitrary token.
    /// @param from Address of the account for which we want to burn the tokens.
    /// @param tokenId The tokenId of the token to burn.
    /// @param amount The amount of tokens that we want to burn.
    function burn(
        address from,
        uint256 tokenId,
        uint256 amount
    ) external;

    /// @notice Burn multiples of arbitrary tokens.
    /// @param account Address of the account for which we want to burn the tokens.
    /// @param ids The tokenIds of the tokens to burn.
    /// @param values The amounts of tokens that we want to burn, index corresponds to `ids`.
    function burnBatch(
        address account,
        uint256[] calldata ids,
        uint256[] calldata values
    ) external;

    /// @notice Retrieve information about a fragment group
    /// @param groupName The name of the group that we want to query.
    /// @return groupId The unique group identifier.
    /// @return secretHash The hash of the secret used for discovering items fom the group.
    /// @return tokenIds The tokenIds of the fragments in the group.
    /// @return supplyLeft The amount of fragments left to mint, index corresponds to `tokenIds`.
    /// @return totalSupply The total amount of fragments that can be minted, index corresponds to `tokenIds`.
    function getFragmentGroup(string calldata groupName)
        external
        view
        returns (
            bytes16 groupId,
            bytes32 secretHash,
            uint256[] memory tokenIds,
            uint128[] memory supplyLeft,
            uint128[] memory totalSupply
        );

    /// @notice Get the number of minted fragments for a given user account.
    /// @param groupName The name of the group that we want to query.
    /// @param account The address of the account for which we want to query the number of minted fragments.
    /// @return number The number of minted fragments for the given user account.
    function getMintedFragmentsCount(string calldata groupName, address account) external view returns (uint256);

    /// @notice Retrieve information about an Object group.
    /// @param groupName The name of the group that we want to query.
    /// @return groupId The unique group identifier.
    /// @return tokenId The tokenId that can be minted by the object group.
    /// @return mintingRequirements The minting requirements for the object group.
    function getObjectGroup(string calldata groupName)
        external
        view
        returns (
            bytes16 groupId,
            uint256 tokenId,
            MintRequirement[] calldata mintingRequirements
        );

    /// @notice construct the token id for a given group.
    /// @param groupName The name of the group that we want to query.
    /// @param tokenIndex The index of the token in the group.
    /// @return tokenId The tokenId of the token at the given index for the group.
    /// @dev if the group refers to an object group, the tokenIndex is `0`.
    function constructTokenId(string calldata groupName, uint128 tokenIndex) external pure returns (uint256);

    /// @notice construct the group id for a given group.
    /// @param groupName The name of the group that we want to query.
    /// @return groupId The groupId of the group.
    function constructGroupId(string calldata groupName) external pure returns (bytes16);

    /// @notice Deconstruct a token id into its sub-components.
    /// @param tokenId The tokenId that we want to deconstruct.
    /// @return groupId The groupId of the group retrieved from the tokenId.
    /// @return tokenIndex The index of the token retrieved from the tokenId.
    function parseTokenId(uint256 tokenId) external pure returns (bytes16 groupId, uint128 tokenIndex);
}