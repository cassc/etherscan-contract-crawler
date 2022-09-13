// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { ReentrancyGuard } from "../dependencies/openzeppelin/ReentrancyGuard.sol";
import { Pausable } from "../dependencies/openzeppelin/Pausable.sol";

import { IProfileNFT } from "../interfaces/IProfileNFT.sol";
import { IUpgradeable } from "../interfaces/IUpgradeable.sol";
import { IEssenceNFT } from "../interfaces/IEssenceNFT.sol";
import { IProfileDeployer } from "../interfaces/IProfileDeployer.sol";

import { Constants } from "../libraries/Constants.sol";
import { DataTypes } from "../libraries/DataTypes.sol";
import { Actions } from "../libraries/Actions.sol";

import { CyberNFTBase } from "../base/CyberNFTBase.sol";
import { ProfileNFTStorage } from "../storages/ProfileNFTStorage.sol";

/**
 * @title Profile NFT
 * @author CyberConnect
 * @notice This contract is used to create a profile NFT.
 */
contract ProfileNFT is
    Pausable,
    ReentrancyGuard,
    CyberNFTBase,
    UUPSUpgradeable,
    ProfileNFTStorage,
    IUpgradeable,
    IProfileNFT
{
    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/

    /* solhint-disable var-name-mixedcase */

    address public immutable SUBSCRIBE_BEACON;
    address public immutable ESSENCE_BEACON;
    address public immutable ENGINE;

    /* solhint-enable var-name-mixedcase */

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Checks that the profile owner is the sender address.
     */
    modifier onlyProfileOwner(uint256 profileId) {
        require(ownerOf(profileId) == msg.sender, "ONLY_PROFILE_OWNER");
        _;
    }

    /**
     * @notice Checks that the profile owner or operator is the sender address.
     */
    modifier onlyProfileOwnerOrOperator(uint256 profileId) {
        require(
            ownerOf(profileId) == msg.sender ||
                getOperatorApproval(profileId, msg.sender),
            "ONLY_PROFILE_OWNER_OR_OPERATOR"
        );
        _;
    }

    /**
     * @notice Checks that the namespace owner is the sender address.
     */
    modifier onlyNamespaceOwner() {
        require(_namespaceOwner == msg.sender, "ONLY_NAMESPACE_OWNER");
        _;
    }

    /**
     * @notice Checks that the CyberEngine is the sender address.
     */
    modifier onlyEngine() {
        require(ENGINE == msg.sender, "ONLY_ENGINE");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        (
            address engine,
            address subBeacon,
            address essenceBeacon
        ) = IProfileDeployer(msg.sender).profileParams();
        require(engine != address(0), "ENGINE_NOT_SET");
        require(subBeacon != address(0), "SUBSCRIBE_BEACON_NOT_SET");
        require(essenceBeacon != address(0), "ESSENCE_BEACON_NOT_SET");
        ENGINE = engine;
        SUBSCRIBE_BEACON = subBeacon;
        ESSENCE_BEACON = essenceBeacon;
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IProfileNFT
    function initialize(
        address _owner,
        string calldata name,
        string calldata symbol
    ) external override initializer {
        require(_owner != address(0), "ZERO_ADDRESS");
        _namespaceOwner = _owner;
        CyberNFTBase._initialize(name, symbol);
        ReentrancyGuard.__ReentrancyGuard_init();
        _pause();
        emit Initialize(_owner, name, symbol);
    }

    /// @inheritdoc IProfileNFT
    function createProfile(
        DataTypes.CreateProfileParams calldata params,
        bytes calldata preData,
        bytes calldata postData
    ) external payable override nonReentrant returns (uint256 tokenID) {
        return _createProfile(params, preData, postData);
    }

    /// @inheritdoc IProfileNFT
    function subscribe(
        DataTypes.SubscribeParams calldata params,
        bytes[] calldata preDatas,
        bytes[] calldata postDatas
    ) external override nonReentrant returns (uint256[] memory) {
        return _subscribe(msg.sender, params, preDatas, postDatas);
    }

    /// @inheritdoc IProfileNFT
    function subscribeWithSig(
        DataTypes.SubscribeParams calldata params,
        bytes[] calldata preDatas,
        bytes[] calldata postDatas,
        address sender,
        DataTypes.EIP712Signature calldata sig
    ) external override nonReentrant returns (uint256[] memory) {
        // let _subscribe handle length check
        uint256 preLength = preDatas.length;
        bytes32[] memory preHashes = new bytes32[](preLength);
        for (uint256 i = 0; i < preLength; ) {
            preHashes[i] = keccak256(preDatas[i]);
            unchecked {
                ++i;
            }
        }
        uint256 postLength = postDatas.length;
        bytes32[] memory postHashes = new bytes32[](postLength);
        for (uint256 i = 0; i < postLength; ) {
            postHashes[i] = keccak256(postDatas[i]);
            unchecked {
                ++i;
            }
        }

        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._SUBSCRIBE_TYPEHASH,
                        keccak256(abi.encodePacked(params.profileIds)),
                        keccak256(abi.encodePacked(preHashes)),
                        keccak256(abi.encodePacked(postHashes)),
                        nonces[sender]++,
                        sig.deadline
                    )
                )
            ),
            sender,
            sig
        );
        return _subscribe(sender, params, preDatas, postDatas);
    }

    /// @inheritdoc IProfileNFT
    function collect(
        DataTypes.CollectParams calldata params,
        bytes calldata preData,
        bytes calldata postData
    ) external override nonReentrant returns (uint256 tokenId) {
        return _collect(params, preData, postData);
    }

    /// @inheritdoc IProfileNFT
    function collectWithSig(
        DataTypes.CollectParams calldata params,
        bytes calldata preData,
        bytes calldata postData,
        address sender,
        DataTypes.EIP712Signature calldata sig
    ) external override nonReentrant returns (uint256 tokenId) {
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._COLLECT_TYPEHASH,
                        params.collector,
                        params.profileId,
                        params.essenceId,
                        keccak256(preData),
                        keccak256(postData),
                        nonces[sender]++,
                        sig.deadline
                    )
                )
            ),
            sender,
            sig
        );
        return _collect(params, preData, postData);
    }

    /// @inheritdoc IProfileNFT
    function registerEssence(
        DataTypes.RegisterEssenceParams calldata params,
        bytes calldata initData
    )
        external
        override
        onlyProfileOwnerOrOperator(params.profileId)
        returns (uint256)
    {
        return _registerEssence(params, initData);
    }

    /// @inheritdoc IProfileNFT
    function registerEssenceWithSig(
        DataTypes.RegisterEssenceParams calldata params,
        bytes calldata initData,
        DataTypes.EIP712Signature calldata sig
    ) external override returns (uint256 tokenId) {
        address owner = ownerOf(params.profileId);
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._REGISTER_ESSENCE_TYPEHASH,
                        params.profileId,
                        keccak256(bytes(params.name)),
                        keccak256(bytes(params.symbol)),
                        keccak256(bytes(params.essenceTokenURI)),
                        params.essenceMw,
                        params.transferable,
                        keccak256(initData),
                        nonces[owner]++,
                        sig.deadline
                    )
                )
            ),
            owner,
            sig
        );
        return _registerEssence(params, initData);
    }

    /// @inheritdoc IProfileNFT
    function pause(bool toPause) external override onlyNamespaceOwner {
        if (toPause) {
            super._pause();
        } else {
            super._unpause();
        }
    }

    /// @inheritdoc IProfileNFT
    function setNamespaceOwner(address owner)
        external
        override
        onlyNamespaceOwner
    {
        require(owner != address(0), "ZERO_ADDRESS");
        _namespaceOwner = owner;

        emit SetNamespaceOwner(msg.sender, owner);
    }

    /// @inheritdoc IProfileNFT
    function setNFTDescriptor(address descriptor)
        external
        override
        onlyNamespaceOwner
    {
        require(descriptor != address(0), "ZERO_ADDRESS");
        _nftDescriptor = descriptor;
        emit SetNFTDescriptor(descriptor);
    }

    /// @inheritdoc IProfileNFT
    function setAvatar(uint256 profileId, string calldata avatar)
        external
        override
        onlyProfileOwnerOrOperator(profileId)
    {
        _setAvatar(profileId, avatar);
    }

    /// @inheritdoc IProfileNFT
    function setAvatarWithSig(
        uint256 profileId,
        string calldata avatar,
        DataTypes.EIP712Signature calldata sig
    ) external override {
        address owner = ownerOf(profileId);
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._SET_AVATAR_TYPEHASH,
                        profileId,
                        keccak256(bytes(avatar)),
                        nonces[owner]++,
                        sig.deadline
                    )
                )
            ),
            owner,
            sig
        );
        _setAvatar(profileId, avatar);
    }

    /// @inheritdoc IProfileNFT
    function setOperatorApproval(
        uint256 profileId,
        address operator,
        bool approved
    ) external override onlyProfileOwner(profileId) {
        _setOperatorApproval(profileId, operator, approved);
    }

    /// @inheritdoc IProfileNFT
    function setMetadata(uint256 profileId, string calldata metadata)
        external
        override
        onlyProfileOwnerOrOperator(profileId)
    {
        _setMetadata(profileId, metadata);
    }

    /// @inheritdoc IProfileNFT
    function setMetadataWithSig(
        uint256 profileId,
        string calldata metadata,
        DataTypes.EIP712Signature calldata sig
    ) external override {
        address owner = ownerOf(profileId);
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._SET_METADATA_TYPEHASH,
                        profileId,
                        keccak256(bytes(metadata)),
                        nonces[owner]++,
                        sig.deadline
                    )
                )
            ),
            owner,
            sig
        );
        _setMetadata(profileId, metadata);
    }

    /// @inheritdoc IProfileNFT
    function setSubscribeData(
        uint256 profileId,
        string calldata uri,
        address mw,
        bytes calldata data
    ) external override onlyProfileOwnerOrOperator(profileId) {
        _setSubscribeData(profileId, uri, mw, data);
    }

    /// @inheritdoc IProfileNFT
    function setSubscribeDataWithSig(
        uint256 profileId,
        string calldata uri,
        address mw,
        bytes calldata data,
        DataTypes.EIP712Signature calldata sig
    ) external override {
        address owner = ownerOf(profileId);
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._SET_SUBSCRIBE_DATA_TYPEHASH,
                        profileId,
                        keccak256(bytes(uri)),
                        mw,
                        keccak256(data),
                        nonces[owner]++,
                        sig.deadline
                    )
                )
            ),
            owner,
            sig
        );
        _setSubscribeData(profileId, uri, mw, data);
    }

    /// @inheritdoc IProfileNFT
    function setEssenceData(
        uint256 profileId,
        uint256 essenceId,
        string calldata uri,
        address mw,
        bytes calldata data
    ) external override onlyProfileOwnerOrOperator(profileId) {
        _setEssenceData(profileId, essenceId, uri, mw, data);
    }

    /// @inheritdoc IProfileNFT
    function setEssenceDataWithSig(
        uint256 profileId,
        uint256 essenceId,
        string calldata uri,
        address mw,
        bytes calldata data,
        DataTypes.EIP712Signature calldata sig
    ) external override {
        address owner = ownerOf(profileId);
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._SET_ESSENCE_DATA_TYPEHASH,
                        profileId,
                        essenceId,
                        keccak256(bytes(uri)),
                        mw,
                        keccak256(data),
                        nonces[owner]++,
                        sig.deadline
                    )
                )
            ),
            owner,
            sig
        );
        _setEssenceData(profileId, essenceId, uri, mw, data);
    }

    /// @inheritdoc IProfileNFT
    function setPrimaryProfile(uint256 profileId)
        external
        override
        onlyProfileOwnerOrOperator(profileId)
    {
        _setPrimaryProfile(msg.sender, profileId);
    }

    /// @inheritdoc IProfileNFT
    function setPrimaryProfileWithSig(
        uint256 profileId,
        DataTypes.EIP712Signature calldata sig
    ) external override {
        address owner = ownerOf(profileId);
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._SET_PRIMARY_PROFILE_TYPEHASH,
                        profileId,
                        nonces[owner]++,
                        sig.deadline
                    )
                )
            ),
            owner,
            sig
        );
        _setPrimaryProfile(owner, profileId);
    }

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IUpgradeable
    function version() external pure virtual override returns (uint256) {
        return _VERSION;
    }

    /// @inheritdoc IProfileNFT
    function getSubscribeMw(uint256 profileId)
        external
        view
        override
        returns (address)
    {
        _requireMinted(profileId);
        return _subscribeByProfileId[profileId].subscribeMw;
    }

    /// @inheritdoc IProfileNFT
    function getPrimaryProfile(address user)
        external
        view
        override
        returns (uint256)
    {
        return _addressToPrimaryProfile[user];
    }

    /// @inheritdoc IProfileNFT
    function getSubscribeNFT(uint256 profileId)
        external
        view
        override
        returns (address)
    {
        _requireMinted(profileId);
        return _subscribeByProfileId[profileId].subscribeNFT;
    }

    /// @inheritdoc IProfileNFT
    function getSubscribeNFTTokenURI(uint256 profileId)
        external
        view
        override
        returns (string memory)
    {
        _requireMinted(profileId);
        return _subscribeByProfileId[profileId].tokenURI;
    }

    /// @inheritdoc IProfileNFT
    function getMetadata(uint256 profileId)
        external
        view
        override
        returns (string memory)
    {
        _requireMinted(profileId);
        return _metadataById[profileId];
    }

    /// @inheritdoc IProfileNFT
    function getAvatar(uint256 profileId)
        external
        view
        override
        returns (string memory)
    {
        _requireMinted(profileId);
        return _profileById[profileId].avatar;
    }

    /// @inheritdoc IProfileNFT
    function getEssenceNFT(uint256 profileId, uint256 essenceId)
        external
        view
        override
        returns (address)
    {
        _requireMinted(profileId);
        _requireEssenceRegistered(profileId, essenceId);
        return _essenceByIdByProfileId[profileId][essenceId].essenceNFT;
    }

    /// @inheritdoc IProfileNFT
    function getEssenceNFTTokenURI(uint256 profileId, uint256 essenceId)
        external
        view
        override
        returns (string memory)
    {
        _requireMinted(profileId);
        _requireEssenceRegistered(profileId, essenceId);
        return _essenceByIdByProfileId[profileId][essenceId].tokenURI;
    }

    /// @inheritdoc IProfileNFT
    function getEssenceMw(uint256 profileId, uint256 essenceId)
        external
        view
        override
        returns (address)
    {
        _requireMinted(profileId);
        _requireEssenceRegistered(profileId, essenceId);
        return _essenceByIdByProfileId[profileId][essenceId].essenceMw;
    }

    /// @inheritdoc IProfileNFT
    function getNFTDescriptor() external view override returns (address) {
        return _nftDescriptor;
    }

    /// @inheritdoc IProfileNFT
    function getHandleByProfileId(uint256 profileId)
        external
        view
        override
        returns (string memory)
    {
        _requireMinted(profileId);
        return _profileById[profileId].handle;
    }

    /// @inheritdoc IProfileNFT
    function getProfileIdByHandle(string calldata handle)
        external
        view
        override
        returns (uint256)
    {
        return _profileIdByHandleHash[keccak256(bytes(handle))];
    }

    /// @inheritdoc IProfileNFT
    function getNamespaceOwner() external view override returns (address) {
        return _namespaceOwner;
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Transfers the profile nft.
     *
     * @param from The initial owner address.
     * @param to The receipient address.
     * @param id The nft id.
     * @dev It requires the state to be unpaused
     */
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override whenNotPaused {
        super.transferFrom(from, to, id);
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Generates the metadata json object.
     *
     * @param tokenId The profile NFT token ID.
     * @return string The metadata json object.
     * @dev It requires the tokenId to be already minted.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        return
            Actions.generateTokenURI(
                tokenId,
                _nftDescriptor,
                _profileById,
                _subscribeByProfileId
            );
    }

    /// @inheritdoc IProfileNFT
    function getOperatorApproval(uint256 profileId, address operator)
        public
        view
        returns (bool)
    {
        _requireMinted(profileId);
        return _operatorApproval[profileId][operator];
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(address) internal override onlyEngine {}

    function _subscribe(
        address sender,
        DataTypes.SubscribeParams calldata params,
        bytes[] calldata preDatas,
        bytes[] calldata postDatas
    ) internal returns (uint256[] memory) {
        for (uint256 i = 0; i < params.profileIds.length; i++) {
            _requireMinted(params.profileIds[i]);
        }

        return
            Actions.subscribe(
                DataTypes.SubscribeData(
                    sender,
                    params.profileIds,
                    preDatas,
                    postDatas,
                    SUBSCRIBE_BEACON,
                    ENGINE
                ),
                _subscribeByProfileId,
                _profileById
            );
    }

    function _collect(
        DataTypes.CollectParams calldata params,
        bytes calldata preData,
        bytes calldata postData
    ) internal returns (uint256) {
        _requireMinted(params.profileId);

        return
            Actions.collect(
                DataTypes.CollectData(
                    params.collector,
                    params.profileId,
                    params.essenceId,
                    preData,
                    postData,
                    ESSENCE_BEACON,
                    ENGINE
                ),
                _essenceByIdByProfileId
            );
    }

    function _createProfile(
        DataTypes.CreateProfileParams calldata params,
        bytes calldata preData,
        bytes calldata postData
    ) internal returns (uint256 tokenID) {
        address profileMw = Actions.createProfilePreProcess(
            params,
            preData,
            ENGINE
        );
        bytes32 handleHash = keccak256(bytes(params.handle));
        require(!_exists(_profileIdByHandleHash[handleHash]), "HANDLE_TAKEN");
        tokenID = _mint(params.to);
        Actions.createProfilePostProcess(
            params,
            postData,
            DataTypes.CreateProfilePostProcessData(
                tokenID,
                handleHash,
                profileMw
            ),
            _profileById,
            _metadataById,
            _profileIdByHandleHash,
            _addressToPrimaryProfile,
            _operatorApproval
        );
    }

    function _registerEssence(
        DataTypes.RegisterEssenceParams calldata params,
        bytes calldata initData
    ) internal returns (uint256) {
        return
            Actions.registerEssence(
                DataTypes.RegisterEssenceData(
                    params.profileId,
                    params.name,
                    params.symbol,
                    params.essenceTokenURI,
                    initData,
                    params.essenceMw,
                    params.transferable,
                    params.deployAtRegister,
                    ESSENCE_BEACON
                ),
                ENGINE,
                _profileById,
                _essenceByIdByProfileId
            );
    }

    function _setMetadata(uint256 profileId, string calldata metadata)
        internal
    {
        require(
            bytes(metadata).length <= Constants._MAX_URI_LENGTH,
            "METADATA_INVALID_LENGTH"
        );
        _metadataById[profileId] = metadata;
        emit SetMetadata(profileId, metadata);
    }

    function _setOperatorApproval(
        uint256 profileId,
        address operator,
        bool approved
    ) internal {
        Actions.setOperatorApproval(
            profileId,
            operator,
            approved,
            _operatorApproval
        );
    }

    function _setSubscribeData(
        uint256 profileId,
        string calldata uri,
        address mw,
        bytes calldata data
    ) internal {
        Actions.setSubscribeData(
            profileId,
            uri,
            mw,
            data,
            ENGINE,
            _subscribeByProfileId
        );
    }

    function _setEssenceData(
        uint256 profileId,
        uint256 essenceId,
        string calldata uri,
        address mw,
        bytes calldata data
    ) internal {
        Actions.setEssenceData(
            profileId,
            essenceId,
            uri,
            mw,
            data,
            ENGINE,
            _essenceByIdByProfileId
        );
    }

    function _setAvatar(uint256 profileId, string calldata avatar) internal {
        require(
            bytes(avatar).length <= Constants._MAX_URI_LENGTH,
            "AVATAR_INVALID_LENGTH"
        );
        _profileById[profileId].avatar = avatar;
        emit SetAvatar(profileId, avatar);
    }

    function _setPrimaryProfile(address owner, uint256 profileId) internal {
        _requireMinted(profileId);
        Actions.setPrimaryProfile(owner, profileId, _addressToPrimaryProfile);
    }

    function _requireEssenceRegistered(uint256 profileId, uint256 essenceId)
        internal
        view
    {
        require(
            bytes(_essenceByIdByProfileId[profileId][essenceId].name).length !=
                0,
            "ESSENCE_DOES_NOT_EXIST"
        );
    }
}