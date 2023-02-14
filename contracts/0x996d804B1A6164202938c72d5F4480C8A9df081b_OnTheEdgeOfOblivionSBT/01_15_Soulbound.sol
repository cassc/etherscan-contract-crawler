// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract OnTheEdgeOfOblivionSBT is ERC721, ERC721Burnable, Ownable, ReentrancyGuard {

    
    /////////////////////////////////////////////////////////////////////////////////////////
    //// 
    ////    Relating to: Deployment Constructor (One-time)
    ////
    ////    - For token #1 which was burned in the V1 bridge.
    ////    - Timestamp set, inscription set, Ordinal number set and token minted.
    ////    - Transaction ID: 0x99da9669d3cca4649f7e8c7b9712ce36bd0e16e9ecc597052f0a7454320a74de
    ////
    /////////////////////////////////////////////////////////////////////////////////////////    
    
    constructor() ERC721("On the Edge of Oblivion SBT", "SOULBOUND") {
        bridgeTimestamps[1] = 1675822211;
        tokenIdToInscription[1] = "f0d35042249166706470873166f2617c639f0e3a06362600a43bf31b4921025ai0";
        tokenIdToOrdinalId[1] = 9978;
        _safeMint(msg.sender, 1);
    }


    /////////////////////////////////////////////////////////////////////////////////////////
    //// 
    ////    Relating to: Bridge Data
    ////
    ////    - If a EOA or a contract needs to fetch data about a burn, they can do so here.
    ////    - Deployer can open/close the bridge.
    ////    - Deployer can add a root for the merkle verification.
    ////
    /////////////////////////////////////////////////////////////////////////////////////////

    address public oblivionContract = 0x48E934457D3082CD4068d10C80DaacE98378409f;

    bytes32 public root = 0x3ee8659e6c5fc3c8c2d3c639960156126678b54edbedcb2d69efcf7087e5e2cf;
    function editRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    bool public bridgeOpen;
    function bridgeState(bool _open) external onlyOwner {
        bridgeOpen = _open;
    }

    mapping(uint256 => uint256) internal bridgeTimestamps;
    mapping(uint256 => uint256) internal tokenIdToOrdinalId;
    mapping(uint256 => string) internal tokenIdToInscription;
    mapping(uint256 => string) internal tokenIdToBitcoinAddress;

    function getBrigedTokenTimestampAndOrdinalId(uint256 _tokenId) public view returns (uint256) {
        return bridgeTimestamps[_tokenId];
    }

    function getBrigedTokenOrdinalId(uint256 _tokenId) public view returns (uint256) {
        return getTokenOrdinalNumber(_tokenId);
    }

    function getBrigedTokenInscription(uint256 _tokenId) public view returns (string memory) {
        return tokenIdToInscription[_tokenId];
    }

    function getBrigedTokenReceiverAddress(uint256 _tokenId) public view returns (string memory) {
        return tokenIdToBitcoinAddress[_tokenId];
    }


    /////////////////////////////////////////////////////////////////////////////////////////
    //// 
    ////    Relating to: Metadata Changes
    ////
    ////    - Ordinal standard devs mentioned some SATs a may be doubly inscribed.
    ////    - Inscription numbers above 500 may go up by a few numbers.
    ////    - This is to bump up or down the inscription number 
    ////    - Changing the same svg preview for a uri preview. Full code still on chain.
    ////
    /////////////////////////////////////////////////////////////////////////////////////////

    bool internal decrementMode;
    uint256 internal changeBy;
    function fixIdVariation(uint256 _changeBy, bool _decrementMode) external onlyOwner {
        changeBy = _changeBy;
        decrementMode = _decrementMode;
    }

    string internal renderURI;
    bool internal isPreviewOnChain = true;
    function changePreviewImage(bool _isPreviewOnChain, string memory _renderURI) external onlyOwner {
        renderURI = _renderURI;
        isPreviewOnChain = _isPreviewOnChain;
    }
    

    /////////////////////////////////////////////////////////////////////////////////////////
    //// 
    ////    Relating to: Bridging your On the Edge of Oblivion tokens to Bitcoin
    ////
    ////    - After setting everything, we emit an event to allow for burn tracking.
    ////
    /////////////////////////////////////////////////////////////////////////////////////////


    event bridgeEvent(uint256 indexed _tokenId, string indexed _btcAddress, uint256 _number, string _inscription);

    function bridgeToBitcoin(uint256 _tokenId, string memory _inscription, uint256 _ordinalId, string memory _btcAddress, bytes32[] calldata _p) external nonReentrant {
    
        bool validProof = MerkleProof.verify(_p, root, keccak256(abi.encodePacked(_tokenId, _inscription, _ordinalId)));
        require(validProof, "You must inscribe a valid combination of: token ID, inscription and ordinal number. This is verified by the merkle root.");
        require(bridgeOpen, "Bridge must be open.");
        require(IERC721(oblivionContract).ownerOf(_tokenId) == msg.sender, "Must own Oblivion to bridge to Bitcoin Ordinal state.");
        IERC721(oblivionContract).transferFrom(msg.sender, address(this), _tokenId);
        tokenIdToBitcoinAddress[_tokenId] = _btcAddress;
        bridgeTimestamps[_tokenId] = block.timestamp;
        tokenIdToInscription[_tokenId] = _inscription;
        tokenIdToOrdinalId[_tokenId] = _ordinalId;
        _safeMint(msg.sender, _tokenId);
        emit bridgeEvent(_tokenId, _btcAddress, _ordinalId, _inscription);

    }

    
    /////////////////////////////////////////////////////////////////////////////////////////
    //// 
    ////    Relating to: Future Burn Capabilities
    ////
    ////    We are allowing the burn of the soulbound token only if:
    ////    - The transaction caller is Nullish or the owner of the token.
    ////    - The transaction is coming from a Nullish project contract.
    ////
    /////////////////////////////////////////////////////////////////////////////////////////

    address internal nullishContract = 0x000000000000000000000000000000000000dEaD;
    function changeNullishContract(address _address) external onlyOwner {
        nullishContract = _address;
    }

    modifier onlyNullishProjects(uint256 _tokenId) {
        require(msg.sender == nullishContract);
        require(tx.origin == ownerOf(_tokenId) || tx.origin == owner());
        _;
    }

    function burnForOther(uint256 _tokenId) external onlyNullishProjects(_tokenId) {
        _burn(_tokenId);
    }


    /////////////////////////////////////////////////////////////////////////////////////////
    //// 
    ////    Relating to: Attributes
    ////
    ////    We are allowing the burn of the soulbound token only if:
    ////    - The transaction caller is Nullish or the owner of the token.
    ////    - The transaction is coming from a Nullish project contract.
    ////
    /////////////////////////////////////////////////////////////////////////////////////////                                                      

    function getAttributes(uint256 _tokenId) internal view returns (uint256[3] memory) {
        return [
            nb(1, 10, "power", _tokenId),
            nb(1, 10, "eventHorizon", _tokenId),
            nb(1, 10, "radiation", _tokenId)
            ];
    }

    function getTokenOrdinalNumber(uint256 _tokenId) internal view returns (uint256) {
        if (decrementMode) {
            return tokenIdToOrdinalId[_tokenId] - changeBy;
        } else {
            return tokenIdToOrdinalId[_tokenId] + changeBy;
        }
    }

    function nb(uint low, uint high, string memory n, uint256 t) internal view returns (uint) {
        uint d = high - low;
        uint rn = uint(keccak256(abi.encodePacked(n, t))) % d + 1;
        rn = rn + low;
        return rn;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {

        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory html = string(abi.encodePacked(
            '<html> <head> <style> body { margin:0; background: #000; overflow: hidden; } canvas { bottom: 0; height: 100vw; left: 0; margin: auto; max-height: 100vh; max-width: 100vh; position: absolute; right: 0; top: 0; width: 100vw; } .text { color:white; position: absolute; top: 0; left: 0; font-family:Courier; padding:2vw; font-size:1vw; } </style> </head> <body> <canvas id="canvas"></canvas> </body> </html> <script> var power = 19+2*',
            toString(getAttributes(tokenId)[0]),
            ';var eventHorizon = ',
            toString(getAttributes(tokenId)[1]),
            ';var radiation = 19 +3*',
            toString(getAttributes(tokenId)[2]),
            ';function onTheEdgeOfOblivion(p,q,r){function j(a,b){return b=a,a=-2500/(1024/h),Math.floor(Math.random()*(b-a+1))+a;}var f=document.querySelector("canvas"),g=f.getContext("2d"),h=f.width=1250,n=f.height=1250,i=[],k=0,l=4000+p*1000;var timeStamp = ',
            toString(bridgeTimestamps[tokenId]),
            '*1000,dateFormat = new Date(timeStamp),day = dateFormat.getDate(),daySuffixes = ["st", "nd", "rd", "th", "th", "th", "th", "th", "th", "th", "th", "th", "th", "th", "th","th","th","th","th","th","st","nd","rd","th","th","th","th","th","th","th","st"],month = dateFormat.getMonth(),monthNames = ["January", "February", "March", "April", "May", "June","July", "August", "September", "October", "November", "December"],year = dateFormat.getFullYear();g.font = "bold 24px Courier";g.fillStyle = "grey";g.textAlign = "start";g.fillText("Bridged on " + ((monthNames[dateFormat.getMonth()])+ " " + dateFormat.getDate() + daySuffixes[dateFormat.getDate() - 1] + ", " + dateFormat.getFullYear()), h*0.025, 0.025*n);g.fillText("',
            tokenIdToInscription[tokenId], //inscription
            '", h*0.025, 0.975*n);g.textAlign = "end";g.fillText("Soulbound Token", h*0.975, 0.025*n);g.fillText("#',
            toString(getTokenOrdinalNumber(tokenId)), //ordinal number
            '", h*0.975, 0.975*n);var c = document.createElement("canvas"), d = c.getContext("2d"); c.width = 1500, c.height = 1500; var a = c.width / 2; var e = d.createRadialGradient(a, a, 0, a, a, a); e.addColorStop(0.1 / 100, "#fff"), e.addColorStop(0.5 / 100, "hsl(25, 60%, 15%)"), e.addColorStop(35 / 100, "hsl(25,65%,1%)"), e.addColorStop(0.9, "transparent"), d.fillStyle = e, d.beginPath(), d.arc(a, a, a, 1, Math.PI * 2), d.fill(); var m = function() { this.oR = j(-h / (16 - q)), this.radius = j(100, this.oR) / 5, this.oX = h / 2, this.oY = n / 2, this.matter = j(0, l), this.paramZ = 0.2 / 100 * r + 7.5 / 100, k++, i[k] = this; }; m.prototype.draw = function() { var a = Math.sin(this.matter) * this.oR + this.oX, b = Math.cos(this.matter) * this.oR / 1 + this.oY; g.globalAlpha = this.paramZ, g.drawImage(c, a - this.radius / 2, b - this.radius / 2, this.radius, this.radius); }; for (var b = 0; b < l; b++) new m(); for (var b = 1, o = i.length; b < o; b++) g.globalCompositeOperation = "lighter", i[b].draw(); }; onTheEdgeOfOblivion(power, eventHorizon, radiation); </script>'
        ));

        string memory thumbnail = isPreviewOnChain ? string(abi.encodePacked('data:image/svg+xml;base64,PHN2ZyBzdHlsZT0iYmFja2dyb3VuZC1jb2xvcjojMDAwIiBwcmVzZXJ2ZUFzcGVjdFJhdGlvPSJ4TWluWU1pbiBtZWV0IiB2aWV3Qm94PSIwIDAgNzUwIDc1MCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4gPGZpbHRlciBpZD0iYiI+IDxmZVR1cmJ1bGVuY2UgYmFzZUZyZXF1ZW5jeT0iMC4yIi8+IDxmZUNvbG9yTWF0cml4IHZhbHVlcz0iMCAwIDAgOSAtNSAwIDAgMCA5IC01IDAgMCAwIDkgLTUgMCAwIDAgMCAxIi8+IDwvZmlsdGVyPiA8cmVjdCB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDAlIiBmaWx0ZXI9InVybCgjYikiIG9wYWNpdHk9Ii41Ii8+IDxjaXJjbGUgY3g9IjUwJSIgY3k9IjUwJSIgcj0iMjAlIi8+IDxkZWZzIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+IDxmaWx0ZXIgaWQ9ImEiIHg9IjAlIiB5PSIwJSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4gPGZlVHVyYnVsZW5jZSBiYXNlRnJlcXVlbmN5PSIwLjAwMDUgMS41IiBudW1PY3RhdmVzPSIxMCIgcmVzdWx0PSJ0dXJidWxlbmNlIiBzZWVkPSI0NTQ1Ij4gPGFuaW1hdGUgYXR0cmlidXRlTmFtZT0ic2VlZCIgY2FsY01vZGU9ImRpc2NyZXRlIiBkdXI9IjAuMjVzIiByZXBlYXRDb3VudD0iaW5kZWZpbml0ZSIgdmFsdWVzPSIxOzI7Mzs0OzU7Njs3Ozg7OTsiLz4gPC9mZVR1cmJ1bGVuY2U+IDxmZURpc3BsYWNlbWVudE1hcCBpbj0iU291cmNlR3JhcGhpYyIgaW4yPSJ0dXJidWxlbmNlIiBzY2FsZT0iNTAiIHhDaGFubmVsU2VsZWN0b3I9IlIiIHlDaGFubmVsU2VsZWN0b3I9IkciLz4gPC9maWx0ZXI+IDwvZGVmcz4gPGcgaWQ9IjEiIGZpbHRlcj0idXJsKCNhKSBibHVyKDVweCkiIG9wYWNpdHk9IjUwJSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4gPGcgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoLTEwIC04KSI+IDxjaXJjbGUgaWQ9ImMiIGN4PSI1MCUiIGN5PSI1MCUiIHI9IjE2JSIgc3Ryb2tlPSIjZmZmIi8+IDwvZz4gPC9nPiA8ZyBmaWx0ZXI9InVybCgjYSkgYmx1cig1cHgpIiBvcGFjaXR5PSI1MCUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+IDxnIHRyYW5zZm9ybT0idHJhbnNsYXRlKC0xMCAtOCkiPiA8Y2lyY2xlIGN4PSI1MCUiIGN5PSI1MCUiIHI9IjE0JSIgc3Ryb2tlPSIjZmZmIi8+IDwvZz4gPC9nPiA8Y2lyY2xlIGN4PSI1MCUiIGN5PSI1MCUiIHI9IjExJSIvPiA8dGV4dCB4PSI1MCUiIHk9IjQ2JSIgZG9taW5hbnQtYmFzZWxpbmU9Im1pZGRsZSIgZmlsbD0id2hpdGUiIGZvbnQtZmFtaWx5PSJDb3VyaWVyIiBmb250LXNpemU9IjMwcHgiIG9wYWNpdHk9Ii42IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIj5PTiBUSEUgRURHRSBPRjwvdGV4dD4gPHRleHQgeD0iNTAlIiB5PSI1MyUiIGRvbWluYW50LWJhc2VsaW5lPSJtaWRkbGUiIGZpbGw9IndoaXRlIiBmb250LWZhbWlseT0iQ291cmllciIgZm9udC1zaXplPSI3NXB4IiBvcGFjaXR5PSIuNiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+T0JMSVZJT048L3RleHQ+IDwvc3ZnPg==')) : string(abi.encodePacked(renderURI, toString(tokenId)));

        string memory json = string(abi.encodePacked(
                '{"name": "On the Edge of Oblivion #',
                toString(tokenId),
                ' (SBT)", "description": "Embark on a voyage to the outer realms of our universe, where the very fabric of space and time is distorted by an overwhelming force of gravity in ways we cannot yet comprehend.", "animation_url": "data:text/html;base64,',
                Base64.encode(bytes(html)),
                '",'
                '"image": "',
                thumbnail,
                '"}'
            ));
        return string(abi.encodePacked('data:application/json;base64,',Base64.encode(bytes(json))));
    
    }


    /////////////////////////////////////////////////////////////////////////////////////////
    //// 
    ////    Relating to: Soulbound Functionality
    ////
    ////    Approvals and transfers are disabled.
    ////    - No exceptions, except for burning as previously mentioned.
    ////
    /////////////////////////////////////////////////////////////////////////////////////////

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721)
    {
        revert("This token is soulbound.");
    }

    function approve(address operator, uint256 tokenId)
        public
        override(ERC721)
    {
        revert("This token is soulbound.");
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721)
    {
        revert("This token is soulbound.");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721)
    {
        revert("This token is soulbound.");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721)
    {
        revert("This token is soulbound.");
    }


    /////////////////////////////////////////////////////////////////////////////////////////
    //// 
    ////    Relating to: Conversion of uint256 variables to strings
    ////
    /////////////////////////////////////////////////////////////////////////////////////////

    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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


/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}