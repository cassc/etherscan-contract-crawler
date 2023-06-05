// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████▓▀██████████████████████████████████████████████
// ██████████████████████████████████  ╙███████████████████████████████████████████
// ███████████████████████████████████    ╙████████████████████████████████████████
// ████████████████████████████████████      ╙▀████████████████████████████████████
// ████████████████████████████████████▌        ╙▀█████████████████████████████████
// ████████████████████████████████████▌           ╙███████████████████████████████
// ████████████████████████████████████▌            ███████████████████████████████
// ████████████████████████████████████▌         ▄█████████████████████████████████
// ████████████████████████████████████       ▄████████████████████████████████████
// ███████████████████████████████████▀   ,▄███████████████████████████████████████
// ██████████████████████████████████▀ ,▄██████████████████████████████████████████
// █████████████████████████████████▄▓█████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████

import {AuthGuard} from "../core/AuthGuard.sol";
import {Base64} from "solady/utils/Base64.sol";

contract VideoStorage is AuthGuard {
    bytes4 public constant VIDEO_CREATE_ROLE =
        bytes4(keccak256("VIDEO_CREATE_ROLE"));
    bytes4 public constant VIDEO_UPDATE_ROLE =
        bytes4(keccak256("VIDEO_UPDATE_ROLE"));

    uint8 constant TAGS_LIMIT = 7;

    constructor(address _registry) AuthGuard(_registry) {}

    event VideoCreated(VideoCreatedEventParams videoCreatedEventParams);
    event TitleUpdated(uint64 indexed id, string newTitle);
    event ThumbnailUpdated(uint64 indexed id, string newThumbnailURL);
    event VideoUpdated(uint64 indexed id, string newVideoURL);
    event DescriptionUpdated(uint64 indexed id, string newDescription);
    event PackedDataUpdated(uint64 indexed id, bytes32 newPackedData);
    event SymbolUpdated(uint64 indexed id, string newSymbol);
    event FrozenStatusUpdated(uint64 indexed id, bool newFrozenStatus);
    event NSFWStatusUpdated(uint64 indexed id, bool newFrozenStatus);
    event LicenseTypeUpdated(uint64 indexed id, uint8 newLicenseType);
    event TagsUpdated(uint64 indexed id, string[] newTags);

    mapping(uint64 => VideoMetadata) public videos;

    struct VideoMetadata {
        // title is limited to 96 characters
        bytes32 title1; // first data slot
        bytes32 title2; // second data slot
        bytes32 title3; // third data slot
        // arweave id efficiently packed
        bytes32 arweaveThumbnail;
        // arweave id efficiently packed
        bytes32 arweaveVideo;
        // packed data combining symbol, created time, flags, and category
        bytes32 packedData; // Combines symbol, created, flags, and category
        // dynamic value at the end for efficiency
        string description;
    }

    struct CreateParams {
        address owner;
        string title; // can only be 96 characters
        string description;
        string thumbnailURL; // just the arweave ID nothing else (no https://arweave.net/)
        string videoURL; // just the arweave ID nothing else (no https://arweave.net/)
        string[] tags;
        string symbol; // 6 characters or less
        bool frozen;
        bool nsfw;
        uint8 licenseType; // license type
        uint8 salt;
    }

    struct VideoCreatedEventParams {
        uint64 id;
        string title;
        string description;
        string thumbnailURL;
        string videoURL;
        string[] tags;
        string symbol;
        bool frozen;
        bool nsfw;
        uint8 licenseType;
        uint64 created;
    }

    function create(
        CreateParams memory params
    )
        public
        onlyAuthorizedByUser(params.owner, VIDEO_CREATE_ROLE)
        returns (uint64)
    {
        uint64 id = registerStorageContract(params.owner, params.salt);
        require(getCreated(id) == 0, "VIDEO_ALREADY_EXISTS");
        (
            bytes32 title1,
            bytes32 title2,
            bytes32 title3
        ) = calculateTitleBytes32(bytes(params.title));

        bytes32 packedData = calculatePackedData(
            PackedDataParams({
                symbol: params.symbol,
                created: uint64(block.timestamp),
                hidden: false,
                frozen: params.frozen,
                licenseType: params.licenseType,
                nsfw: params.nsfw,
                tagHashes: calculateTagHashes(params.tags)
            })
        );

        videos[id] = VideoMetadata(
            title1,
            title2,
            title3,
            arweaveIdToBytes32(params.thumbnailURL),
            arweaveIdToBytes32(params.videoURL),
            packedData,
            params.description
        );

        emit VideoCreated(
            VideoCreatedEventParams(
                id,
                params.title,
                params.description,
                params.thumbnailURL,
                params.videoURL,
                params.tags,
                params.symbol,
                params.frozen,
                params.nsfw,
                params.licenseType,
                uint64(block.timestamp)
            )
        );

        return id;
    }

    modifier validUpdate(uint64 _id) {
        require(getCreated(_id) != 0, "VIDEO_NOT_CREATED");
        require(!isFrozen(_id), "VIDEO_DATA_FROZEN");
        _;
    }

    function updateTitle(
        uint64 _id,
        string memory _newTitle
    ) public validUpdate(_id) onlyAuthorizedById(_id, VIDEO_UPDATE_ROLE) {
        (
            bytes32 title1,
            bytes32 title2,
            bytes32 title3
        ) = calculateTitleBytes32(bytes(_newTitle));
        require(
            title1 != 0x0 || title2 != 0x0 || title3 != 0x0,
            "INVALID_TITLE"
        );
        videos[_id].title1 = title1;
        videos[_id].title2 = title2;
        videos[_id].title3 = title3;

        // Emit TitleUpdated event
        emit TitleUpdated(_id, _newTitle);
    }

    function updateThumbnail(
        uint64 _id,
        string memory _newThumbnailURL
    ) public validUpdate(_id) onlyAuthorizedById(_id, VIDEO_UPDATE_ROLE) {
        bytes memory input = Base64.decode(_newThumbnailURL);
        bytes32 _thumbnail;
        assembly {
            _thumbnail := mload(add(input, 32))
        }
        require(_thumbnail != 0x0, "INVALID_THUMBNAIL");
        videos[_id].arweaveThumbnail = _thumbnail;

        // Emit ThumbnailUpdated event
        emit ThumbnailUpdated(_id, _newThumbnailURL);
    }

    function updateVideo(
        uint64 _id,
        string memory _newVideoURL
    ) public validUpdate(_id) onlyAuthorizedById(_id, VIDEO_UPDATE_ROLE) {
        bytes memory input = Base64.decode(_newVideoURL);
        bytes32 _video;
        assembly {
            _video := mload(add(input, 32))
        }
        require(_video != 0x0, "INVALID_VIDEO");
        videos[_id].arweaveVideo = _video;

        // Emit VideoUpdated event
        emit VideoUpdated(_id, _newVideoURL);
    }

    function updateDescription(
        uint64 _id,
        string memory _newDescription
    ) public validUpdate(_id) onlyAuthorizedById(_id, VIDEO_UPDATE_ROLE) {
        require(bytes(_newDescription).length > 0, "INVALID_DESCRIPTION");
        videos[_id].description = _newDescription;

        // Emit DescriptionUpdated event
        emit DescriptionUpdated(_id, _newDescription);
    }

    function updatePackedData(
        uint64 _id,
        bytes16 _newPackedData
    ) public validUpdate(_id) onlyAuthorizedById(_id, VIDEO_UPDATE_ROLE) {
        require(_newPackedData != 0x0, "INVALID_COMBINED_FIELD");
        videos[_id].packedData = _newPackedData;

        // Emit PackedDataUpdated event
        emit PackedDataUpdated(_id, _newPackedData);
    }

    function updateSymbol(
        uint64 _id,
        string memory _newSymbol
    ) public validUpdate(_id) onlyAuthorizedById(_id, VIDEO_UPDATE_ROLE) {
        bytes32 newPackedData = calculatePackedData(
            PackedDataParams({
                symbol: _newSymbol,
                created: getCreated(_id),
                hidden: isHidden(_id),
                frozen: isFrozen(_id),
                licenseType: getLicenseType(_id),
                nsfw: isNSFW(_id),
                tagHashes: getTags(_id)
            })
        );

        videos[_id].packedData = newPackedData;

        // Emit SymbolUpdated event
        emit SymbolUpdated(_id, _newSymbol);
    }

    function updateFrozenStatus(
        uint64 _id,
        bool _newFrozenStatus
    ) public validUpdate(_id) onlyAuthorizedById(_id, VIDEO_UPDATE_ROLE) {
        bytes32 newPackedData = calculatePackedData(
            PackedDataParams({
                symbol: getSymbol(_id),
                created: getCreated(_id),
                hidden: isHidden(_id),
                frozen: _newFrozenStatus,
                licenseType: getLicenseType(_id),
                nsfw: isNSFW(_id),
                tagHashes: getTags(_id)
            })
        );

        videos[_id].packedData = newPackedData;

        // Emit FrozenStatusUpdated event
        emit FrozenStatusUpdated(_id, _newFrozenStatus);
    }

    function updateLicenseType(
        uint64 _id,
        uint8 _newLicenseType
    ) public validUpdate(_id) onlyAuthorizedById(_id, VIDEO_UPDATE_ROLE) {
        bytes32 newPackedData = calculatePackedData(
            PackedDataParams({
                symbol: getSymbol(_id),
                created: getCreated(_id),
                hidden: isHidden(_id),
                frozen: isFrozen(_id),
                licenseType: _newLicenseType,
                nsfw: isNSFW(_id),
                tagHashes: getTags(_id)
            })
        );

        videos[_id].packedData = newPackedData;

        // Emit LicenseTypeUpdated event
        emit LicenseTypeUpdated(_id, _newLicenseType);
    }

    function updateNSFWStatus(
        uint64 _id,
        bool _newNSFWStatus
    ) public validUpdate(_id) onlyAuthorizedById(_id, VIDEO_UPDATE_ROLE) {
        bytes32 newPackedData = calculatePackedData(
            PackedDataParams({
                symbol: getSymbol(_id),
                created: getCreated(_id),
                hidden: isHidden(_id),
                frozen: isFrozen(_id),
                licenseType: getLicenseType(_id),
                nsfw: _newNSFWStatus,
                tagHashes: getTags(_id)
            })
        );

        videos[_id].packedData = newPackedData;

        // Emit NSFWStatusUpdated event
        emit NSFWStatusUpdated(_id, _newNSFWStatus);
    }

    function updateTags(
        uint64 _id,
        string[] memory _newTags
    ) public validUpdate(_id) onlyAuthorizedById(_id, VIDEO_UPDATE_ROLE) {
        bytes32 newPackedData = calculatePackedData(
            PackedDataParams({
                symbol: getSymbol(_id),
                created: getCreated(_id),
                hidden: isHidden(_id),
                frozen: isFrozen(_id),
                licenseType: getLicenseType(_id),
                nsfw: isNSFW(_id),
                tagHashes: calculateTagHashes(_newTags)
            })
        );

        videos[_id].packedData = newPackedData;

        // Emit CategoriesUpdated event
        emit TagsUpdated(_id, _newTags);
    }

    function getTitle(uint64 _id) public view returns (string memory) {
        bytes memory titleBytes = new bytes(96);
        uint64 actualLength;

        for (uint64 i = 0; i < 32; i++) {
            titleBytes[i] = videos[_id].title1[i];
            titleBytes[32 + i] = videos[_id].title2[i];
            titleBytes[64 + i] = videos[_id].title3[i];
        }

        for (uint64 j = 0; j < titleBytes.length; j++) {
            if (titleBytes[j] == 0x00) {
                actualLength = j;
                break;
            }
        }

        bytes memory trimmedTitleBytes = new bytes(actualLength);
        for (uint64 k = 0; k < actualLength; k++) {
            trimmedTitleBytes[k] = titleBytes[k];
        }
        return string(trimmedTitleBytes);
    }

    function getThumbnail(uint64 _id) public view returns (string memory) {
        bytes32 input = videos[_id].arweaveThumbnail;
        bytes memory output = new bytes(32);
        assembly {
            mstore(add(output, 32), input)
        }
        return Base64.encode(output, true, true);
    }

    function getVideo(uint64 _id) public view returns (string memory) {
        bytes32 input = videos[_id].arweaveVideo;
        bytes memory output = new bytes(32);
        assembly {
            mstore(add(output, 32), input)
        }
        return Base64.encode(output, true, true);
    }

    function getDescription(uint64 _id) public view returns (string memory) {
        return videos[_id].description;
    }

    function getSymbol(uint64 _id) public view returns (string memory) {
        bytes32 packedData = videos[_id].packedData;
        uint48 symbol = uint48(uint256(packedData) >> 208);
        bytes6 symbolBytes = bytes6(symbol);

        // Count the number of non-null characters
        uint8 nonNullChars = 0;
        for (uint8 i = 0; i < 6; i++) {
            if (symbolBytes[i] != 0) {
                nonNullChars++;
            } else {
                break;
            }
        }

        // Create a new array with the appropriate size and copy the non-null characters
        bytes memory trimmedSymbol = new bytes(nonNullChars);
        for (uint8 i = 0; i < nonNullChars; i++) {
            trimmedSymbol[i] = symbolBytes[i];
        }

        return string(trimmedSymbol);
    }

    function getCreated(uint64 _id) public view returns (uint64) {
        bytes32 packedData = videos[_id].packedData;
        return uint64(uint256(packedData) >> 144);
    }

    function isHidden(uint64 _id) public view returns (bool) {
        bytes32 packedData = videos[_id].packedData;
        return (uint256(packedData) >> 96) & 1 == 1;
    }

    function isFrozen(uint64 _id) public view returns (bool) {
        bytes32 packedData = videos[_id].packedData;
        return (uint256(packedData) >> 97) & 1 == 1;
    }

    function getLicenseType(uint64 _id) public view returns (uint8) {
        bytes32 packedData = videos[_id].packedData;
        return uint8((uint256(packedData) >> 98) & 0xFF);
    }

    function isNSFW(uint64 _id) public view returns (bool) {
        bytes32 packedData = videos[_id].packedData;
        return (uint256(packedData) >> 106) & 1 == 1;
    }

    function getTags(uint64 _id) public view returns (uint16[] memory) {
        bytes32 packedData = videos[_id].packedData;
        uint112 packedTags = uint112(uint256(packedData) & 0xFFFFFFFFFFFF);
        uint8 tagCount = 0;

        // Count the number of non-zero tags
        for (uint8 i = 0; i < TAGS_LIMIT; i++) {
            uint16 tagHash = uint16(packedTags >> (i * 16));
            if (tagHash != 0) {
                tagCount++;
            }
        }

        // Create a new array with the appropriate size and fill it with the non-zero tags
        uint16[] memory tagHashes = new uint16[](tagCount);
        uint8 index = 0;
        for (uint8 i = 0; i < TAGS_LIMIT; i++) {
            uint16 tagHash = uint16(packedTags >> (i * 16));
            if (tagHash != 0) {
                tagHashes[index] = tagHash;
                index++;
            }
        }

        return tagHashes;
    }

    function calculateTitleBytes32(
        bytes memory titleBytes
    ) public pure returns (bytes32 title1, bytes32 title2, bytes32 title3) {
        require(titleBytes.length <= 96, "TITLE_TOO_LONG");

        // bytes memory titleBytes = bytes(title);
        uint32 i = 0;

        for (; i < 32 && i < titleBytes.length; i++) {
            title1 |= bytes32(
                uint(uint8(titleBytes[i])) * (2 ** (8 * (31 - i)))
            );
        }
        for (; i < 64 && i < titleBytes.length; i++) {
            title2 |= bytes32(
                uint(uint8(titleBytes[i])) * (2 ** (8 * (63 - i)))
            );
        }
        for (; i < 96 && i < titleBytes.length; i++) {
            title3 |= bytes32(
                uint(uint8(titleBytes[i])) * (2 ** (8 * (95 - i)))
            );
        }
    }

    // music     gaming
    // VVV         V
    // 1000000000100000000000000000

    // UP TO 7
    // 16bits(hash("asfaa"))
    // [0000000000000000] =>
    // [0000000000000000][0000000000000000][0000000000000000][0000000000000000][0000000000000000][0000000000000000][0000000000000000]

    struct PackedDataParams {
        string symbol;
        uint64 created;
        bool hidden;
        bool frozen;
        uint8 licenseType;
        bool nsfw;
        uint16[] tagHashes;
    }

    function calculatePackedData(
        PackedDataParams memory params
    ) public pure returns (bytes32) {
        uint48 symbol = uint48(bytes6(bytes(params.symbol)));
        uint64 created = params.created;
        uint8 hidden = params.hidden ? 1 : 0;
        uint8 frozen = params.frozen ? 1 : 0;
        uint8 licenseType = params.licenseType;
        uint8 nsfw = params.nsfw ? 1 : 0;
        uint112 tags = 0;

        for (uint8 i = 0; i < params.tagHashes.length && i < TAGS_LIMIT; i++) {
            tags |= uint112(params.tagHashes[i]) << (i * 16);
        }
        return
            (bytes32(uint(symbol)) << 208) |
            (bytes32(uint(created)) << 144) |
            (bytes32(uint(hidden)) << 96) |
            (bytes32(uint(frozen)) << 97) |
            (bytes32(uint(licenseType)) << 98) |
            (bytes32(uint(nsfw)) << 106) |
            (bytes32(uint(tags)));
    }

    function calculateTagHashes(
        string[] memory _tags
    ) public pure returns (uint16[] memory) {
        uint16[] memory tagHashes = new uint16[](_tags.length);

        for (uint8 i = 0; i < _tags.length && i < TAGS_LIMIT; i++) {
            tagHashes[i] = uint16(
                bytes2(keccak256(abi.encodePacked(_tags[i])))
            );
        }

        return tagHashes;
    }

    function arweaveIdToBytes32(
        string memory id
    ) public pure returns (bytes32) {
        bytes memory input = Base64.decode(id);
        bytes32 output;
        assembly {
            output := mload(add(input, 32))
        }
        return output;
    }
}