//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITokenURIProvider.sol";
import "./OpenSeaMetadata.sol";
import "./ChainScoutsExtension.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * Base class for all Token URI providers. Giving a new implementation of this class allows you to change how the metadata is created.
 */
abstract contract BaseTokenURIProvider is ITokenURIProvider, ChainScoutsExtension {
    string private baseName;
    string private defaultDescription;
    mapping (uint => string) private names;
    mapping (uint => string) private descriptions;

    constructor(string memory _baseName, string memory _defaultDescription) {
        baseName = _baseName;
        defaultDescription = _defaultDescription;
    }

    modifier stringIsJsonSafe(string memory str) {
        bytes memory b = bytes(str);
        for (uint i = 0; i < b.length; ++i) {
            uint8 char = uint8(b[i]);
            //              0-9                         A-Z                         a-z                   space
            if (!(char >= 48 && char <= 57 || char >= 65 && char <= 90 || char >= 97 && char <= 122 || char == 32)) {
                revert("BaseTokenURIProvider: All chars must be spaces or alphanumeric");
            }
        }
        _;
    }

    /**
     * @dev Sets the description of a token on OpenSea.
     * Must be an admin or the owner of the token.
     * 
     * The description may only contain A-Z, a-z, 0-9, or spaces.
     */
    function setDescription(uint tokenId, string memory description) external canAccessToken(tokenId) stringIsJsonSafe(description) {
        descriptions[tokenId] = description;
    }

    /**
     * @dev Sets the description of a token on OpenSea.
     * Must be an admin or the owner of the token.
     * 
     * The name may only contain A-Z, a-z, 0-9, or spaces.
     */
    function setName(uint tokenId, string memory name) external canAccessToken(tokenId) stringIsJsonSafe(name) {
        names[tokenId] = name;
    }

    /**
     * @dev Gets the background color of the given token ID as it appears on OpenSea.
     */
    function tokenBgColor(uint tokenId) internal view virtual returns (uint24);

    /**
     * @dev Gets the SVG of the given token ID.
     */
    function tokenSvg(uint tokenId) public view virtual returns (string memory);

    /**
     * @dev Gets the OpenSea attributes of the given token ID.
     */
    function tokenAttributes(uint tokenId) internal view virtual returns (Attribute[] memory);

    /**
     * @dev Gets the OpenSea token URI of the given token ID.
     */
    function tokenURI(uint tokenId) external view override returns (string memory) {
        string memory name = names[tokenId];
        if (bytes(name).length == 0) {
            name = string(abi.encodePacked(
                baseName,
                " #",
                Strings.toString(tokenId)
            ));
        }

        string memory description = descriptions[tokenId];
        if (bytes(description).length == 0) {
            description = defaultDescription;
        }

        return OpenSeaMetadataLibrary.makeMetadata(OpenSeaMetadata(
            tokenSvg(tokenId),
            description,
            name,
            tokenBgColor(tokenId),
            tokenAttributes(tokenId)
        ));
    }
}