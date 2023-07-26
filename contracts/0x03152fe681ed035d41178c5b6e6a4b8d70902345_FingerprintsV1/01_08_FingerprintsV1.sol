/// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IFingerprints.sol";
import "./interfaces/IFingerprints.sol";
import "./libraries/Metadata.sol";

contract FingerprintsV1 is IFingerprints, Ownable, IERC165 {
    using Counters for Counters.Counter;
    Counters.Counter private _idCounter;

    /// @dev "MODA-<ChainID>-<FingerprintVersion>-"
    string private constant MODA_ID_PREFACE = "MODA-1-1-";

    ///@dev ArtistReleases => is a list of NFTs that are registered for Fingerprints
    mapping(address => bool) private _authorizedReleases;

    ///@dev Fingerprints => a list of addresses for registered fingerprint versions
    mapping(address => bool) private _authorizedFingerprints;

    /// @dev MODA ID => Metadata
    mapping(string => Metadata.Meta) internal _metadata;

    /// @dev MODA ID => x values in an array to iterate over
    mapping(string => uint32[]) public x_array;

    /// @dev MODA ID => x => array of y
    mapping(string => mapping(uint32 => uint32[])) public y_map;

    event FingerprintCreated(address indexed creator, string indexed modaId, string indexed song);
    event ArtistReleasesRegistered(address indexed artist, address indexed artistReleases, bool isRegistered);
    event FingerprintsReleasesRegistered(address indexed fingerprints, bool isRegistered);

    function createFingerprint(
        address creator,
        string memory creatorName,
        address artist,
        string memory artistName,
        string memory uri,
        string memory title,
        uint16 x_shape,
        uint16 y_shape
    ) public onlyOwner {
        _idCounter.increment();
        string memory modaId = string(abi.encodePacked(MODA_ID_PREFACE, Strings.toString(_idCounter.current())));
        require(_metadata[modaId].creator == address(0), "Fingerprint already exists");
        require(address(0) != creator, "creator cannot be 0x0");
        require(address(0) != artist, "artist cannot be 0x0");
        require(x_shape > 0 && y_shape > 0, "x and y shapes cannot be 0");

        _metadata[modaId].created = block.timestamp;
        _metadata[modaId].creator = creator;
        _metadata[modaId].creatorName = creatorName;
        _metadata[modaId].artist = artist;
        _metadata[modaId].artistName = artistName;
        _metadata[modaId].title = title;
        _metadata[modaId].x_shape = x_shape;
        _metadata[modaId].y_shape = y_shape;
        _metadata[modaId].uri = uri;

        emit FingerprintCreated(creator, modaId, title);
    }

    function setURI(string memory modaId, string memory uri) public onlyOwner {
        _metadata[modaId].uri = uri;
    }

    /// @dev Registration for official ArtistReleases that are recognized by MODA. The event emitted serves as a way for client applications to find all contracts and filter by creator
    /// @param artistReleases The address of the NFT contract deployed by MODA
    /// @param artist The address of the artist for a given ArtistReleases contract
    /// @param isRegistered The state of registration
    function registerArtistReleases(
        address artistReleases,
        address artist,
        bool isRegistered
    ) public onlyOwner {
        _authorizedReleases[artistReleases] = isRegistered;
        emit ArtistReleasesRegistered(artistReleases, artist, isRegistered);
    }

    /// @dev Registration for official Fingerprint contracts. Used to validate fingerprint contracts in ArtistReleases
    /// @param fingerprints The address of the NFT contract deployed by MODA
    /// @param isRegistered The state of registration
    function registerFingerprint(address fingerprints, bool isRegistered) public onlyOwner {
        _authorizedFingerprints[fingerprints] = isRegistered;
        emit FingerprintsReleasesRegistered(fingerprints, isRegistered);
    }

    /// @dev Function to check if a ArtistReleases contract is registered
    /// @param artistReleases Address of a ArtistReleases contract
    /// @return bool
    function isAuthorizedArtistRelease(address artistReleases) public view returns (bool) {
        return _authorizedReleases[artistReleases];
    }

    function setData(
        string memory modaId,
        uint32[] memory x,
        uint32[][] memory y
    ) public onlyOwner {
        _setData(modaId, x, y);
    }

    function _setData(
        string memory modaId,
        uint32[] memory x,
        uint32[][] memory y
    ) internal virtual {
        require(x.length == y.length, "x and y must have the same length");

        for (uint256 i = 0; i < x.length; i++) {
            uint32 _x_value = x[i];
            require(y_map[modaId][_x_value].length == 0, "x value already exists");
            x_array[modaId].push(_x_value);
            y_map[modaId][_x_value] = y[i];

            _metadata[modaId].pointCount += y[i].length;
        }
    }

    /// @inheritdoc	IFingerprints
    function getPoint(string memory modaId, uint32 index) external view override returns (uint32 x, uint32 y) {
        uint256 count;
        for (uint32 i = 0; i < x_array[modaId].length; i++) {
            uint32[] memory _y = y_map[modaId][x_array[modaId][i]];

            for (uint32 j = 0; j < _y.length; j++) {
                if (count == index) {
                    return (x_array[modaId][i], _y[j]);
                }
                count++;
            }
        }

        return (0, 0);
    }

    /// @inheritdoc	IFingerprints
    function metadata(string memory modaId) external view override returns (Metadata.Meta memory) {
        return _metadata[modaId];
    }

    function uniqueX(string memory modaId) public view returns (uint256) {
        return x_array[modaId].length;
    }

    /// @inheritdoc	IERC165
    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return interfaceId == type(IFingerprints).interfaceId;
    }

    /// @inheritdoc	IFingerprints
    function hasValidFingerprintAddress(address fingerprints) external view override returns (bool) {
        return address(this) == fingerprints || _authorizedFingerprints[fingerprints];
    }

    /// @inheritdoc	IFingerprints
    function hasMatchingArtist(
        string memory modaId,
        address artist,
        address artistReleases
    ) external view override returns (bool) {
        return _metadata[modaId].artist == artist && isAuthorizedArtistRelease(artistReleases);
    }
}