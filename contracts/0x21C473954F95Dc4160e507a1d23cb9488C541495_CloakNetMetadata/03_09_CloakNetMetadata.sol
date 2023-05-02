// SPDX-License-Identifier: AGPL-3.0
// ©2023 Ponderware Ltd

pragma solidity ^0.8.17;

import "../lib/Base64.sol";
import "../lib/ENSNamehash.sol";
import "../lib/ItemStorage.sol";
import "../lib/image/GIF32.sol";
import "../lib/image/PixelSVG.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IReverseRegistrar {
    function node(address addr) external view returns (bytes32);
}

interface IReverseResolver {
    function name(bytes32 node) external view returns (string memory);
}

interface IResolver {
    function addr(bytes32 node) external view returns (address);
}

interface IENS {
    function resolver (bytes32 node) external view returns (address);
}

interface ICodex {
    function ENSReverseRegistrar () external view returns (address);
    function ENSReverseResolver () external view returns (address);
    function ENS () external view returns (address);
}

interface ITypeface {
    struct Font {
        uint256 weight;
        string style;
    }
    function sourceOf(Font memory font) external view returns (bytes memory);
}

struct Signal {
    uint16 tokenId;
    uint8 style;
    uint32 startBlock;
    address sender;
    uint40 message1;
    uint256 message2;
}

