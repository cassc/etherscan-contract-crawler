// SPDX-License-Identifier: MIT

/// @title Ultra Sound Editions Descriptor
/// @author -wizard

// Inspired by - Nouns DAO and .merge by pak

pragma solidity ^0.8.6;

import {IUltraSoundParts} from "./interfaces/IUltraSoundParts.sol";
import {IUltraSoundGridRenderer} from "./interfaces/IUltraSoundGridRenderer.sol";
import {IUltraSoundDescriptor} from "./interfaces/IUltraSoundDescriptor.sol";
import {IUltraSoundEditions} from "./interfaces/IUltraSoundEditions.sol";
import {Base64} from "./libs/Base64.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract UltraSoundDescriptor is IUltraSoundDescriptor, Ownable {
    using Strings for *;

    struct MetadataStructure {
        string name;
        string description;
        string createdBy;
        string image;
        MetadataAttribute[] attributes;
    }

    struct MetadataAttribute {
        bool isValueAString;
        string displayType;
        string traitType;
        string value;
    }

    IUltraSoundParts public parts;
    IUltraSoundGridRenderer public renderer;

    IUltraSoundGridRenderer.Override[] private overrides;
    IUltraSoundGridRenderer.Override[] private ultraSoundEdition;

    bool public isDataURIEnabled = true;
    string public baseURI;

    constructor(IUltraSoundParts _parts, IUltraSoundGridRenderer _renderer) {
        parts = _parts;
        renderer = _renderer;
        overrides.push(
            IUltraSoundGridRenderer.Override({
                symbols: 2,
                positions: 78,
                colors: "#B5BDDB",
                size: 0
            })
        );
        overrides.push(
            IUltraSoundGridRenderer.Override({
                symbols: 3,
                positions: 79,
                colors: "#B5BDDB",
                size: 0
            })
        );

        ultraSoundEdition.push(
            IUltraSoundGridRenderer.Override({
                symbols: 4,
                positions: 35,
                colors: "",
                size: 1
            })
        );
        ultraSoundEdition.push(
            IUltraSoundGridRenderer.Override({
                symbols: 5,
                positions: 51,
                colors: "url(#lg1)",
                size: 0
            })
        );
        ultraSoundEdition.push(
            IUltraSoundGridRenderer.Override({
                symbols: 6,
                positions: 52,
                colors: "url(#lg1)",
                size: 0
            })
        );
    }

    function toggleDataURIEnabled() external onlyOwner {
        bool enabled = !isDataURIEnabled;

        isDataURIEnabled = enabled;
        emit DataURIToggled(enabled);
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;

        emit BaseURIUpdated(_baseURI);
    }

    function setParts(IUltraSoundParts _parts) external override onlyOwner {
        parts = _parts;
        emit PartsUpdated(_parts);
    }

    function setRenderer(IUltraSoundGridRenderer _renderer) external onlyOwner {
        renderer = _renderer;
        emit RendererUpdated(_renderer);
    }

    function palettesCount() external view override returns (uint256) {
        return parts.palettesCount();
    }

    function symbolsCount() external view override returns (uint256) {
        return parts.symbolsCount();
    }

    function gradientsCount() external view override returns (uint256) {
        return parts.gradientsCount();
    }

    function quantitiesCount() external view override returns (uint256) {
        return parts.quantityCount();
    }

    function tokenURI(
        uint256 tokenId,
        IUltraSoundEditions.Edition memory edition
    ) external view returns (string memory) {
        if (isDataURIEnabled) return dataURI(tokenId, edition);
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function _formatData(IUltraSoundEditions.Edition memory edition, uint8 size)
        internal
        pure
        returns (IUltraSoundGridRenderer.Symbol memory)
    {
        return
            IUltraSoundGridRenderer.Symbol({
                id: edition.burned ? 7 : 1,
                gridPalette: 0,
                gridSize: size,
                seed: edition.seed,
                level: edition.level,
                palette: edition.palette,
                opaque: edition.ultraSound || edition.level < 5 ? true : false
            });
    }

    function tokenSVG(IUltraSoundEditions.Edition memory edition, uint8 size)
        external
        view
        returns (string memory)
    {
        return
            renderer.generateGrid(
                _formatData(edition, size),
                _getOverrides(edition.ultraSound, edition.level),
                _getGradients(edition.level, edition.seed),
                edition.ultraEdition
            );
    }

    function dataURI(
        uint256 tokenId,
        IUltraSoundEditions.Edition memory edition
    ) public view returns (string memory) {
        bytes memory name = abi.encodePacked(
            "proof of stake #",
            tokenId.toString()
        );

        if (edition.level == 7) {
            name = abi.encodePacked(
                "ultra sound edition #",
                edition.ultraEdition.toString()
            );
        } else if (edition.burned) {
            name = abi.encodePacked("proof of burn #", tokenId.toString());
        }
        MetadataStructure memory metadata = MetadataStructure({
            name: string(name),
            description: string(
                abi.encodePacked(
                    "may or may not be ultra sound\\n\\nby -wizard\\n\\n",
                    "[inventory](https://ultrasoundeditions.com/inventory) | ",
                    "[swap](https://ultrasoundeditions.com/inventory/",
                    tokenId.toString(),
                    "/swap) | [merge](https://ultrasoundeditions.com/inventory/",
                    tokenId.toString(),
                    "/merge)"
                )
            ),
            createdBy: "-wizard",
            image: renderer.generateGrid(
                _formatData(edition, 1),
                _getOverrides(edition.ultraSound, edition.level),
                _getGradients(edition.level, edition.seed),
                edition.ultraEdition
            ),
            attributes: _getJsonAttributes(edition)
        });

        // prettier-ignore
        string memory base64Json = Base64.encode(bytes(string(_generateMetadata(metadata))));
        // prettier-ignore
        return string(abi.encodePacked("data:application/json;base64,", base64Json));
    }

    function _getOverrides(bool ultraSound, uint256 level)
        private
        view
        returns (IUltraSoundGridRenderer.Override[] memory o)
    {
        if (ultraSound && level != 7) o = overrides;
        else if (ultraSound && level == 7) o = ultraSoundEdition;
        else o = new IUltraSoundGridRenderer.Override[](0);
    }

    function _getGradients(uint256 level, uint256 seed)
        private
        view
        returns (uint256)
    {
        if (level != 7) return 0;
        else return ((seed % (parts.gradientsCount() - 1)) + 1);
    }

    function _generateMetadata(MetadataStructure memory metadata)
        private
        pure
        returns (string memory)
    {
        bytes memory byteString;

        byteString = abi.encodePacked(byteString, _openJsonObject());

        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute("name", metadata.name, true)
        );

        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute(
                "description",
                metadata.description,
                true
            )
        );

        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute(
                "created_by",
                metadata.createdBy,
                true
            )
        );

        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute(
                "image_data",
                metadata.image,
                true
            )
        );

        byteString = abi.encodePacked(
            byteString,
            _pushJsonComplexAttribute(
                "attributes",
                _getAttributes(metadata.attributes),
                false
            )
        );

        byteString = abi.encodePacked(byteString, _closeJsonObject());

        return string(byteString);
    }

    function _getAttributes(MetadataAttribute[] memory attributes)
        private
        pure
        returns (string memory)
    {
        bytes memory byteString;

        byteString = abi.encodePacked(byteString, _openJsonArray());

        for (uint256 i = 0; i < attributes.length; i++) {
            MetadataAttribute memory attribute = attributes[i];

            byteString = abi.encodePacked(
                byteString,
                _pushJsonArrayElement(
                    _getAttribute(attribute),
                    i < (attributes.length - 1)
                )
            );
        }

        byteString = abi.encodePacked(byteString, _closeJsonArray());

        return string(byteString);
    }

    function _getAttribute(MetadataAttribute memory attribute)
        private
        pure
        returns (string memory)
    {
        bytes memory byteString;

        byteString = abi.encodePacked(byteString, _openJsonObject());

        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute(
                "display_type",
                attribute.displayType,
                true
            )
        );

        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute(
                "trait_type",
                attribute.traitType,
                true
            )
        );

        if (attribute.isValueAString) {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveStringAttribute(
                    "value",
                    attribute.value,
                    false
                )
            );
        } else {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveNonStringAttribute(
                    "value",
                    attribute.value,
                    false
                )
            );
        }

        byteString = abi.encodePacked(byteString, _closeJsonObject());

        return string(byteString);
    }

    function _getJsonAttributes(IUltraSoundEditions.Edition memory edition)
        private
        pure
        returns (MetadataAttribute[] memory)
    {
        // prettier-ignore
        MetadataAttribute[] memory metadataAttributes = new MetadataAttribute[](6);

        metadataAttributes[0] = _getMetadataAttribute(
            false,
            "number",
            "Block Number",
            edition.blockNumber.toString()
        );
        metadataAttributes[1] = _getMetadataAttribute(
            false,
            "date",
            "Block Time",
            edition.blockTime.toString()
        );
        metadataAttributes[2] = _getMetadataAttribute(
            false,
            "number",
            "Base Fee",
            edition.baseFee.toString()
        );
        metadataAttributes[3] = _getMetadataAttribute(
            false,
            "number",
            "Merge Count",
            edition.mergeCount.toString()
        );
        metadataAttributes[4] = _getMetadataAttribute(
            true,
            "string",
            "Ultra Sound",
            edition.ultraSound ? "True" : "False"
        );
        metadataAttributes[5] = _getMetadataAttribute(
            false,
            "number",
            "Level",
            edition.level.toString()
        );

        return metadataAttributes;
    }

    function _getMetadataAttribute(
        bool isValueAString,
        string memory displayType,
        string memory traitType,
        string memory value
    ) private pure returns (MetadataAttribute memory) {
        MetadataAttribute memory attribute = MetadataAttribute({
            isValueAString: isValueAString,
            displayType: displayType,
            traitType: traitType,
            value: value
        });

        return attribute;
    }

    function _openJsonObject() private pure returns (string memory) {
        return string(abi.encodePacked("{"));
    }

    function _closeJsonObject() private pure returns (string memory) {
        return string(abi.encodePacked("}"));
    }

    function _openJsonArray() private pure returns (string memory) {
        return string(abi.encodePacked("["));
    }

    function _closeJsonArray() private pure returns (string memory) {
        return string(abi.encodePacked("]"));
    }

    function _pushJsonPrimitiveStringAttribute(
        string memory key,
        string memory value,
        bool insertComma
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '"',
                    key,
                    '": "',
                    value,
                    '"',
                    insertComma ? "," : ""
                )
            );
    }

    function _pushJsonComplexAttribute(
        string memory key,
        string memory value,
        bool insertComma
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked('"', key, '": ', value, insertComma ? "," : "")
            );
    }

    function _pushJsonPrimitiveNonStringAttribute(
        string memory key,
        string memory value,
        bool insertComma
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked('"', key, '": ', value, insertComma ? "," : "")
            );
    }

    function _pushJsonArrayElement(string memory value, bool insertComma)
        private
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(value, insertComma ? "," : ""));
    }
}