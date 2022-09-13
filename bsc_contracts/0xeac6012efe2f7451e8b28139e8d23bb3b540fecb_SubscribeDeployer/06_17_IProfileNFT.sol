// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IProfileNFTEvents } from "./IProfileNFTEvents.sol";

import { DataTypes } from "../libraries/DataTypes.sol";

interface IProfileNFT is IProfileNFTEvents {
    /**
     * @notice Initializes the Profile NFT.
     *
     * @param _owner Owner of the Profile NFT.
     * @param name Name to set for the Profile NFT.
     * @param symbol Symbol to set for the Profile NFT.
     */
    function initialize(
        address _owner,
        string calldata name,
        string calldata symbol
    ) external;

    /*
     * @notice Creates a profile and mints it to the recipient address.
     *
     * @param params contains all params.
     * @param data contains extra data.
     *
     * @dev The current function validates the caller address and the handle before minting
     * and the following conditions must be met:
     * - The caller address must be the engine address.
     * - The recipient address must be a valid Ethereum address.
     * - The handle must contain only a-z, A-Z, 0-9.
     * - The handle must not be already used.
     * - The handle must not be longer than 27 bytes.
     * - The handle must not be empty.
     */
    function createProfile(
        DataTypes.CreateProfileParams calldata params,
        bytes calldata preData,
        bytes calldata postData
    ) external payable returns (uint256);

    /**
     * @notice The subscription functionality.
     *
     * @param params The params for subscription.
     * @param preDatas The subscription data for preprocess.
     * @param postDatas The subscription data for postprocess.
     * @return uint256[] The subscription nft ids.
     * @dev the function requires the stated to be not paused.
     */
    function subscribe(
        DataTypes.SubscribeParams calldata params,
        bytes[] calldata preDatas,
        bytes[] calldata postDatas
    ) external returns (uint256[] memory);

    /**
     * @notice Subscribe to an address(es) with a signature.
     *
     * @param sender The sender address.
     * @param params The params for subscription.
     * @param preDatas The subscription data for preprocess.
     * @param postDatas The subscription data for postprocess.
     * @param sig The EIP712 signature.
     * @dev the function requires the stated to be not paused.
     * @return uint256[] The subscription nft ids.
     */
    function subscribeWithSig(
        DataTypes.SubscribeParams calldata params,
        bytes[] calldata preDatas,
        bytes[] calldata postDatas,
        address sender,
        DataTypes.EIP712Signature calldata sig
    ) external returns (uint256[] memory);

    /**
     * @notice Collect a profile's essence. Anyone can collect to another wallet
     *
     * @param params The params for collect.
     * @param preData The collect data for preprocess.
     * @param postData The collect data for postprocess.
     * @return uint256 The collected essence nft id.
     */
    function collect(
        DataTypes.CollectParams calldata params,
        bytes calldata preData,
        bytes calldata postData
    ) external returns (uint256);

    /**
     * @notice Collect a profile's essence with signature.
     *
     * @param sender The sender address.
     * @param params The params for collect.
     * @param preData The collect data for preprocess.
     * @param postData The collect data for postprocess.
     * @param sig The EIP712 signature.
     * @dev Only owner's signature works.
     * @return uint256 The collected essence nft id.
     */
    function collectWithSig(
        DataTypes.CollectParams calldata params,
        bytes calldata preData,
        bytes calldata postData,
        address sender,
        DataTypes.EIP712Signature calldata sig
    ) external returns (uint256);

    /**
     * @notice Register an essence.
     *
     * @param params The params for registration.
     * @param initData The registration initial data.
     * @return uint256 The new essence count.
     */
    function registerEssence(
        DataTypes.RegisterEssenceParams calldata params,
        bytes calldata initData
    ) external returns (uint256);

