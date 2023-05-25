pragma solidity 0.8.13;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {RevokableDefaultOperatorFilterer} from "./RevokableDefaultOperatorFilterer.sol";
import {UpdatableOperatorFilterer} from "./UpdatableOperatorFilterer.sol";
import {Base64} from "./Base64.sol";

contract TheFlags is ERC721, Ownable, RevokableDefaultOperatorFilterer {
    string private constant SVG_HEADER = '<svg xmlns=\'http://www.w3.org/2000/svg\' version=\'1.2\' viewBox=\'0 0 32 32\' shape-rendering=\'crispEdges\'>';
    string private constant SVG_FOOTER = '</svg>';
    bytes16 private constant HEX_SYMBOLS = "0123456789abcdef";

    enum FormType { Default, Square, Nepal }
    enum BackgroundType { BgDefault, BgAdditional }
    enum StickType { StickDefault, StickAdditional }
    
    mapping(FormType => FormParameters) formsParameters;
    mapping(FormType => uint256[]) formsRowOffsets;
    mapping(BackgroundType => bytes3) backgroundColors;
    mapping(StickType => bytes3) stickColors;

    mapping(uint256 => bytes) private flags;
    mapping(uint256 => string) private names;

    bool isMediaLocked;

    struct FormParameters { uint256 startColumn; uint256 startRow; uint256 columnsCount; uint256 rowsCount; }
    struct decompressionParameters{
        FormType formType;
        BackgroundType bgType;
        StickType stickType;
        uint8 paletteLength;
        uint8 paletteIndexOffset;
        bytes1 repeatsMultiplier;
        bool isHorizontalCompression;
    }

    modifier checkIdExists(uint256 flagId){
        require(flagId != 0, "Flags idexes starts from 1");
        require(flagId <= 195, "There are only 195 flags");
        _;
    }

    modifier ifMediaNotLocked(){
        require(isMediaLocked == false, "All media is locked");
        _;
    }

    constructor() ERC721("TheFlags", "FLG") public {
        backgroundColors[BackgroundType.BgDefault] = hex"6AC3E6";
        backgroundColors[BackgroundType.BgAdditional] = hex"D4D4D4";
        stickColors[StickType.StickDefault] = hex"FFFFFF";
        stickColors[StickType.StickAdditional] = hex"EBEBEB";

        formsParameters[FormType.Default] = FormParameters(10, 10, 13, 9);
        formsParameters[FormType.Square] = FormParameters(11, 9, 10, 10);
        formsParameters[FormType.Nepal] = FormParameters(11, 9, 10, 10);

        formsRowOffsets[FormType.Default] = [ 0, 1, 2, 2, 2, 2, 1, 0, 0, 0, 0, 0, 1 ];
        formsRowOffsets[FormType.Square] = [ 0, 1, 2, 2, 2, 1, 0, 0, 0, 1 ];
        formsRowOffsets[FormType.Nepal] = [ 0, 1, 2, 2, 2, 2, 2, 2, 2, 2 ];

        isMediaLocked = false;
    }

    function safeMint(address to, uint256 flagId, string calldata name, bytes calldata flag)
        public
        onlyOwner
        checkIdExists(flagId)
    {
        flags[flagId] = flag;
        names[flagId] = name;
        _safeMint(to, flagId);
    }

    function updateFlag(uint flagId, bytes calldata flag) public onlyOwner ifMediaNotLocked checkIdExists(flagId) {
        flags[flagId] = flag;
    }

    function updateName(uint flagId, string calldata name) public onlyOwner ifMediaNotLocked checkIdExists(flagId) {
        names[flagId] = name;
    }

    function batchMint(address to, uint256[] calldata _tokenIds, string[] calldata _names, bytes[] calldata _flags) 
        public 
        onlyOwner 
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeMint(to, _tokenIds[i], _names[i], _flags[i]);
        }
    }

    function lockMedia() public onlyOwner {
        isMediaLocked = true;
    }

    function getMediaLockedStatus() public view returns (bool isLocked){
        isLocked = isMediaLocked;
    } 

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function owner() public view override(Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }

    function tokenURI(uint256 flagId) public view override(ERC721) checkIdExists(flagId) returns (string memory) {
        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{',
                    '"name": "', names[flagId], '",',
                    '"image_data": "', getFlagSvg(flagId), '"',
                    '}'
                )
            )));
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function getFlagSvg(uint256 flagId) public view checkIdExists(flagId) returns (string memory svg) {
        bytes memory data = flags[flagId];

        decompressionParameters memory params = getConfigurations(data[0]);

        svg = SVG_HEADER;
        svg = string(abi.encodePacked(svg, getSvgBlock(0, 0, 32, 32, backgroundColors[params.bgType])));
        svg = string(abi.encodePacked(svg, getSvgBlock(formsParameters[params.formType].startColumn, formsParameters[params.formType].startRow + 1, 1, 32 - (formsParameters[params.formType].startRow + 1), stickColors[params.stickType])));

        bytes3 color;
        uint256 interator = 0;
        for (uint8 colorDataIndex = 1 + params.paletteLength * 3; colorDataIndex < data.length; colorDataIndex++)
        {
            uint8 colorIndex = 1 + uint8(data[colorDataIndex] >> params.paletteIndexOffset) * 3;
            color = (bytes3(data[colorIndex])) | (bytes3(data[colorIndex + 1]) >> 8) | (bytes3(data[colorIndex + 2]) >> 16);

            for (uint8 repeat = 0; repeat < uint8(data[colorDataIndex] & params.repeatsMultiplier) + 1; repeat++)
            {
                (uint256 column, uint256 row) = getFormPixelByIterator(params, interator);
                interator++;
                svg = string(abi.encodePacked(svg, getSvgBlock(column, row, 1, 1, color)));
            }
        }
        
        svg = string(abi.encodePacked(svg, SVG_FOOTER));
    }

    function getFlagRaw(uint256 flagId) public view checkIdExists(flagId) returns (bytes memory raw){
        bytes memory data = flags[flagId];
        decompressionParameters memory params = getConfigurations(data[0]);

        raw = new bytes(3072);
        for (uint256 index = 0; index < 1024; index++){
            raw[index * 3] = backgroundColors[params.bgType][0];
            raw[index * 3 + 1] = backgroundColors[params.bgType][1];
            raw[index * 3 + 2] = backgroundColors[params.bgType][2];
        }

        for (uint256 row = formsParameters[params.formType].startRow + formsParameters[params.formType].rowsCount; row < 32; row++){
            uint256 index = row * 32 + formsParameters[params.formType].startColumn;
            raw[index * 3] = stickColors[params.stickType][0];
            raw[index * 3 + 1] = stickColors[params.stickType][1];
            raw[index * 3 + 2] = stickColors[params.stickType][2];
        }

        uint256 interator = 0;
        for (uint8 colorDataIndex = 1 + params.paletteLength * 3; colorDataIndex < data.length; colorDataIndex++)
        {
            uint8 colorIndex = 1 + uint8(data[colorDataIndex] >> params.paletteIndexOffset) * 3;
            for (uint8 repeat = 0; repeat < uint8(data[colorDataIndex] & params.repeatsMultiplier) + 1; repeat++)
            {
                (uint256 column, uint256 row) = getFormPixelByIterator(params, interator);
                interator++;
                uint256 index = (row * 32 + column) * 3;
                raw[index] = data[colorIndex];
                raw[index + 1] = data[colorIndex + 1];
                raw[index + 2] = data[colorIndex + 2];
            }
        }
    }

    function getConfigurations(bytes1 config) private view returns (decompressionParameters memory params){
        uint8 configByte = uint8(config);
        uint8 formIndex = (configByte >> 6) & 0x3;
        bool isHorizontalCompression = (configByte >> 5) & 0x1 == 0;
        uint8 bgIndex = (configByte >> 4) & 0x1;
        uint8 stickIndex = (configByte >> 3) & 0x1;
        uint8 paletteLength = (configByte & 0x7) + 1;
        uint8 paletteIndexOffset = paletteLength <= 2 ? 7 : paletteLength <= 4 ? 6 : 5;
        bytes1 repeatsMultiplier = paletteLength <= 2 ? bytes1(0x7F) : paletteLength <= 4 ? bytes1(0x3F) : bytes1(0x1F);

        params = decompressionParameters(
            FormType(formIndex),
            BackgroundType(bgIndex),
            StickType(stickIndex),
            paletteLength,
            paletteIndexOffset,
            repeatsMultiplier,
            isHorizontalCompression
        );
    }

    function getFormPixelByIterator(
        decompressionParameters memory params,
        uint256 iterator
        ) private view returns (uint256 column, uint256 row) {
        uint256 columnIndex = 0;
        uint256 rowIndex = 0;

        if (params.isHorizontalCompression) {
            columnIndex = iterator % formsParameters[params.formType].columnsCount;
            rowIndex = iterator / formsParameters[params.formType].columnsCount;
        } else {
            columnIndex = iterator / formsParameters[params.formType].rowsCount;
            rowIndex = iterator % formsParameters[params.formType].rowsCount;
        }

        column = formsParameters[params.formType].startColumn + columnIndex;
        row = formsParameters[params.formType].startRow + rowIndex + formsRowOffsets[params.formType][columnIndex];
    }

    function getSvgBlock(uint256 x, uint256 y, uint256 xSize, uint256 ySize, bytes3 color) private pure returns (string memory) {
        bytes memory buffer = new bytes(6);
        for (uint256 i = 0; i < 3; i++) {
            uint8 value = uint8(color[i]);
            buffer[i * 2 + 1] = HEX_SYMBOLS[value & 0xf];
            value >>= 4;
            buffer[i * 2] = HEX_SYMBOLS[value & 0xf];
        }

        return string(abi.encodePacked(
                        '<rect x=\'', toString(x), '\' y=\'', toString(y),'\' width=\'', toString(xSize), '\' height=\'', toString(ySize) ,'\' fill=\'#', string(buffer),'\'/>'));
    }

    function toString(uint256 value) private pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}