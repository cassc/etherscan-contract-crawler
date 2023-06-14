// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import {IAsyncToSync} from "./interfaces/IAsyncToSync.sol";
import {IRenderer} from "./interfaces/IRenderer.sol";
import {ICutUpGeneration} from "./interfaces/ICutUpGeneration.sol";

contract Renderer is IRenderer, Ownable {
    ICutUpGeneration public cutUpGenerator;
    string public baseImageUrl;
    string public imageUrlSuffix;
    string public baseAnimationUrl;
    string public animationUrlSuffix;
    string public description;
    string public baseExternalUrl;
    mapping(uint8 => string) public scripts;
    uint8 public scriptsLength;
    string public scriptUrl;
    string public externalScript;
    string public soundBaseUrl;
    bool public useOriginalAnimationUrl;

    constructor(address cutUpGeneratorAddress) {
        cutUpGenerator = ICutUpGeneration(cutUpGeneratorAddress);
    }

    function setCutUpGeneration(address cutUpGeneratorAddress) external onlyOwner {
        cutUpGenerator = ICutUpGeneration(cutUpGeneratorAddress);
    }

    function setImageUrl(string memory baseUrl, string memory suffix) external onlyOwner {
        baseImageUrl = baseUrl;
        imageUrlSuffix = suffix;
    }

    function setAnimationUrl(string memory baseUrl, string memory suffix) external onlyOwner {
        baseAnimationUrl = baseUrl;
        animationUrlSuffix = suffix;
    }

    function setDescription(string memory desc) external onlyOwner {
        description = desc;
    }

    function setBaseExternalUrl(string memory url) external onlyOwner {
        baseExternalUrl = url;
    }

    function setScriptsLength(uint8 length) external onlyOwner {
        scriptsLength = length;
    }

    function setScript(uint8 index, string memory script) external onlyOwner {
        scripts[index] = script;
    }

    function setScriptUrl(string memory url) external onlyOwner {
        scriptUrl = url;
    }

    function setExternalScript(string memory script) external onlyOwner {
        externalScript = script;
    }

    function setSoundBaseUrl(string memory url) external onlyOwner {
        soundBaseUrl = url;
    }

    function setUseOriginalAnimationUrl(bool useOrNot) external onlyOwner {
        useOriginalAnimationUrl = useOrNot;
    }

    function tokenURI(uint256 tokenId, IAsyncToSync.MusicParam memory musicParam) external view returns (string memory) {
        ICutUpGeneration.Messages memory messages = cutUpGenerator.cutUp(blockhash(block.number - 1));
        string memory originalAnimationUrl = getOriginalAnimationURL(tokenId, musicParam, messages);
        string memory animationUrl = useOriginalAnimationUrl ? originalAnimationUrl : getAnimationURL(tokenId);
        string memory json = string.concat(
            '{',
            '"name":"Async to Sync #', Strings.toString(tokenId), '",',
            '"description":"', description, '",',
            '"image":"', baseImageUrl, Strings.toString(tokenId), imageUrlSuffix, '",',
            '"original_animation_url":"', originalAnimationUrl, '",',
            '"animation_url":"', animationUrl, '",',
            '"external_url":"', baseExternalUrl, Strings.toString(tokenId), '",',
            '"attributes":', getAttributes(tokenId, musicParam, messages),
            '}'
        );
        return string.concat("data:application/json;utf8,", json);
    }

    function getAnimationURL(uint256 tokenId) private view returns (string memory) {
        return string.concat(baseAnimationUrl, Strings.toString(tokenId), animationUrlSuffix);
    }

    function getOriginalAnimationURL(uint256 tokenId, IAsyncToSync.MusicParam memory musicParam, ICutUpGeneration.Messages memory messages) private view returns (string memory) {
        string memory html = string.concat(
            "<html>",
            "<head>",
            '<meta name="viewport" width="device-width," initial-scale="1.0," maximum-scale="1.0," user-scalable="0" />',
            "<style>body { padding: 0; margin: 0; }</style>",
            externalScript,
            "\n<script>\n",
            embedVariable("A2S_TOKEN_ID", Strings.toString(tokenId)),
            embedVariable("A2S_RARITY", getRarity(musicParam.rarity)),
            embedVariable("A2S_RHYTHM", getRhythm(musicParam.rhythm)),
            embedVariable("A2S_OSCILLATOR", getOscillator(musicParam.oscillator)),
            embedVariable("A2S_ADSR", getADSR(musicParam.adsr)),
            embedVariable("A2S_LYRIC", getLyric(musicParam.lyric)),
            embedVariable("A2S_PARAM1", getRandomParam(1)),
            embedVariable("A2S_PARAM2", getRandomParam(2)),
            embedVariable("A2S_PARAM3", getRandomParam(3)),
            embedVariable("A2S_CU1", string.concat('"', messages.message1, '"')),
            embedVariable("A2S_CU2", string.concat('"', messages.message2, '"')),
            embedVariable("A2S_CU3", string.concat('"', messages.message3, '"')),
            embedVariable("A2S_CU4", string.concat('"', messages.message4, '"')),
            embedVariable("A2S_CU5", string.concat('"', messages.message5, '"')),
            embedVariable("A2S_CU6", string.concat('"', messages.message6, '"')),
            embedVariable("A2S_CU7", string.concat('"', messages.message7, '"')),
            embedVariable("A2S_CU8", string.concat('"', messages.message8, '"')),
            embedVariable("A2S_CU9", string.concat('"', messages.message9, '"')),
            embedVariable("A2S_CU10", string.concat('"', messages.message10, '"')),
            embedVariable("A2S_CU11", string.concat('"', messages.message11, '"')),
            embedVariable("A2S_CU12", string.concat('"', messages.message12, '"')),
            embedVariable("A2S_SOUND_BASE_URL", string.concat('"', soundBaseUrl, '"')),
            embedScripts(),
            "\n</script>\n",
            '<script src="', scriptUrl, '"></script>',
            "</head>",
            "<body>",
            "<main></main>",
            "</body>",
            "</html>"
        );
        return string.concat("data:text/html;charset=UTF-8;base64,", Base64.encode(bytes(html)));
    }

    function getAttributes(uint256 tokenId, IAsyncToSync.MusicParam memory musicParam, ICutUpGeneration.Messages memory messages) private view returns (string memory) {
        return string.concat(
            '[',
            '{"trait_type":"Rarity","value":"', getRarityName(musicParam.rarity), '"},',
            '{"trait_type":"Rhythm","value":"', getRhythmName(musicParam.rhythm), '"},',
            '{"trait_type":"Oscillator","value":"', getOscillatorName(musicParam.oscillator), '"},',
            '{"trait_type":"ADSR","value":"', getADSRName(musicParam.adsr), '"},',
            '{"trait_type":"Lyric","value":"', getLyricName(musicParam.lyric), '"},',
            '{"trait_type":"A2S_TOKEN_ID","value":', Strings.toString(tokenId), '},',
            '{"trait_type":"A2S_RARITY","value":', getRarity(musicParam.rarity), '},',
            '{"trait_type":"A2S_RHYTHM","value":', getRhythm(musicParam.rhythm), '},',
            '{"trait_type":"A2S_OSCILLATOR","value":', getOscillator(musicParam.oscillator), '},',
            '{"trait_type":"A2S_ADSR","value":', getADSR(musicParam.adsr), '},',
            '{"trait_type":"A2S_LYRIC","value":', getLyric(musicParam.lyric), '},',
            '{"trait_type":"A2S_PARAM1","value":', getRandomParam(1), '},',
            '{"trait_type":"A2S_PARAM2","value":', getRandomParam(2), '},',
            '{"trait_type":"A2S_PARAM3","value":', getRandomParam(3), '},',
            '{"trait_type":"A2S_CU1","value":"', messages.message1, '"},',
            '{"trait_type":"A2S_CU2","value":"', messages.message2, '"},',
            '{"trait_type":"A2S_CU3","value":"', messages.message3, '"},',
            '{"trait_type":"A2S_CU4","value":"', messages.message4, '"},',
            '{"trait_type":"A2S_CU5","value":"', messages.message5, '"},',
            '{"trait_type":"A2S_CU6","value":"', messages.message6, '"},',
            '{"trait_type":"A2S_CU7","value":"', messages.message7, '"},',
            '{"trait_type":"A2S_CU8","value":"', messages.message8, '"},',
            '{"trait_type":"A2S_CU9","value":"', messages.message9, '"},',
            '{"trait_type":"A2S_CU10","value":"', messages.message10, '"},',
            '{"trait_type":"A2S_CU11","value":"', messages.message11, '"},',
            '{"trait_type":"A2S_CU12","value":"', messages.message12, '"}',
            ']'
        );
    }

    function getRandomParam(uint8 seed) private view returns (string memory) {
        uint8 param = uint8(uint256(keccak256(abi.encode(seed, blockhash(block.number - 1)))) % 10);
        return Strings.toString(param);
    }

    function embedVariable(string memory name, string memory value) private pure returns (string memory) {
        return string.concat("var ", name, " = ", value, ";\n");
    }

    function embedScripts() private view returns (string memory) {
        string memory res = "";
        for (uint8 i = 0; i < scriptsLength; i++) {
            res = string.concat(res, scripts[i]);
        }
        return res;
    }

    function getRarity(IAsyncToSync.Rarity val) private pure returns (string memory) {
        if (val == IAsyncToSync.Rarity.Common) return '"COMMON"';
        if (val == IAsyncToSync.Rarity.Rare) return '"RARE"';
        if (val == IAsyncToSync.Rarity.SuperRare) return '"SUPER_RARE"';
        if (val == IAsyncToSync.Rarity.UltraRare) return '"ULTRA_RARE"';
        if (val == IAsyncToSync.Rarity.OneOfOne) return '"ONE_OF_ONE"';
        return '""';
    }

    function getRhythm(IAsyncToSync.Rhythm val) private pure returns (string memory) {
        if (val == IAsyncToSync.Rhythm.Thick) return '"THICK"';
        if (val == IAsyncToSync.Rhythm.LoFi) return '"LO_FI"';
        if (val == IAsyncToSync.Rhythm.HiFi) return '"HI_FI"';
        if (val == IAsyncToSync.Rhythm.Glitch) return '"GLITCH"';
        if (val == IAsyncToSync.Rhythm.Shuffle) return '"SHUFFLE"';
        return '""';
    }

    function getLyric(IAsyncToSync.Lyric val) private pure returns (string memory) {
        if (val == IAsyncToSync.Lyric.LittleGirl) return '"LITTLE_GIRL"';
        if (val == IAsyncToSync.Lyric.OldMan) return '"OLD_MAN"';
        if (val == IAsyncToSync.Lyric.FussyMan) return '"FUSSY_MAN"';
        if (val == IAsyncToSync.Lyric.LittleBoy) return '"LITTLE_BOY"';
        if (val == IAsyncToSync.Lyric.Shuffle) return '"SHUFFLE"';
        return '""';
    }

    function getOscillator(IAsyncToSync.Oscillator val) private pure returns (string memory) {
        if (val == IAsyncToSync.Oscillator.Lyra) return '"LYRA"';
        if (val == IAsyncToSync.Oscillator.Freak) return '"FREAK"';
        if (val == IAsyncToSync.Oscillator.LFO) return '"LFO"';
        if (val == IAsyncToSync.Oscillator.Glitch) return '"GLITCH"';
        if (val == IAsyncToSync.Oscillator.Shuffle) return '"SHUFFLE"';
        return '""';
    }

    function getADSR(IAsyncToSync.ADSR val) private pure returns (string memory) {
        if (val == IAsyncToSync.ADSR.Piano) return '"PIANO"';
        if (val == IAsyncToSync.ADSR.Pad) return '"PAD"';
        if (val == IAsyncToSync.ADSR.Pluck) return '"PLUCK"';
        if (val == IAsyncToSync.ADSR.Lead) return '"LEAD"';
        if (val == IAsyncToSync.ADSR.Shuffle) return '"SHUFFLE"';
        return '""';
    }

    function getRarityName(IAsyncToSync.Rarity val) private pure returns (string memory) {
        if (val == IAsyncToSync.Rarity.Common) return "Common";
        if (val == IAsyncToSync.Rarity.Rare) return "Rare";
        if (val == IAsyncToSync.Rarity.SuperRare) return "Super Rare";
        if (val == IAsyncToSync.Rarity.UltraRare) return "Ultra Rare";
        if (val == IAsyncToSync.Rarity.OneOfOne) return "1 of 1";
        return "";
    }

    function getRhythmName(IAsyncToSync.Rhythm val) private pure returns (string memory) {
        if (val == IAsyncToSync.Rhythm.Thick) return "Thick";
        if (val == IAsyncToSync.Rhythm.LoFi) return "Lo-Fi";
        if (val == IAsyncToSync.Rhythm.HiFi) return "Hi-Fi";
        if (val == IAsyncToSync.Rhythm.Glitch) return "Glitch";
        if (val == IAsyncToSync.Rhythm.Shuffle) return "(Shuffle)";
        return "";
    }

    function getLyricName(IAsyncToSync.Lyric val) private pure returns (string memory) {
        if (val == IAsyncToSync.Lyric.LittleGirl) return "Little girl";
        if (val == IAsyncToSync.Lyric.OldMan) return "Old man";
        if (val == IAsyncToSync.Lyric.FussyMan) return "Fussy man";
        if (val == IAsyncToSync.Lyric.LittleBoy) return "Little boy";
        if (val == IAsyncToSync.Lyric.Shuffle) return "(Shuffle)";
        return "";
    }

    function getOscillatorName(IAsyncToSync.Oscillator val) private pure returns (string memory) {
        if (val == IAsyncToSync.Oscillator.Lyra) return "Lyra";
        if (val == IAsyncToSync.Oscillator.Freak) return "Freak";
        if (val == IAsyncToSync.Oscillator.LFO) return "LFO";
        if (val == IAsyncToSync.Oscillator.Glitch) return "Glitch";
        if (val == IAsyncToSync.Oscillator.Shuffle) return "(Shuffle)";
        return "";
    }

    function getADSRName(IAsyncToSync.ADSR val) private pure returns (string memory) {
        if (val == IAsyncToSync.ADSR.Piano) return "Piano";
        if (val == IAsyncToSync.ADSR.Pad) return "Pad";
        if (val == IAsyncToSync.ADSR.Pluck) return "Pluck";
        if (val == IAsyncToSync.ADSR.Lead) return "Lead";
        if (val == IAsyncToSync.ADSR.Shuffle) return "(Shuffle)";
        return "";
    }
}