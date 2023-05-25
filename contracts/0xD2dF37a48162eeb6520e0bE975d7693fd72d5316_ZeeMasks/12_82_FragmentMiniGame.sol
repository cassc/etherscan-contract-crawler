// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";

import "../acl/access-controlled/AccessControlledUpgradeable.sol";
import "../common/BlockAware.sol";
import "./IFragmentMiniGame.sol";
import "./FragmentMiniGameStorage.sol";
import "./FragmentMiniGameUtils.sol";

contract FragmentMiniGame is
    IFragmentMiniGame,
    ERC1155Upgradeable,
    ERC1155BurnableUpgradeable,
    UUPSUpgradeable,
    AccessControlledUpgradeable,
    BlockAware,
    FragmentMiniGameStorage
{
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.Bytes32ToBytes32Map;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;
    using FragmentMiniGameUtils for FragmentGroup;
    using FragmentMiniGameUtils for bytes16;
    using FragmentMiniGameUtils for string;
    using FragmentMiniGameUtils for uint256;
    using FragmentMiniGameUtils for bytes32;
    using StringsUpgradeable for uint256;

    /// @dev Modifier for making sure that the group does not exist.
    modifier whenGroupDoesNotExist(string memory groupName) {
        bytes16 groupId = groupName.toGroupId();
        _checkGroupDoesNotExist(groupId);

        _;
    }

    /// @dev Modifier for making sure that the fragment group exists.
    modifier whenFragmentGroupExists(string memory groupName) {
        bytes16 groupId = groupName.toGroupId();
        _checkFragmentGroupExists(groupId);

        _;
    }

    /// @dev Modifier for making sure that the object group exists.
    modifier whenObjectGroupExists(string memory groupName) {
        bytes16 groupId = groupName.toGroupId();
        _checkObjectGroupExists(groupId);

        _;
    }

    /// @dev Constructor that gets called for the implementation contract.
    constructor() initializer {
        // solhint-disable-previous-line no-empty-blocks
    }

    // solhint-disable-next-line comprehensive-interface
    function initialize(
        address acl,
        string calldata baseUri,
        string calldata name_,
        string calldata symbol_
    ) external initializer {
        __BlockAware_init();
        __UUPSUpgradeable_init();
        __AccessControlled_init(acl);
        __ERC1155_init(baseUri);

        // Set metadata
        _name = name_;
        _symbol = symbol_;

        // Set the base URI
        _setBaseURI(baseUri);
    }

    /// @inheritdoc IFragmentMiniGame
    function setBaseURI(string calldata baseUri) external override onlyMaintainer {
        _setBaseURI(baseUri);
    }

    /// @inheritdoc IFragmentMiniGame
    function registerFragmentGroup(
        string calldata groupName,
        uint128[] calldata fragmentSupply,
        bytes32 secretHash,
        uint128 accountCap
    ) external override onlyMaintainer whenGroupDoesNotExist(groupName) {
        // Construct the real group ID
        bytes16 groupId = groupName.toGroupId();

        // Make sure that neither a fragment group nor an object group is registered under the same group id!
        if (accountCap == 0) revert AccountCapCannotBeZero();

        // Make sure that the group secret hash is unique
        FragmentGroup storage fragmentGroup = _fragmentGroups[groupId];
        if (_fragmentGroupIds[secretHash] != bytes16(0)) revert FragmentSecretAlreadyRegistered();

        // Associate the secret with the group id
        _fragmentGroupIds[secretHash] = groupId;

        // Associate the the group id with the group type
        _registeredGroups[groupId] = GroupType.Fragment;

        // Instantiate the fragment groups
        fragmentGroup.secretHash = secretHash;
        fragmentGroup.accountCap = accountCap;
        fragmentGroup.size = uint128(fragmentSupply.length);
        for (uint128 index = 0; index < fragmentSupply.length; index++) {
            if (fragmentSupply[index] == 0) revert FragmentSupplyMustBeGreaterThanZero();
            fragmentGroup.supply[index] = FragmentMiniGameUtils.toFragmentSupply(
                fragmentSupply[index],
                fragmentSupply[index]
            );
        }

        emit FragmentGroupRegistered(groupId);
    }

    /// @inheritdoc IFragmentMiniGame
    /// @dev Never post the `mintingRequirements` with duplicate tokenIds! That will result in undefined behaviour!
    function registerObjectGroup(string calldata groupName, MintRequirement[] calldata mintingRequirements)
        external
        override
        onlyMaintainer
        whenGroupDoesNotExist(groupName)
    {
        // Construct the real group ID
        bytes16 groupId = groupName.toGroupId();

        // Associate the the group id with the group type
        _registeredGroups[groupId] = GroupType.Object;

        // Instantiate the object group
        ObjectGroup storage objectGroup = _objectGroups[groupId];
        for (uint256 index = 0; index < mintingRequirements.length; index++) {
            uint256 tokenId = mintingRequirements[index].tokenId;
            (bytes16 dependantGroupId, uint128 tokenIndex) = parseTokenId(tokenId);

            // Make sure that the dependant groups token id is valid
            GroupType gt = _registeredGroups[dependantGroupId];

            // Depends on a fragment group.
            if (gt == GroupType.Fragment) {
                _checkFragmentGroupExists(dependantGroupId);
                _fragmentGroups[dependantGroupId].canProvideToken(
                    dependantGroupId,
                    tokenIndex,
                    mintingRequirements[index].necessaryTokenCount
                );
            }
            // Depends on an object group.
            else if (gt == GroupType.Object) {
                if (tokenIndex != 0) revert UnsupportedTokenIndex(dependantGroupId, tokenIndex);
                _checkObjectGroupExists(dependantGroupId);
            }
            // Group type is not supported.
            else {
                revert GroupDoesNotExist(dependantGroupId);
            }

            bytes32 necessaryNumber = bytes32(uint256(mintingRequirements[index].necessaryTokenCount));
            bytes32 tokenIdKey = bytes32(tokenId);
            objectGroup.mintingRequirements.set(tokenIdKey, necessaryNumber);
        }

        emit ObjectGroupRegistered(groupId);
    }

    /// @inheritdoc IFragmentMiniGame
    function deregisterGroup(string calldata groupName) external override onlyMaintainer {
        // Construct the real group ID
        bytes16 groupId = groupName.toGroupId();

        // Make sure that the dependant groups token id is valid
        GroupType gt = _registeredGroups[groupId];

        // We need to clear up a fragment group.
        if (gt == GroupType.Fragment) {
            FragmentGroup storage fg = _fragmentGroups[groupId];

            for (uint128 index = 0; index < fg.size; index++) {
                delete fg.supply[index];
                // NOTE: not clearing `fragmentCount` because we don't know the keys!
            }
            delete _fragmentGroupIds[fg.secretHash];
            delete _fragmentGroups[groupId];
        }
        // We need to clear up an object group
        else if (gt == GroupType.Object) {
            delete _objectGroups[groupId];
        } else {
            revert GroupDoesNotExist(groupId);
        }

        _registeredGroups[groupId] = GroupType.Unregistered;
        emit GroupDeregistered(groupId);
    }

    /// @inheritdoc IFragmentMiniGame
    function discover(string calldata fragmentSecret) external override {
        bytes32 secret = keccak256(abi.encodePacked(fragmentSecret));

        // Retrieve the group id from the secret
        bytes16 groupId = _fragmentGroupIds[secret];
        _checkFragmentGroupExists(groupId);
        FragmentGroup storage fg = _fragmentGroups[groupId];

        // Assert that the account can still mint
        if (fg.fragmentCount[msg.sender] >= fg.accountCap) revert MintingCapReached(msg.sender, groupId, fg.accountCap);

        // Determine which token index to mint
        uint256 sourceOfRandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, msg.sender))
        );
        uint128 index = uint128(sourceOfRandomness % fg.size);

        for (uint128 i = 0; i < fg.size; i++) {
            index = (index + 1) % fg.size;

            // Assert that there's still supply left to be minted.
            (uint128 supplyLeft, uint128 totalSupply) = fg.supply[index].deconstructFragmentSupply();
            if (supplyLeft == 0) continue;

            // Update the contracts mint state.
            fg.supply[index] = FragmentMiniGameUtils.toFragmentSupply(supplyLeft - 1, totalSupply);
            fg.fragmentCount[msg.sender] += 1;

            // Mint the Fragment NFT.
            uint256 tokenId = groupId.toFragmentTokenId(index);
            _mint(msg.sender, tokenId, 1, new bytes(0));

            emit FragmentMinted(msg.sender, tokenId);
            return; // Early return if we have minted the token
        }

        // Revert in a case where we cannot mint any token.
        revert AllItemsDiscovered(groupId);
    }

    /// @inheritdoc IFragmentMiniGame
    function collect(string calldata groupName) external override whenObjectGroupExists(groupName) {
        bytes16 groupId = groupName.toGroupId();

        ObjectGroup storage og = _objectGroups[groupId];
        bytes32[] memory childTokenIds = og.mintingRequirements._keys.values();

        // iterate over all token ids and check if the user has enough of them
        for (uint256 index = 0; index < childTokenIds.length; index++) {
            bytes32 tokenIdKey = childTokenIds[index];
            uint256 amountToBurn = uint256(og.mintingRequirements.get(tokenIdKey));

            // NOTE: the balance is already checked in the `_burn` function
            _burn(msg.sender, uint256(tokenIdKey), amountToBurn);
        }

        // Mint the object NFT
        uint256 objectTokenId = groupId.toObjectTokenId();
        _mint(msg.sender, objectTokenId, 1, new bytes(0));

        emit ObjectMinted(msg.sender, objectTokenId);
    }

    /// @inheritdoc IFragmentMiniGame
    function canCollect(address account, string calldata groupName)
        external
        view
        override
        whenObjectGroupExists(groupName)
        returns (bool)
    {
        bytes16 groupId = groupName.toGroupId();

        // Retrieve the object group
        ObjectGroup storage og = _objectGroups[groupId];
        bytes32[] memory childTokenIds = og.mintingRequirements._keys.values();

        // iterate over all token ids and check if the user has enough of them
        for (uint256 index = 0; index < childTokenIds.length; index++) {
            bytes32 tokenIdKey = childTokenIds[index];
            uint256 amountToBurn = uint256(og.mintingRequirements.get(tokenIdKey));

            if (balanceOf(account, uint256(tokenIdKey)) < amountToBurn) return false;
        }

        return true;
    }

    /// @inheritdoc IFragmentMiniGame
    function getFragmentGroup(string calldata groupName)
        external
        view
        override
        whenFragmentGroupExists(groupName)
        returns (
            bytes16 groupId,
            bytes32 secretHash,
            uint256[] memory tokenIds,
            uint128[] memory supplyLeft,
            uint128[] memory totalSupply
        )
    {
        // Retrieve the fragment group
        groupId = groupName.toGroupId();
        FragmentGroup storage fg = _fragmentGroups[groupId];

        // Populate the response
        secretHash = fg.secretHash;
        tokenIds = new uint256[](fg.size);
        supplyLeft = new uint128[](fg.size);
        totalSupply = new uint128[](fg.size);
        for (uint128 index = 0; index < fg.size; index++) {
            uint256 tokenId = groupId.toFragmentTokenId(index);
            (uint128 iSupplyLeft, uint128 iTotalSupply) = fg.supply[index].deconstructFragmentSupply();

            tokenIds[index] = tokenId;
            supplyLeft[index] = iSupplyLeft;
            totalSupply[index] = iTotalSupply;
        }
    }

    /// @inheritdoc IFragmentMiniGame
    function name() external view override returns (string memory) {
        return _name;
    }

    /// @inheritdoc IFragmentMiniGame
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /// @inheritdoc IFragmentMiniGame
    function owner() external view override returns (address) {
        return _getAcl().getRoleMember(Roles.NFT_OWNER, 0);
    }

    /// @inheritdoc IFragmentMiniGame
    function getMintedFragmentsCount(string calldata groupName, address account)
        external
        view
        override
        whenFragmentGroupExists(groupName)
        returns (uint256)
    {
        // Retrieve the group
        bytes16 groupId = groupName.toGroupId();
        FragmentGroup storage fg = _fragmentGroups[groupId];

        // Return the response
        return fg.fragmentCount[account];
    }

    /// @inheritdoc IFragmentMiniGame
    function getObjectGroup(string calldata groupName)
        external
        view
        override
        whenObjectGroupExists(groupName)
        returns (
            bytes16 groupId,
            uint256 tokenId,
            MintRequirement[] memory mintingRequirements
        )
    {
        // Retrieve the group
        groupId = groupName.toGroupId();
        ObjectGroup storage og = _objectGroups[groupId];

        // Get all token dependencies
        bytes32[] memory childTokenIds = og.mintingRequirements._keys.values();

        // Populate the response
        tokenId = groupId.toObjectTokenId();
        mintingRequirements = new MintRequirement[](childTokenIds.length);

        // Iterate over all of the keys (token Ids) and retrieve the necessary token count
        for (uint256 index = 0; index < childTokenIds.length; index++) {
            uint128 necessaryTokenCount = uint128(uint256(og.mintingRequirements.get(childTokenIds[index])));
            mintingRequirements[index] = MintRequirement({
                tokenId: uint256(childTokenIds[index]),
                necessaryTokenCount: necessaryTokenCount
            });
        }
    }

    /// @inheritdoc IFragmentMiniGame
    function constructTokenId(string calldata groupName, uint128 tokenIndex) external pure override returns (uint256) {
        return groupName.toGroupId().toFragmentTokenId(tokenIndex);
    }

    /// @inheritdoc IFragmentMiniGame
    function constructGroupId(string calldata groupName) external pure override returns (bytes16) {
        return groupName.toGroupId();
    }

    /// @inheritdoc IFragmentMiniGame
    function burn(
        address from,
        uint256 tokenId,
        uint256 amount
    ) public override(ERC1155BurnableUpgradeable, IFragmentMiniGame) onlyRole(Roles.FRAGMENT_MINI_GAME_BURN) {
        ERC1155BurnableUpgradeable.burn(from, tokenId, amount);
    }

    /// @inheritdoc IFragmentMiniGame
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public override(ERC1155BurnableUpgradeable, IFragmentMiniGame) onlyRole(Roles.FRAGMENT_MINI_GAME_BURN) {
        ERC1155BurnableUpgradeable.burnBatch(account, ids, values);
    }

    /// @inheritdoc ERC1155Upgradeable
    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(super.uri(tokenId), tokenId.toString()));
    }

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IFragmentMiniGame).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IFragmentMiniGame
    function parseTokenId(uint256 tokenId) public pure override returns (bytes16 groupId, uint128 tokenIndex) {
        // when converting bytes32 to bytes16, the first 16 bytes get saved, the last 16 get dropped
        groupId = bytes16(bytes32(tokenId));
        // when converting uint256 to uint128, the first 16 bytes get dropped, the last 16 get saved
        tokenIndex = uint128(tokenId);
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address) internal override onlyAdmin {
        // solhint-disable-previous-line no-empty-blocks
    }

    /// @dev set the base URI and emit an event.
    function _setBaseURI(string calldata baseUri) internal {
        _setURI(baseUri);

        emit UriSet(baseUri);
    }

    /// @notice Assert that an group does not exist with a given groupId.
    /// @param groupId The group ID that we want to query.
    function _checkGroupDoesNotExist(bytes16 groupId) internal view {
        if (_registeredGroups[groupId] != GroupType.Unregistered) revert GroupShouldNotExist(groupId);
    }

    /// @notice Assert that an fragment group either exists with the provided groupId.
    /// @param groupId The group ID that we want to query.
    function _checkFragmentGroupExists(bytes16 groupId) internal view {
        if (_registeredGroups[groupId] != GroupType.Fragment) revert FragmentGroupShouldExist(groupId);
    }

    /// @notice Assert that an object group either exists with the provided groupId.
    /// @param groupId The group ID that we want to query.
    function _checkObjectGroupExists(bytes16 groupId) internal view {
        if (_registeredGroups[groupId] != GroupType.Object) revert ObjectGroupShouldExist(groupId);
    }
}