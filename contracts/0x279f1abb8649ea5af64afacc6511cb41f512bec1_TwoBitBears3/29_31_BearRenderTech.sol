// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@theappstudio/solidity/contracts/utils/DecimalStrings.sol";
import "@theappstudio/solidity/contracts/utils/OnChain.sol";
import "@theappstudio/solidity/contracts/utils/Randomization.sol";
import "@theappstudio/solidity/contracts/utils/SVG.sol";
import "./BearRenderTechErrors.sol";
import "../interfaces/ICubTraits.sol";
import "../interfaces/IBear3Traits.sol";
import "../interfaces/IBearRenderer.sol";
import "../interfaces/IBearRenderTech.sol";
import "../interfaces/IBearRenderTechProvider.sol";
import "../tokens/TwoBitCubs.sol";

/// @title BearRendering3
contract BearRenderTech is Ownable, IBearRenderTech, IBearRenderTechProvider {

    using Strings for uint256;
    using DecimalStrings for uint256;

    /// Represents an encoding of a number
    struct NumberEncoding {
        uint8 bytesPerPoint;
        uint8 decimals;
        bool signed;
    }

    /// @dev The Black Bear SVG renderer
    IBearRenderer private _blackBearRenderer;

    /// @dev The Brown Bear SVG renderer
    IBearRenderer private _brownBearRenderer;

    /// @dev The Panda Bear SVG renderer
    IBearRenderer private _pandaBearRenderer;

    /// @dev The Polar Bear SVG renderer
    IBearRenderer private _polarBearRenderer;

    /// @dev Reference to the TwoBitCubs contract
    TwoBitCubs private immutable _twoBitCubs;

    /// @dev Controls the reveal
    bool private _wenReveal;

    /// Look...at these...Bears
    constructor(address twoBitCubs) {
        _twoBitCubs = TwoBitCubs(twoBitCubs);
    }

    /// Applies the four IBearRenderers
    /// @param blackRenderer The Black Bear renderer
    /// @param brownRenderer The Brown Bear renderer
    /// @param pandaRenderer The Panda Bear renderer
    /// @param polarRenderer The Polar Bear renderer
    function applyRenderers(address blackRenderer, address brownRenderer, address pandaRenderer, address polarRenderer) external onlyOwner {
        if (address(_blackBearRenderer) != address(0) ||
            address(_brownBearRenderer) != address(0) ||
            address(_pandaBearRenderer) != address(0) ||
            address(_polarBearRenderer) != address(0)) revert AlreadyConfigured();
        _blackBearRenderer = IBearRenderer(blackRenderer);
        _brownBearRenderer = IBearRenderer(brownRenderer);
        _pandaBearRenderer = IBearRenderer(pandaRenderer);
        _polarBearRenderer = IBearRenderer(polarRenderer);
    }

    function backgroundForType(IBear3Traits.BackgroundType background) public pure returns (string memory) {
        string[3] memory backgrounds = ["White Tundra", "Green Forest", "Blue Shore"];
        return backgrounds[uint(background)];
    }

    /// @inheritdoc IBearRenderTech
    function createSvg(IBear3Traits.Traits memory traits, uint256 tokenId) public view onlyWenRevealed returns (bytes memory) {
        IBearRenderer renderer = _rendererForTraits(traits);
        ISVGTypes.Color memory eyeColor = renderer.customEyeColor(_twoBitCubs.traitsV1(traits.firstParentTokenId));
        return SVG.createElement("svg", SVG.svgAttributes(447, 447), abi.encodePacked(
            _defs(renderer, traits, eyeColor, tokenId),
            this.rectElement(100, 100, " fill='url(#background)'"),
            this.pathElement(hex'224d76126b084c81747bfb4381f57cdd821c7de981df7ee74381a37fe5810880c2802f81514c5b3b99a8435a359a5459049aaf57cc9ab0569ab04356939ab055619a55545b99a94c2f678151432e8e80c22df37fe52db77ee7432d7b7de92da17cdd2e227bfb4c39846b0a4c57ca6b0a566b084c76126b085a', "url(#chest)"),
            this.polygonElement(hex'1207160d0408bc0da20a620d040c0a0a9b08bc0a9b056e0a9b', "url(#neck)"),
            renderer.customSurfaces(traits.genes, eyeColor, tokenId)
        ));
    }

    /// @inheritdoc IBearRenderTechProvider
    function dynamicPolygonElement(bytes memory points, bytes memory fill, Substitution[] memory substitutions) external view onlyRenderer returns (bytes memory) {
        return SVG.createElement("polygon", abi.encodePacked(" points='", _polygonPoints(points, substitutions), "' fill='", fill, "'"), "");
    }

    /// @inheritdoc IBearRenderTech
    function familyForTraits(IBear3Traits.Traits memory traits) public view override onlyWenRevealed returns (string memory) {
        string[18] memory families = ["Hirst", "Stark", "xCopy", "Watkinson", "Davis", "Evan Dennis", "Anderson", "Pak", "Greenawalt", "Capacity", "Hobbs", "Deafbeef", "Rainaud", "Snowfro", "Winkelmann", "Fairey", "Nines", "Maeda"];
        return families[(uint(uint8(bytes22(traits.genes)[1])) + uint(traits.familyIndex)) % 18];
    }

    /// @inheritdoc IBearRenderTechProvider
    function linearGradient(bytes memory id, bytes memory points, bytes memory stop1, bytes memory stop2) external view onlyRenderer returns (bytes memory) {
        string memory stop = "stop";
        NumberEncoding memory encoding = _readEncoding(points);
        bytes memory attributes = abi.encodePacked(
            " id='", id,
            "' x1='", _decimalStringFromBytes(points, 1, encoding),
            "' x2='", _decimalStringFromBytes(points, 1 + encoding.bytesPerPoint, encoding),
            "' y1='", _decimalStringFromBytes(points, 1 + 2 * encoding.bytesPerPoint, encoding),
            "' y2='", _decimalStringFromBytes(points, 1 + 3 * encoding.bytesPerPoint, encoding), "'"
        );
        return SVG.createElement("linearGradient", attributes, abi.encodePacked(
            SVG.createElement(stop, stop1, ""), SVG.createElement(stop, stop2, "")
        ));
    }

    /// @inheritdoc IBearRenderTech
    function metadata(IBear3Traits.Traits memory traits, uint256 tokenId) external view returns (bytes memory) {
        string memory token = tokenId.toString();
        if (_wenReveal) {
            return OnChain.dictionary(OnChain.commaSeparated(
                OnChain.keyValueString("name", abi.encodePacked(nameForTraits(traits), " ", familyForTraits(traits), " the ", moodForType(traits.mood), " ", speciesForType(traits.species), " Bear ", token)),
                OnChain.keyValueArray("attributes", _attributesFromTraits(traits)),
                OnChain.keyValueString("image", OnChain.svgImageURI(bytes(createSvg(traits, tokenId))))
            ));
        }
        return OnChain.dictionary(OnChain.commaSeparated(
            OnChain.keyValueString("name", abi.encodePacked("Rendering Bear ", token)),
            OnChain.keyValueString("image", "ipfs://QmUZ3ojSLv3rbu8egkS5brb4ETkNXXmcgCFG66HeFBXn54")
        ));
    }

    /// @inheritdoc IBearRenderTech
    function moodForType(IBear3Traits.MoodType mood) public pure override returns (string memory) {
        string[14] memory moods = ["Happy", "Hungry", "Sleepy", "Grumpy", "Cheerful", "Excited", "Snuggly", "Confused", "Ravenous", "Ferocious", "Hangry", "Drowsy", "Cranky", "Furious"];
        return moods[uint256(mood)];
    }

    /// @inheritdoc IBearRenderTech
    function nameForTraits(IBear3Traits.Traits memory traits) public view override onlyWenRevealed returns (string memory) {
        string[50] memory names = ["Cophi", "Trace", "Abel", "Ekko", "Goomba", "Milk", "Arth", "Roeleman", "Adjudicator", "Kelly", "Tropo", "Type3", "Jak", "Srsly", "Triggity", "SNR", "Drogate", "Scott", "Timm", "Nutsaw", "Rugged", "Vaypor", "XeR0", "Toasty", "BN3", "Dunks", "JFH", "Eallen", "Aspen", "Krueger", "Nouside", "Fonky", "Ian", "Metal", "Bones", "Cruz", "Daniel", "Buz", "Bliargh", "Strada", "Lanky", "Westwood", "Rie", "Moon", "Mango", "Hammer", "Pizza", "Java", "Gremlin", "Hash"];
        return names[(uint(uint8(bytes22(traits.genes)[0])) + uint(traits.nameIndex)) % 50];
    }

    /// Prevents a function from executing if not called by an authorized party
    modifier onlyRenderer() {
        if (_msgSender() != address(_blackBearRenderer) &&
            _msgSender() != address(_brownBearRenderer) &&
            _msgSender() != address(_pandaBearRenderer) &&
            _msgSender() != address(_polarBearRenderer) &&
            _msgSender() != address(this)) revert OnlyRenderer();
        _;
    }

    /// Prevents a function from executing until wenReveal is set
    modifier onlyWenRevealed() {
        if (!_wenReveal) revert NotYetRevealed();
        _;
    }

    /// @inheritdoc IBearRenderTechProvider
    function pathElement(bytes memory path, bytes memory fill) external view onlyRenderer returns (bytes memory result) {
        NumberEncoding memory encoding = _readEncoding(path);
        bytes memory attributes = " d='";
        uint index = 1;
        while (index < path.length) {
            bytes1 control = path[index++];
            attributes = abi.encodePacked(attributes, control);
            if (control == "C") {
                attributes = abi.encodePacked(attributes, _readNext(path, encoding, 6, index));
                index += 6 * encoding.bytesPerPoint;
            } else if (control == "H") { // Not used by any IBearRenderers anymore
                attributes = abi.encodePacked(attributes, _readNext(path, encoding, 1, index));
                index += encoding.bytesPerPoint;
            } else if (control == "L") {
                attributes = abi.encodePacked(attributes, _readNext(path, encoding, 2, index));
                index += 2 * encoding.bytesPerPoint;
            } else if (control == "M") {
                attributes = abi.encodePacked(attributes, _readNext(path, encoding, 2, index));
                index += 2 * encoding.bytesPerPoint;
            } else if (control == "V") {
                attributes = abi.encodePacked(attributes, _readNext(path, encoding, 1, index));
                index += encoding.bytesPerPoint;
            }
        }
        return SVG.createElement("path", abi.encodePacked(attributes, "' fill='", fill, "'"), "");
    }

    /// @inheritdoc IBearRenderTechProvider
    function polygonElement(bytes memory points, bytes memory fill) external view onlyRenderer returns (bytes memory) {
        return SVG.createElement("polygon", abi.encodePacked(" points='", _polygonPoints(points, new Substitution[](0)), "' fill='", fill, "'"), "");
    }

    /// @inheritdoc IBearRenderTechProvider
    function rectElement(uint256 widthPercentage, uint256 heightPercentage, bytes memory attributes) external view onlyRenderer returns (bytes memory) {
        return abi.encodePacked("<rect width='", widthPercentage.toString(), "%' height='", heightPercentage.toString(), "%'", attributes, "/>");
    }

    /// Wen the world is ready
    /// @dev Only the contract owner can invoke this
    function revealBears() external onlyOwner {
        _wenReveal = true;
    }

    /// @inheritdoc IBearRenderTech
    function scarsForTraits(IBear3Traits.Traits memory traits) public view onlyWenRevealed returns (IBear3Traits.ScarColor[] memory) {
        bytes22 geneBytes = bytes22(traits.genes);
        uint8 scarCountProvider = uint8(geneBytes[18]);
        uint scarCount = Randomization.randomIndex(scarCountProvider, _scarCountPercentages());
        IBear3Traits.ScarColor[] memory scars = new IBear3Traits.ScarColor[](scarCount == 0 ? 1 : scarCount);
        if (scarCount == 0) {
            scars[0] = IBear3Traits.ScarColor.None;
        } else {
            uint8 scarColorProvider = uint8(geneBytes[17]);
            uint scarColor = Randomization.randomIndex(scarColorProvider, _scarColorPercentages());
            for (uint scar = 0; scar < scarCount; scar++) {
                scars[scar] = IBear3Traits.ScarColor(scarColor+1);
            }
        }
        return scars;
    }

    /// @inheritdoc IBearRenderTech
    function scarForType(IBear3Traits.ScarColor scarColor) public pure override returns (string memory) {
        string[4] memory scarColors = ["None", "Blue", "Magenta", "Gold"];
        return scarColors[uint256(scarColor)];
    }

    /// @inheritdoc IBearRenderTech
    function speciesForType(IBear3Traits.SpeciesType species) public pure override returns (string memory) {
        string[4] memory specieses = ["Brown", "Black", "Polar", "Panda"];
        return specieses[uint256(species)];
    }

    function _attributesFromTraits(IBear3Traits.Traits memory traits) private view returns (bytes memory) {
        bytes memory attributes = OnChain.commaSeparated(
            OnChain.traitAttribute("Species", bytes(speciesForType(traits.species))),
            OnChain.traitAttribute("Mood", bytes(moodForType(traits.mood))),
            OnChain.traitAttribute("Background", bytes(backgroundForType(traits.background))),
            OnChain.traitAttribute("First Name", bytes(nameForTraits(traits))),
            OnChain.traitAttribute("Last Name (Gen 4 Scene)", bytes(familyForTraits(traits))),
            OnChain.traitAttribute("Parents", abi.encodePacked("#", uint(traits.firstParentTokenId).toString(), " & #", uint(traits.secondParentTokenId).toString()))
        );
        bytes memory scarAttributes = OnChain.traitAttribute("Scars", _scarDescription(scarsForTraits(traits)));
        attributes = abi.encodePacked(attributes, OnChain.continuesWith(scarAttributes));
        bytes memory gen4Attributes = OnChain.traitAttribute("Gen 4 Claim Status", bytes(traits.gen4Claimed ? "Claimed" : "Unclaimed"));
        return abi.encodePacked(attributes, OnChain.continuesWith(gen4Attributes));
    }

    function _decimalStringFromBytes(bytes memory encoded, uint startIndex, NumberEncoding memory encoding) private pure returns (bytes memory) {
        (uint value, bool isNegative) = _uintFromBytes(encoded, startIndex, encoding);
        return value.toDecimalString(encoding.decimals, isNegative);
    }

    function _defs(IBearRenderer renderer, IBear3Traits.Traits memory traits, ISVGTypes.Color memory eyeColor, uint256 tokenId) private view returns (bytes memory) {
        string[3] memory firstStop = ["#fff", "#F3FCEE", "#EAF4F9"];
        string[3] memory lastStop = ["#9C9C9C", "#A6B39E", "#98ADB5"];
        return SVG.createElement("defs", "", abi.encodePacked(
            this.linearGradient("background", hex'32000003ea000003e6',
                abi.encodePacked(" offset='0.44521' stop-color='", firstStop[uint(traits.background)], "'"),
                abi.encodePacked(" offset='0.986697' stop-color='", lastStop[uint(traits.background)], "'")
            ),
            renderer.customDefs(traits.genes, eyeColor, scarsForTraits(traits), tokenId)
        ));
    }

    function _polygonCoordinateFromBytes(bytes memory encoded, uint startIndex, NumberEncoding memory encoding, Substitution[] memory substitutions) private pure returns (bytes memory) {
        (uint x, bool xIsNegative) = _uintFromBytes(encoded, startIndex, encoding);
        (uint y, bool yIsNegative) = _uintFromBytes(encoded, startIndex + encoding.bytesPerPoint, encoding);
        for (uint index = 0; index < substitutions.length; index++) {
            if (x == substitutions[index].matchingX && y == substitutions[index].matchingY) {
                x = substitutions[index].replacementX;
                y = substitutions[index].replacementY;
                break;
            }
        }
        return OnChain.commaSeparated(x.toDecimalString(encoding.decimals, xIsNegative), y.toDecimalString(encoding.decimals, yIsNegative));
    }

    function _polygonPoints(bytes memory points, Substitution[] memory substitutions) private pure returns (bytes memory pointsValue) {
        NumberEncoding memory encoding = _readEncoding(points);

        pointsValue = abi.encodePacked(_polygonCoordinateFromBytes(points, 1, encoding, substitutions));
        uint bytesPerIteration = encoding.bytesPerPoint << 1; // Double because this method processes 2 points at a time
        for (uint byteIndex = 1 + bytesPerIteration; byteIndex < points.length; byteIndex += bytesPerIteration) {
            pointsValue = abi.encodePacked(pointsValue, " ", _polygonCoordinateFromBytes(points, byteIndex, encoding, substitutions));
        }
    }

    function _readEncoding(bytes memory encoded) private pure returns (NumberEncoding memory encoding) {
        encoding.decimals = uint8(encoded[0] >> 4) & 0xF;
        encoding.bytesPerPoint = uint8(encoded[0]) & 0x7;
        encoding.signed = uint8(encoded[0]) & 0x8 == 0x8;
    }

    function _readNext(bytes memory encoded, NumberEncoding memory encoding, uint numbers, uint startIndex) private pure returns (bytes memory result) {
        result = _decimalStringFromBytes(encoded, startIndex, encoding);
        for (uint index = startIndex + encoding.bytesPerPoint; index < startIndex + (numbers * encoding.bytesPerPoint); index += encoding.bytesPerPoint) {
            result = abi.encodePacked(result, " ", _decimalStringFromBytes(encoded, index, encoding));
        }
    }

    function _rendererForTraits(IBear3Traits.Traits memory traits) private view returns (IBearRenderer) {
        if (traits.species == IBear3Traits.SpeciesType.Black) {
            return _blackBearRenderer;
        } else if (traits.species == IBear3Traits.SpeciesType.Brown) {
            return _brownBearRenderer;
        } else if (traits.species == IBear3Traits.SpeciesType.Panda) {
            return _pandaBearRenderer;
        } else /* if (traits.species == IBear3Traits.SpeciesType.Polar) */ {
            return _polarBearRenderer;
        }
    }

    function _scarColorPercentages() private pure returns (uint8[] memory percentages) {
        uint8[] memory array = new uint8[](2);
        array[0] = 60; // 60% Blue
        array[1] = 30; // 30% Magenta
        return array; // 10% Gold
    }

    function _scarCountPercentages() private pure returns (uint8[] memory percentages) {
        uint8[] memory array = new uint8[](2);
        array[0] = 70; // 70% None
        array[1] = 20; // 20% One
        return array; // 10% Two
    }

    function _scarDescription(IBear3Traits.ScarColor[] memory scarColors) private pure returns (bytes memory) {
        if (scarColors.length == 0 || scarColors[0] == IBear3Traits.ScarColor.None) {
            return bytes(scarForType(IBear3Traits.ScarColor.None));
        } else {
            return abi.encodePacked(scarColors.length.toString(), " ", scarForType(scarColors[0]));
        }
    }

    function _uintFromBytes(bytes memory encoded, uint startIndex, NumberEncoding memory encoding) private pure returns (uint result, bool isNegative) {
        result = uint8(encoded[startIndex]);
        if (encoding.signed) {
            isNegative = result & 0x80 == 0x80;
            result &= 0x7F;
        }
        uint stopIndex = startIndex + encoding.bytesPerPoint;
        for (uint index = startIndex + 1; index < stopIndex; index++) {
            result = (result << 8) + uint(uint8(encoded[index]));
        }
    }
}