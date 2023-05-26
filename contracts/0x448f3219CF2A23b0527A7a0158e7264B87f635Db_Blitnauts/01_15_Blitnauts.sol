//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


interface BlitmapContract is IERC721 {
    function tokenSvgDataOf(uint256 tokenId) external view returns (string memory);
}

contract Blitnauts is ERC721Enumerable, ReentrancyGuard, Ownable {

    BlitmapContract private blitmapContract;
    address private blitmapContractAddress;

    struct BlitmapPosition {
        uint16 x;
        uint16 y;
        uint16 width;
        uint16 height;
    }

    struct BlitnautFrameData {
        string svgTxHash;
        string rasterTxHash;
        string name;
        uint8 numColors;
        BlitmapPosition position;
    }

    struct BlitnautInstanceData {
        uint256 frameId;
        uint256 blitmapId;
        uint256 instanceId;
        uint8[] colors;
        uint8 backgroundColor;
    }

    BlitnautFrameData[] private blitnautFrames;
    BlitnautInstanceData[] private blitnautInstances;
    mapping (uint256 => bool) private blitmapRedemptions;
    mapping (bytes32 => bool) private craftHashes;
    mapping (uint256 => uint256) public instanceCount;
    string private _uriPrefix;

    string[64] public palette = [
        "#ff0040",
        "#131313",
        "#1b1b1b",
        "#272727",
        "#3d3d3d",
        "#5d5d5d",
        "#858585",
        "#b4b4b4",
        "#ffffff",
        "#c7cfdd",
        "#92a1b9",
        "#657392",
        "#424c6e",
        "#2a2f4e",
        "#1a1932",
        "#0e071b",
        "#1c121c",
        "#391f21",
        "#5d2c28",
        "#8a4836",
        "#bf6f4a",
        "#e69c69",
        "#f6ca9f",
        "#f9e6cf",
        "#edab50",
        "#e07438",
        "#c64524",
        "#8e251d",
        "#ff5000",
        "#ed7614",
        "#ffa214",
        "#ffc825",
        "#ffeb57",
        "#d3fc7e",
        "#99e65f",
        "#5ac54f",
        "#33984b",
        "#1e6f50",
        "#134c4c",
        "#0c2e44",
        "#00396d",
        "#0069aa",
        "#0098dc",
        "#00cdf9",
        "#0cf1ff",
        "#94fdff",
        "#fdd2ed",
        "#f389f5",
        "#db3ffd",
        "#7a09fa",
        "#3003d9",
        "#0c0293",
        "#03193f",
        "#3b1443",
        "#622461",
        "#93388f",
        "#ca52c9",
        "#c85086",
        "#f68187",
        "#f5555d",
        "#ea323c",
        "#c42430",
        "#891e2b",
        "#571c27"
    ];

    string public compileScript = 'function hexToBytes(e){for(var o=[],r=2;r<e.length;r+=2)o.push(parseInt(e.substr(r,2),16));return o}function bufferToBase64(e){for(var o="",r=new Uint8Array(e),t=r.byteLength,n=0;n<t;n++)o+=String.fromCharCode(r[n]);return window.btoa(o)}var colorSlots={};function draw(){const e=hexToBytes(svgData),o=String.fromCharCode.apply(null,e),r=document.createElement("div");r.innerHTML=o,document.body.appendChild(r);const t=document.querySelector("div svg").querySelectorAll("g");for([s,c]of t.entries()){var n=c.attributes.fill.value;null==colorSlots[n]&&(colorSlots[n]=[]),colorSlots[n].push(c)}var a=hexToBytes(rasterData),l=new Image(1500,1500);for(var[s,u]of(l.src="data:image/png;base64,"+bufferToBase64(a),document.body.appendChild(l),Object.keys(colorSlots).entries()))for(var c of colorSlots[u])c.attributes.fill.value=colors[s%colors.length]}document.addEventListener("DOMContentLoaded",draw);';

    bool public mintingActive = false;

    constructor(address _blitmapContractAddress) ERC721("The Blitnauts", "NAUT") Ownable() {
        blitmapContractAddress = _blitmapContractAddress;
        blitmapContract = BlitmapContract(blitmapContractAddress);

        setBaseURI("https://blitnauts.blitmap.com/api/v1/metadata/");
    }

    function toggleActive() public onlyOwner {
        mintingActive = !mintingActive;
    }

    function _baseURI() override internal view virtual returns (string memory) {
        return _uriPrefix;
    }

    function setBaseURI(string memory prefix) public onlyOwner {
        _uriPrefix = prefix;
    }

    function ownerOfBlitmap(uint256 tokenId) public view returns (address) {
        return blitmapContract.ownerOf(tokenId);
    }

    function unredeemedBlitmaps(uint256[] memory blitmapIds) public view returns (uint256[128] memory unredeemedIds, uint8 length) {
        uint256[128] memory ids;
        uint8 cursor;
        for (uint i = 0; i < blitmapIds.length; ++i) {
            if (blitmapRedemptions[blitmapIds[i]] == false) {
                ids[cursor] = blitmapIds[i];
                ++cursor;
            }
        }
        return (ids, cursor);
    }

    function permutationIsAvailable(uint16 frameId, uint8[] memory colors) public view returns (bool isAvailable) {
        require(frameId < blitnautFrames.length, "Frame ID invalid");
        require(colors.length == blitnautFrames[frameId].numColors, "Number of colors doesn't match");
        for (uint8 i = 0; i < colors.length; ++i) {
            colors[i] = colors[i] % 64;
        }

        bytes32 craftHash = keccak256(abi.encodePacked(frameId, colors));
        return !craftHashes[craftHash];
    }

    function mintInstance(uint256 blitmapId, uint16 frameId, uint8[] memory colors, uint8 backgroundColor) public nonReentrant {
        require(mintingActive, "Minting is not currently active");
        require(frameId < blitnautFrames.length, "Frame ID invalid");
        require(_msgSender() == ownerOfBlitmap(blitmapId), "Blitmap not owned");
        require(blitmapRedemptions[blitmapId] == false, "Blitmap already redeemed");
        require(colors.length == blitnautFrames[frameId].numColors, "Number of colors doesn't match");

        backgroundColor = backgroundColor % 64;
        for (uint8 i = 0; i < colors.length; ++i) {
            colors[i] = colors[i] % 64;
        }

        bytes32 craftHash = keccak256(abi.encodePacked(frameId, colors));
        require(craftHashes[craftHash] == false, "Frame/color combo already crafted");

        uint256 tokenId = totalSupply();

        BlitnautInstanceData memory data;
        data.blitmapId = blitmapId;
        data.frameId = frameId;
        data.colors = colors;
        data.backgroundColor = backgroundColor;
        data.instanceId = instanceCount[frameId];
        blitmapRedemptions[blitmapId] = true;
        blitnautInstances.push(data);
        instanceCount[frameId]++;
        craftHashes[craftHash] = true;
        _safeMint(_msgSender(), tokenId);
    }

    function uploadSvgData(bytes calldata svgData) public onlyOwner {
        // do nothing and store data
    }

    function uploadRasterData(bytes calldata rasterData) public onlyOwner {
        // do nothing and store data
    }

    function registerFrameData(string memory svgTxHash, string memory rasterTxHash, string memory name, uint8 numColors, uint16 x, uint16 y, uint16 width, uint16 height) public onlyOwner {
        BlitmapPosition memory position;
        position.x = x;
        position.y = y;
        position.width = width;
        position.height = height;

        BlitnautFrameData memory frameData;
        frameData.svgTxHash = svgTxHash;
        frameData.rasterTxHash = rasterTxHash;
        frameData.name = name;
        frameData.numColors = numColors;
        frameData.position = position;
        blitnautFrames.push(frameData);
    }

    function frameDataFor(uint256 index) public view returns (BlitnautFrameData memory) {
        return blitnautFrames[index];
    }

    function instanceDataFor(uint256 tokenId) public view returns (BlitnautInstanceData memory) {
        return blitnautInstances[tokenId];
    }

    function nameForFrameAndInstance(uint256 frameId, uint256 instanceId) public view returns (string memory) {
        BlitnautFrameData memory frameData = blitnautFrames[frameId];

        string[24] memory alphabet = [
            "Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta",
            "Eta", "Etheta", "Iota", "Kappa", "Lambda", "Mu",
            "Nu", "Xi", "Omicron", "Pi", "Rho", "Sigma",
            "Tau", "Upsilon", "Phi", "Chi", "Psi", "Omega"
        ];
        string[10] memory numbers = [
            "I", "II", "III", "IV", "V",
            "VI", "VII", "VIII", "IX", "X"
        ];

        string[5] memory stringParts;

        stringParts[0] = frameData.name;
        stringParts[1] = " ";
        stringParts[2] = alphabet[instanceId % 24];
        if (instanceId >= 24) {
            stringParts[3] = " ";
            stringParts[4] = numbers[instanceId / 24];
        }

        return string(abi.encodePacked(stringParts[0], stringParts[1], stringParts[2], stringParts[3], stringParts[4]));
    }

    function nameFor(uint256 tokenId) public view returns (string memory) {
        BlitnautInstanceData memory instanceData = blitnautInstances[tokenId];
        return nameForFrameAndInstance(instanceData.frameId, instanceData.instanceId);
    }

    function templateScriptFor(uint256 tokenId) public view returns (string memory) {
        BlitnautInstanceData memory instanceData = blitnautInstances[tokenId];
        BlitnautFrameData memory frameData = blitnautFrames[instanceData.frameId];

        string memory colors;

        for (uint8 i = 0; i < frameData.numColors; ++i) {
            if (i == 0) {
                colors = string(abi.encodePacked('"', palette[instanceData.colors[i]], '"'));
            } else {
                colors = string(abi.encodePacked(colors, ', "', palette[instanceData.colors[i]], '"'));
            }
        }

        string memory css = string(abi.encodePacked("<style>*{margin: 0;}body{background: ",  palette[instanceData.backgroundColor],"80;}img, svg{position: absolute; top: 0; left: 0;}img.blitmap, svg{top:",
            uint2str(frameData.position.y), "px; left:",
            uint2str(frameData.position.x), "px; width:",
            uint2str(frameData.position.width), "px; height:",
            uint2str(frameData.position.height), "px; z-index: -1;}div svg{top: 0; left: 0; width: 1500px; height: 1500px;}</style>\n\n"));

        return string(abi.encodePacked("<script>\n// grab data[0] from ethereum transaction\n// ", frameData.rasterTxHash, "\n// and put it here as a string\nvar rasterData = '';\n\n// then grab data[0] from ethereum transaction\n// ", frameData.svgTxHash, "\n// and put it here as a string\nvar svgData = '';\n\n// then save to a .html file and open in a browser of your choice.\n\nvar colors = [", colors, "];\n\n", compileScript, "\n</script>\n\n", css, blitmapContract.tokenSvgDataOf(instanceData.blitmapId)));
    }

    // via https://stackoverflow.com/a/65707309/424107
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}