    /**
     * @notice Register an essence with signature.
     *
     * @param params The params for registration.
     * @param initData The registration initial data.
     * @param sig The EIP712 signature.
     * @dev Only owner's signature works.
     * @return uint256 The new essence count.
     */
    function registerEssenceWithSig(
        DataTypes.RegisterEssenceParams calldata params,
        bytes calldata initData,
        DataTypes.EIP712Signature calldata sig
    ) external returns (uint256);

    /**
     * @notice Changes the pause state of the profile nft.
     *
     * @param toPause The pause state.
     */
    function pause(bool toPause) external;

    /**
     * @notice Set new namespace owner.
     *
     * @param owner The new owner.
     */
    function setNamespaceOwner(address owner) external;

    /**
     * @notice Sets the Profile NFT Descriptor.
     *
     * @param descriptor The new descriptor address to set.
     */
    function setNFTDescriptor(address descriptor) external;

    /**
     * @notice Sets the NFT metadata as IPFS hash.
     *
     * @param profileId The profile ID.
     * @param metadata The new metadata to set.
     */
    function setMetadata(uint256 profileId, string calldata metadata) external;

    /**
     * @notice Sets the profile metadata with a signture.
     *
     * @param profileId The profile ID.
     * @param metadata The new metadata to be set.
     * @param sig The EIP712 signature.
     * @dev Only owner's signature works.
     */
    function setMetadataWithSig(
        uint256 profileId,
        string calldata metadata,
        DataTypes.EIP712Signature calldata sig
    ) external;

    /**
     * @notice Sets subscribe middleware for a profile.
     *
     * @param profileId The profile ID.
     * @param tokenURI The new token URI.
     * @param mw The new middleware to be set.
     * @param data The data for middleware.
     */
    function setSubscribeData(
        uint256 profileId,
        string calldata tokenURI,
        address mw,
        bytes calldata data
    ) external;

    /**
     * @notice Sets subscribe middleware for a profile with signature.
     *
     * @param profileId The profile ID.
     * @param tokenURI The new token URI.
     * @param mw The new middleware to be set.
     * @param data The data for middleware.
     * @param sig The EIP712 signature.
     * @dev Only owner's signature works.
     */
    function setSubscribeDataWithSig(
        uint256 profileId,
        string calldata tokenURI,
        address mw,
        bytes calldata data,
        DataTypes.EIP712Signature calldata sig
    ) external;

    /**
     * @notice Sets subscribe middleware for a profile.
     *
     * @param profileId The profile ID.
     * @param essenceId The profile ID.
     * @param tokenURI The new token URI.
     * @param mw The new middleware to be set.
     * @param data The data for middleware.
     */
    function setEssenceData(
        uint256 profileId,
        uint256 essenceId,
        string calldata tokenURI,
        address mw,
        bytes calldata data
    ) external;

    /**
     * @notice Sets subscribe middleware for a profile with signature.
     *
     * @param profileId The profile ID.
     * @param essenceId The profile ID.
     * @param tokenURI The new token URI.
     * @param mw The new middleware to be set.
     * @param data The data for middleware.
     * @param sig The EIP712 signature.
     * @dev Only owner's signature works.
     */
    function setEssenceDataWithSig(
        uint256 profileId,
        uint256 essenceId,
        string calldata tokenURI,
        address mw,
        bytes calldata data,
        DataTypes.EIP712Signature calldata sig
    ) external;

    /**
     * @notice Sets the primary profile for the user.
     *
     * @param profileId The profile ID that is set to be primary.
     */
    function setPrimaryProfile(uint256 profileId) external;

    /**
     * @notice Sets the primary profile for the user with signature.
     *
     * @param profileId The profile ID that is set to be primary.
     * @param sig The EIP712 signature.
     * @dev Only owner's signature works.
     */
    function setPrimaryProfileWithSig(
        uint256 profileId,
        DataTypes.EIP712Signature calldata sig
    ) external;

    /**
     * @notice Sets the NFT avatar as IPFS hash.
     *
     * @param profileId The profile ID.
     * @param avatar The new avatar to set.
     */
    function setAvatar(uint256 profileId, string calldata avatar) external;