contract CloakNetMetadata {

    address CodexAddress;

    constructor (address _authorized, address codex) {
        CodexAddress = codex;
        authorized = _authorized;

        font = ITypeface.Font(300, "normal");
        ItemStorage.sideload(ModelData, 10, 0x02aCF9B3712dff73C1c800e03318B9708171BAeE);
        ItemStorage.sideload(ModelData, 10, 0x3d8Dd08e6eEF791C96CdeA0D39068D6BBeA8C665);
    }

    address internal authorized;

    modifier onlyAuthorized () {
        require(msg.sender == authorized, "Unauthorized");
        _;
    }

    ItemStorage.Store internal ModelData;

    string[10] ModelDetails = ["jabber walkie",
                               "vintage long range communication device once popular among children.",

                               "mangled drone crow",
                               "raised from a hatchling to serve [REDACTED]; in death it finds greater purpose.",

                               "derelict coin-op",
                               "before the code.94 prohibition on games and game-like activities, these were quite common.",

                               "surplus zappersat",
                               "remnant of ZapperFresh's pioneering efforts to commoditize orbital convenience foods.",

                               "arcane contraption",
                               "antique mechanical oracles and a paper clip."];

    /* Unpack Models */

    struct Model {
        uint8 width;
        uint8 height;
        uint8 aniX;
        uint8 aniY;
        uint8 aniWidth;
        uint8 aniHeight;
        uint8 offsetX;
        uint8 offsetY;
        bytes f1;
        bytes f2;
        bytes f3;
        bytes f4;
    }

    function slice(uint begin, uint len, bytes memory arr) internal pure returns (bytes memory) {
        bytes memory res = new bytes(len);
        for (uint i = 0; i < len; i++) {
            res[i] = arr[i+begin];
        }
        return res;
    }

    function slice2(uint loc, bytes memory arr) internal pure returns (uint) {
        uint res = uint(uint8(arr[loc])) << 8;
        return (res + uint8(arr[loc + 1]));
    }

    function unpackModel (bytes memory input) internal pure returns (Model memory) {

        uint pointer = 8;
        uint len = slice2(pointer, input);
        pointer += 2;
        bytes memory f1 = slice(pointer, len, input);

        pointer += len;
        len = slice2(pointer, input);
        pointer += 2;
        bytes memory f2 = slice(pointer, len, input);

        pointer += len;
        len = slice2(pointer, input);
        pointer += 2;
        bytes memory f3 = slice(pointer, len, input);

        pointer += len;
        len = slice2(pointer, input);
        pointer += 2;
        bytes memory f4 = slice(pointer, len, input);

        return Model(uint8(bytes1(input[0])),
                     uint8(bytes1(input[1])),
                     uint8(bytes1(input[2])),
                     uint8(bytes1(input[3])),
                     uint8(bytes1(input[4])),
                     uint8(bytes1(input[5])),
                     uint8(bytes1(input[6])),
                     uint8(bytes1(input[7])),
                     f1,
                     f2,
                     f3,
                     f4);
    }

    /* Model Data Storage */

    function getModel (uint id) internal view returns (Model memory) {
        return unpackModel(ItemStorage.bget(ModelData, id));
    }

    /* Transmissions */

    struct Transmission {
        uint length;
        string message;
        string handle;
    }

    function signalToTransmission (uint40 message1, uint256 message2, string memory handle, uint handleLength) internal pure returns (Transmission memory) {
        bytes5 message1 = bytes5(message1);
        bytes32 message2 = bytes32(message2);
        uint messageLength = 0;

        for (; messageLength < 37; messageLength++) {
            if (messageLength < 5) {
                if (uint8(message1[messageLength]) == 0) break;
            } else if (uint8(message2[messageLength - 5]) == 0) break;
        }

        bytes memory temp = new bytes(messageLength);
        for (uint i = 0; i < messageLength; i++) {
            if (i < 5) temp[i] = message1[i];
            else temp[i] = message2[i - 5];
        }

        string memory message = string(temp);

        uint length = messageLength + handleLength;
        if (handleLength > 0) {
            length += 2;
        }

        return Transmission(length, message, handle);
    }

    /* Font */

    ITypeface.Font font;
    address typefaceAddress = 0xA77b7D93E79f1E6B4f77FaB29d9ef85733A3D44A;

    function adjustTypeface (address _typefaceAddress, uint256 weight, string memory style) public onlyAuthorized {
        typefaceAddress = _typefaceAddress;
        font = ITypeface.Font(weight, style);
    }

    /* Text Handling */

    function measureString (string memory utf8string) internal pure returns (uint) {
        bytes memory bs = bytes(utf8string);
        for (uint i = 0; i < bs.length; i++) {
            uint b = uint8(bs[i]);
            if ((b >= 97 && b <= 122) || // a-z
                (b == 32) || // " "
                (b >= 45 && b <= 57) || // - . / 0-9
                (b == 39) || // '
                (b == 63) || // ?
                (b == 95) || // _
                (b == 33)) continue; // !
            return 0;
        }
        return bs.length;
    }

    /* Handles */

    function getENSName (address addr) internal view returns (string memory) {
        bytes32 nodeReverse = IReverseRegistrar(ICodex(CodexAddress).ENSReverseRegistrar()).node(addr);
        string memory name = IReverseResolver(ICodex(CodexAddress).ENSReverseResolver()).name(nodeReverse);
        bytes32 nodeForeward = ENSNamehash.namehash(bytes(name));
        address resolverAddress = IENS(ICodex(CodexAddress).ENS()).resolver(nodeForeward);
        if (bytes(name).length == 0 || addr != IResolver(resolverAddress).addr(nodeForeward)) {
            return "";
        }
        return name;
    }

    function addressHandle (address lawless) internal pure returns (bytes memory handle) {
        bytes memory name = bytes(Strings.toHexString(lawless));
        handle = new bytes(9);
        handle[4] = ".";
        for (uint i = 0; i < 4; i++) {
            handle[i] = name[i + 2];
        }
        for (uint i = 5; i < 9; i++) {
            handle[i] = name[i + 33];
        }
    }

    function getHandle (address lawless) internal view returns (string memory, uint) {
        string memory handle = getENSName(lawless);
        if (bytes(handle).length > 0) {
            uint handleLength = measureString(handle);
            if (handleLength > 0) {
                return (handle, handleLength);
            }
        }
        return (string(addressHandle(lawless)), 9);
    }

    /* GIFs */

    uint8 constant MCS = 5;

    function animatedGIF (Model memory m, bytes memory chroma) internal pure returns (string memory) {
        bytes memory framedata = abi.encodePacked(abi.encodePacked(GIF32.gce(false, 30, 0),
                                                                   GIF32.frame(0, 0, m.width, m.height, MCS, m.f1)),

                                                  GIF32.gce(true, 1, 0),
                                                  GIF32.frame(m.aniX, m.aniY, m.aniWidth, m.aniHeight, MCS, m.f2),

                                                  GIF32.gce(true, 29, 0),
                                                  GIF32.frame(m.aniX, m.aniY, m.aniWidth, m.aniHeight, MCS, m.f3),

                                                  GIF32.gce(true, 30, 0),
                                                  GIF32.frame(m.aniX, m.aniY, m.aniWidth, m.aniHeight, MCS, m.f4));
        bytes memory gif = GIF32.assembleAnimated(m.width, m.height, framedata, MCS, chroma);
        return string(abi.encodePacked("data:image/gif;base64,", Base64.encode(gif)));
    }

    /* SVG */

    uint constant private SCALE_FACTOR = 10;

    function position (Model memory m) internal pure returns (int x, int y, uint width, uint height) {
        width = m.width * SCALE_FACTOR;
        height = m.height * SCALE_FACTOR;
        x = int(uint(m.offsetX) * SCALE_FACTOR);
        y = int(uint(m.offsetY) * SCALE_FACTOR);
    }

    function SVGImg (uint modelId, bytes memory chroma) internal view returns (bytes memory) {
        Model memory m = getModel(modelId);
        string memory gif = animatedGIF(getModel(modelId), chroma);
        (int x, int y, uint width, uint height) = position(m);
        return PixelSVG.img(x, y, width, height, gif);
    }

    function getRGB (bytes memory chroma, uint index) internal pure returns (bytes memory) {
        uint r = uint8(chroma[index * 3]);
        uint g = uint8(chroma[index * 3 + 1]);
        uint b = uint8(chroma[index * 3 + 2]);
        return abi.encodePacked("rgb(", Strings.toString(r),",", Strings.toString(g),",", Strings.toString(b),")");
    }

    bytes constant internal STYLE_PREAMBLE = bytes("<style>text.cl { font-size: 80px; white-space: pre; font-weight: 100; font-family: Capsules, Courier New, Courier, mono; } @font-face { font-family: 'Capsules'; src: url(data:font/truetype;charset=utf-8;base64,");

    function SVGStyle () internal view returns (bytes memory) {
        return abi.encodePacked(STYLE_PREAMBLE,
                                ITypeface(typefaceAddress).sourceOf(font),
                                ") format('opentype')}</style>");
    }

    function SVGTspans (string memory message, string memory handle) internal pure returns (bytes memory) {
        bytes memory signature;
        if (bytes(handle).length > 0) {
            bytes memory handleSuffix;
            bytes memory handleStripped;
            if (bytes1(bytes(handle)[bytes(handle).length - 1]) == bytes1(bytes("h"))) {
                handleSuffix = ".eth";
                handleStripped = new bytes(bytes(handle).length - 4);
                for (uint i = 0; i < handleStripped.length; i++) {
                    handleStripped[i] = bytes(handle)[i];
                }
            } else {
                handleStripped = bytes(handle);
            }
            signature = abi.encodePacked("<tspan fill-opacity='0.4'> @",
                                         handleStripped,
                                         "</tspan><tspan fill-opacity='0.2'>",
                                         handleSuffix,
                                         "</tspan>");
        }
        return abi.encodePacked("<tspan>", message, "</tspan>", signature);
    }

    function pctString (uint x) internal pure returns (bytes memory) {
        bytes memory res = new bytes(5);
        if (x >= 100) {
            return bytes("0.999;");
        }
        res[0] = bytes1(bytes("0"));
        res[1] = bytes1(bytes("."));
        res[4] = bytes1(bytes(";"));
        if (x < 10) {
            res[2] = bytes1(bytes("0"));
            res[3] = bytes1(bytes(Strings.toString(x))[0]);
        } else {
            bytes memory temp = bytes(Strings.toString(x));
            res[2] = bytes1(temp[0]);
            res[3] = bytes1(temp[1]);
        }
        return res;
    }

    uint constant internal BETWEEN_MESSAGE_TIME_1000 = 3000;
    uint constant internal BOX_ANIMATION_TIME_1000 = 500;
    uint constant internal DUR_ADD = (BETWEEN_MESSAGE_TIME_1000 + 2 * BOX_ANIMATION_TIME_1000) / 100;
    uint constant internal EXTRA_CHARS_FOR_BLANKING = 13;
    uint constant internal SCROLL_SPEED_DENOMINATOR = 8;

    function intoKeyTimes (Transmission[] memory ts, uint totalDur10) internal pure returns (bytes memory, bytes memory) {
        uint intervalPct = BETWEEN_MESSAGE_TIME_1000 / totalDur10;
        uint boxTransitionPct = BOX_ANIMATION_TIME_1000 / totalDur10;
        if (intervalPct < 2) intervalPct = 2;
        if (boxTransitionPct < 1) boxTransitionPct = 1;
        uint scrollDelta = intervalPct + (boxTransitionPct * 2);
        bytes memory boxKeyTimes = bytes("0;");
        bytes memory scrollKeyTimes = bytes("0;");
        uint boxCursor;
        uint scrollCursor;
        for (uint i = 0; i < ts.length; i++) {
            uint dur10 = (ts[i].length + EXTRA_CHARS_FOR_BLANKING) * 10 / SCROLL_SPEED_DENOMINATOR + DUR_ADD;
            uint scrollPct = ((dur10 * 100 / totalDur10) - scrollDelta);
            boxKeyTimes = abi.encodePacked(boxKeyTimes,
                                           pctString(boxCursor += intervalPct),
                                           pctString(boxCursor += boxTransitionPct),
                                           pctString(boxCursor += scrollPct),
                                           pctString(boxCursor += boxTransitionPct));
            scrollKeyTimes = abi.encodePacked(scrollKeyTimes,
                                              pctString(scrollCursor += (i == 0 ? (intervalPct + boxTransitionPct): scrollDelta)),
                                              pctString(scrollCursor += scrollPct));
        }
        return (abi.encodePacked(boxKeyTimes, "1"), abi.encodePacked(scrollKeyTimes, "1"));
    }

    function generateKeyTimes (Transmission[] memory ts) internal pure returns (bytes memory, bytes memory, bytes memory) {

        uint totalDur10;
        for (uint i = 0;  i < ts.length; i++) {
            totalDur10 += (ts[i].length + EXTRA_CHARS_FOR_BLANKING) * 10 / SCROLL_SPEED_DENOMINATOR + DUR_ADD;
        }
        (bytes memory boxKeyTimes, bytes memory scrollKeyTimes) = intoKeyTimes(ts, totalDur10);
        bytes memory s = bytes(Strings.toString(totalDur10));
        bytes memory duration = new bytes(s.length + 1);
        uint j = 0;
        for (; j < s.length - 1; j++) {
            duration[j] = s[j];
        }
        duration[j] = bytes1(bytes("."));
        duration[j+1] = s[j];
        return (duration, boxKeyTimes, scrollKeyTimes);
    }

    function SVGMarqueeBox (bytes memory duration, bytes memory boxKeyTimes, uint totalSegments, bytes memory chroma) internal pure returns (bytes memory) {
        bytes memory values = bytes("600;600;480;480;600;600");
        for (uint i = 1; i < totalSegments; i++) {
            values = abi.encodePacked(values, ";480;480;600;600");
        }
        return abi.encodePacked("<rect y='600' x='0' width='600' height='120' fill='",
                                getRGB(chroma, 8),
                                "'><animate attributeType='XML' attributeName='y' values='", values, "' keyTimes='",
                                boxKeyTimes ,"'  dur='", duration,
                                "s' repeatCount='indefinite' /></rect>");
    }

    function SVGMarqueeText (bytes memory duration, bytes memory scrollKeyTimes, uint totalSegments, uint index, Transmission memory t, bytes memory chroma) internal pure returns (bytes memory) {
        uint distance = (t.length * 483) / 10 + 10;
        bytes memory finalPosition = abi.encodePacked("-", Strings.toString(distance));
        bytes memory values = "600;600";
        for(uint i = 0; i < totalSegments; i++) {
            if (i < index) {
                values = abi.encodePacked(values, ";600;600");
            } else {
                values = abi.encodePacked(values, ";", finalPosition, ";", finalPosition);
            }
        }
        bytes memory tspans = SVGTspans(t.message, t.handle);
        return abi.encodePacked("<text class='cl' x='600' y='568' fill='",
                                getRGB(chroma, 11),
                                "'><animate attributeType='XML' attributeName='x' values='",
                                values,
                                "' keyTimes='",
                                scrollKeyTimes,
                                "' dur='",
                                duration,
                                "s' repeatCount='indefinite' />",
                                tspans,
                                "</text>");
    }

    function SVGMarquee (bytes memory duration, bytes memory boxKeyTimes, bytes memory scrollKeyTimes, Transmission[] memory ts, bytes memory chroma) internal pure returns (bytes memory) {
        bytes memory marquee = SVGMarqueeBox(duration, boxKeyTimes, ts.length, chroma);
        for (uint i = 0; i < ts.length; i++) {
            Transmission memory t = ts[i];
            marquee = abi.encodePacked(marquee, SVGMarqueeText(duration, scrollKeyTimes, ts.length, i, t, chroma));
        }
        return marquee;
    }

    function disappearGroup (bytes memory duration, bytes memory boxKeyTimes, uint totalSegments, bytes memory message) internal pure returns (bytes memory) {
        bytes memory values = bytes("0;0;1;1;0;0");
        for (uint i = 1; i < totalSegments; i++) {
            values = abi.encodePacked(values, ";0;0;0;0");
        }
        return abi.encodePacked("<g><animate attributeType='XML' attributeName='opacity' values='", values, "' keyTimes='",
                                boxKeyTimes ,"'  dur='", duration,
                                "s' repeatCount='indefinite' />",
                                message, "</g>");
    }

    function opacityGroup (bytes memory img, string memory opacity) internal pure returns (bytes memory) {
        return abi.encodePacked("<g opacity='", opacity, "'>", img, "</g>");
    }


    function transponderImage (bytes memory duration, bytes memory boxKeyTimes, uint totalSegments, uint modelId, bytes memory chroma) internal view returns (bytes memory) {
        bytes memory broadcasting = disappearGroup(duration, boxKeyTimes, totalSegments,
                                                   abi.encodePacked(SVGImg(modelId * 4 + 2, chroma),
                                                                    opacityGroup(SVGImg(modelId * 4 + 3, chroma), "0.12")));

        return abi.encodePacked(SVGImg(modelId * 4 + 0, chroma),
                                opacityGroup(SVGImg(modelId * 4 + 1, chroma), "0.12"),
                                broadcasting);
    }

    bytes12[6] shift = [bytes12(0x1c65252798363acf4c53ff68),
                        bytes12(0x277e9535badc5acce6b7f2ff),
                        bytes12(0xcf8404f7a708fdd912fff527),
                        bytes12(0x651b1ca31f1ced2929ff5353),
                        bytes12(0x2a1c6a4918987d3acf9c49ff)];

    bytes constant Chroma = hex"554d3fff5d77ff0017ffeb330e0c0a161410211e17262626595959808080aaaaaae6e6e69e8e70d4be95f8dfaffefed2332e244e443272654f928265b7b794bdbd9c3927203c322e1c65252798363acf4c53ff68ff3fd4ff5bf3ff9affffcaff";

    string[5] internal ChromaNames = ["jade",
                                      "cobalt",
                                      "amber",
                                      "garnet",
                                      "amethyst"];

    function assembleSVG (uint modelId, uint chromaId, Transmission[] memory ts) internal view returns (string memory) {
        (bytes memory duration, bytes memory boxKeyTimes, bytes memory scrollKeyTimes) = generateKeyTimes(ts);
        bytes memory chroma = Chroma;

        for (uint i = 24; i < 36; i++) {
            chroma[i] = shift[chromaId][i - 24];
        }

        bytes memory marquee = SVGMarquee(duration, boxKeyTimes, scrollKeyTimes, ts, chroma);
        bytes memory svg = "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' preserveAspectRatio='xMidYMid meet' viewBox='0 0 600 600' width='600' height='600'>";
        bytes memory img = transponderImage(duration, boxKeyTimes, ts.length, modelId, chroma);
        return string(abi.encodePacked(svg,
                                       SVGStyle(),
                                       "<defs>"
                                       "<rect id='bg' x='0' y='0' width='600' height='600' fill='",
                                       getRGB(chroma, 0),
                                       "' /><clipPath id='c'><use xlink:href='#bg'/></clipPath></defs><g clip-path='url(#c)'><use xlink:href='#bg' />",
                                       img,
                                       marquee,
                                       "</g></svg>"));
    }

    function assembleSVGURI  (uint modelId, uint chromaId, Transmission[] memory ts) internal view returns (string memory) {
        return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(assembleSVG(modelId, chromaId, ts)))));
    }

    /* JSON */

    function encodeStringAttribute (string memory key, string memory value) internal pure returns (bytes memory) {
        return abi.encodePacked("{\"trait_type\":\"", key,"\",\"value\":\"",value,"\"}");
    }

    bool b64EncodeURI = false;

    function setB64EncodeURI (bool value) public onlyAuthorized {
        b64EncodeURI = value;
    }

    function toJSON (string memory name,
                     bytes memory description,
                     bytes memory attributes,
                     string memory image)
        internal view returns (string memory) {
        bytes memory json = abi.encodePacked("{\"attributes\":[",
                                             attributes,
                                             "], \"name\":\"",
                                             name,
                                             "\", \"description\":\"",
                                             description,
                                             "\",\"image\":\"",
                                             image,
                                             "\"}");
        if (b64EncodeURI) {
            return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
        } else {
            return string(abi.encodePacked("data:application/json;utf8,", json));
        }
    }

    function signalMetadata(uint peer, Signal memory local, Signal memory peer1, Signal memory peer2) public onlyAuthorized view returns (string memory) {
        Transmission[] memory ts = new Transmission[](3);
        string memory handle;
        {
            uint handleLength;
            (handle, handleLength) = getHandle(local.sender);
            ts[0] = signalToTransmission(local.message1, local.message2, handle, handleLength);
        }
        {
            (string memory peerHandle, uint handleLength) = getHandle(peer1.sender);
            ts[1] = signalToTransmission(peer1.message1, peer1.message2, peerHandle, handleLength);
        }
        {
            (string memory peerHandle, uint handleLength) = getHandle(peer2.sender);
            ts[2] = signalToTransmission(peer2.message1, peer2.message2, peerHandle, handleLength);
        }

        uint chromaId = (local.style >> 4) & 7;
        bytes memory attributes;
        {
            bytes memory preamble = encodeStringAttribute("peer", Strings.toString(peer));
            if (local.style >> 7 == 1) {
                preamble = abi.encodePacked(preamble, ",", encodeStringAttribute("err", "sigint")); // redacted
            }
            attributes = abi.encodePacked(preamble,
                                          abi.encodePacked(
                                                           ",", encodeStringAttribute("pkhash", Strings.toHexString(local.sender)),
                                                           ",", encodeStringAttribute("source", handle),
                                                           ",", encodeStringAttribute("plaintext", ts[0].message)),
                                          ",", encodeStringAttribute("initiated", string(abi.encodePacked("cycle.", Strings.toString(local.startBlock / 7200)))),
                                          ",", encodeStringAttribute("chroma", ChromaNames[chromaId]));
        }
        uint modelId = local.style & 7;
        return toJSON(string(abi.encodePacked("peer ", Strings.toString(peer), " - ", ModelDetails[modelId * 2])),
                      bytes(ModelDetails[modelId * 2 + 1]),
                      attributes,
                      assembleSVGURI(local.style & 7, chromaId, ts));
    }
}