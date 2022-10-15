/// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../libraries/Metadata.sol";

interface IFingerprints {
    /**
     * @return Metadata.Meta
     * @param modaId MODA ID in the form of MODA-<ChainID>-<FingerprintVersion>-<FingerprintID>
     */
    function metadata(string memory modaId) external view returns (Metadata.Meta memory);

    /**
     * @return x and y coordinates for a given point in fingerprint data
     * @param modaId MODA ID in the form of MODA-<ChainID>-<FingerprintVersion>-<FingerprintID>
     */
    function getPoint(string memory modaId, uint32 index) external view returns (uint32 x, uint32 y);

    /**
     * @return true if the fingeprints address is registered
     * @param fingerprints Address of the fingerprints contract
     */
    function hasValidFingerprintAddress(address fingerprints) external view returns (bool);

    /**
     * @dev Convenience function used to verify an artist wallet address matches the one in the metadata for a given hash
     * @return bool
     * @param modaId MODA ID in the form of MODA-<ChainID>-<FingerprintVersion>-<FingerprintID>
     * @param artist Artist wallet address or a contract address used on behalf of the artist
     */
    function hasMatchingArtist(
        string memory modaId,
        address artist,
        address artistReleases
    ) external view returns (bool);
}