    /**
     * @notice Sets the NFT avatar as IPFS hash with signature.
     *
     * @param profileId The profile ID.
     * @param avatar The new avatar to set.
     * @param sig The EIP712 signature.
     * @dev Only owner's signature works.
     */
    function setAvatarWithSig(
        uint256 profileId,
        string calldata avatar,
        DataTypes.EIP712Signature calldata sig
    ) external;

    /**
     * @notice Sets the operator approval.
     *
     * @param profileId The profile ID.
     * @param operator The operator address.
     * @param approved The approval status.
     */
    function setOperatorApproval(
        uint256 profileId,
        address operator,
        bool approved
    ) external;

    /**
     * @notice Gets the profile metadata.
     *
     * @param profileId The profile ID.
     * @return string The metadata of the profile.
     */
    function getMetadata(uint256 profileId)
        external
        view
        returns (string memory);

    /**
     * @notice Gets the profile NFT descriptor.
     *
     * @return address The descriptor address.
     */
    function getNFTDescriptor() external view returns (address);

    /**
     * @notice Gets the profile avatar.
     *
     * @param profileId The profile ID.
     * @return string The avatar of the profile.
     */
    function getAvatar(uint256 profileId) external view returns (string memory);

    /**
     * @notice Gets the operator approval status.
     *
     * @param profileId The profile ID.
     * @param operator The operator address.
     * @return bool The approval status.
     */
    function getOperatorApproval(uint256 profileId, address operator)
        external
        view
        returns (bool);

    /**
     * @notice Gets the profile handle by ID.
     *
     * @param profileId The profile ID.
     * @return string the profile handle.
     */
    function getHandleByProfileId(uint256 profileId)
        external
        view
        returns (string memory);

    /**
     * @notice Gets the profile ID by handle.
     *
     * @param handle The profile handle.
     * @return uint256 the profile ID.
     */
    function getProfileIdByHandle(string calldata handle)
        external
        view
        returns (uint256);

    /**
     * @notice Gets a profile subscribe middleware address.
     *
     * @param profileId The profile id.
     * @return address The middleware address.
     */
    function getSubscribeMw(uint256 profileId) external view returns (address);

    /**
     * @notice Gets the primary profile of the user.
     *
     * @param user The wallet address of the user.
     * @return profileId The primary profile of the user.
     */
    function getPrimaryProfile(address user)
        external
        view
        returns (uint256 profileId);

    /**
     * @notice Gets the Subscribe NFT token URI.
     *
     * @param profileId The profile ID.
     * @return string The Subscribe NFT token URI.
     */
    function getSubscribeNFTTokenURI(uint256 profileId)
        external
        view
        returns (string memory);

    /**
     * @notice Gets the Subscribe NFT address.
     *
     * @param profileId The profile ID.
     * @return address The Subscribe NFT address.
     */
    function getSubscribeNFT(uint256 profileId) external view returns (address);

    /**
     * @notice Gets the Essence NFT token URI.
     *
     * @param profileId The profile ID.
     * @param essenceId The Essence ID.
     * @return string The Essence NFT token URI.
     */
    function getEssenceNFTTokenURI(uint256 profileId, uint256 essenceId)
        external
        view
        returns (string memory);

    /**
     * @notice Gets the Essence NFT address.
     *
     * @param profileId The profile ID.
     * @param essenceId The Essence ID.
     * @return address The Essence NFT address.
     */
    function getEssenceNFT(uint256 profileId, uint256 essenceId)
        external
        view
        returns (address);

    /**
     * @notice Gets a profile essence middleware address.
     *
     * @param profileId The profile id.
     * @param essenceId The Essence ID.
     * @return address The middleware address.
     */
    function getEssenceMw(uint256 profileId, uint256 essenceId)
        external
        view
        returns (address);

    /**
     * @notice Gets the profile namespace owner.
     *
     * @return address The owner of this profile namespace.
     */
    function getNamespaceOwner() external view returns (address);
}