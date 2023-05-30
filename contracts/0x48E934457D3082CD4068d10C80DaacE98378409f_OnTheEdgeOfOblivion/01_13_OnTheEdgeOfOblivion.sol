// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {OperatorFilterer} from "../OperatorFilterer.sol";

contract OnTheEdgeOfOblivion is ERC721A, OperatorFilterer, Ownable, ReentrancyGuard, ERC2981 {

    constructor() ERC721A("On the Edge of Oblivion", "EDGE") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _setDefaultRoyalty(msg.sender, 750);
        _safeMint(msg.sender, 1);
    }

    uint256 public price = 0.025 ether;
    uint256 public maxSupply = 555;

    bool public operatorFilteringEnabled;
    mapping(address => bool) internal w;
    address internal verifier;
    bytes32 internal root;
    uint256 internal mintPhase;

    string internal renderURI;
    bool internal isPreviewOnChain = true;
    


    /*//////////////////////////////////////////
    ___  ________ _   _ _____ _____ _   _ _____ 
    |  \/  |_   _| \ | |_   _|_   _| \ | |  __ \
    | .  . | | | |  \| | | |   | | |  \| | |  \/
    | |\/| | | | | . ` | | |   | | | . ` | | __ 
    | |  | |_| |_| |\  | | |  _| |_| |\  | |_\ \
    \_|  |_/\___/\_| \_/ \_/  \___/\_| \_/\____/

    /*//////////////////////////////////////////

    function publicMint(uint256 _amount, uint256 _phase, uint160 _hash, bytes32[] calldata _p) external payable nonReentrant checks() {

        bool validProof = MerkleProof.verify(_p, root, keccak256(abi.encodePacked(msg.sender, _amount, _phase)));
        if (mintPhase < 2) {
            require(validProof, "If phase is not 2, valid proof is required.");
            require(_phase == mintPhase, "Your phase must be equal to the current phase.");
        } else {
            require(_hash == requestHash(msg.sender), "Make sure you are minting on the website.");
        }
        uint256 qty = validProof ? _amount : 1;
        require(msg.value == price, "Please send the exact amount of Ether.");
        w[msg.sender] = true;
        _safeMint(msg.sender, qty);
        if (validProof) executeFreeMint(msg.sender, price);

    }



    /*///////////////////////////////////////////////      
    ______ ___________ _     _______   _____________ 
    |  _  \  ___| ___ \ |   |  _  \ \ / /  ___| ___ \
    | | | | |__ | |_/ / |   | | | |\ V /| |__ | |_/ /
    | | | |  __||  __/| |   | | | | \ / |  __||    / 
    | |/ /| |___| |   | |___\ \_/ / | | | |___| |\ \ 
    |___/ \____/\_|   \_____/\___/  \_/ \____/\_| \_|
                                                 
    /*///////////////////////////////////////////////                                                  

    function setVerifier(address _address) external onlyOwner {
        verifier = _address;
    }
    
    function changeMintPhase(uint256 _currentPhase) external onlyOwner {
        mintPhase = _currentPhase;
    }

    function changePreviewImage(bool _isPreviewOnChain, string memory _renderURI) external onlyOwner {
        renderURI = _renderURI;
        isPreviewOnChain = _isPreviewOnChain;
    }

    function editPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function editList(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function withdraw() public onlyOwner {
        uint256 b = address(this).balance;
        Address.sendValue(payable(owner()), b);
    }
    


    /*/////////////////////////////////////////////// 
    _____ _____ _   _ ___________  ___  _____ _____ 
    /  __ \  _  | \ | |_   _| ___ \/ _ \/  __ \_   _|
    | /  \/ | | |  \| | | | | |_/ / /_\ \ /  \/ | |  
    | |   | | | | . ` | | | |    /|  _  | |     | |  
    | \__/\ \_/ / |\  | | | | |\ \| | | | \__/\ | |  
    \____/\___/\_| \_/ \_/ \_| \_\_| |_/\____/ \_/  
                                             
    /*///////////////////////////////////////////////                                                          

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function getAttributes(uint256 _tokenId) internal view returns (uint256[3] memory) {
        return [
            nb(1, 10, "power", _tokenId),
            nb(1, 10, "eventHorizon", _tokenId),
            nb(1, 10, "radiation", _tokenId)
            ];
    }

    function nb(uint low, uint high, string memory n, uint256 t) internal view returns (uint) {
        uint d = high - low;
        uint rn = uint(keccak256(abi.encodePacked(n, t))) % d + 1;
        rn = rn + low;
        return rn;
    }

    modifier checks() {
        require(mintPhase > 0, "Mint is not live.");
        require(_totalMinted() + 1 <= maxSupply, "Max supply cap is 555 tokens.");
        require(!w[msg.sender], "One claim transaction per wallet.");
        require(msg.sender == tx.origin, "EOAs only");
        _;
    }

    function requestHash(address _addr) internal view returns (uint160) {
        return mintParameters(verifier).request(_addr);
    }

    function getCurrentPhase() external view returns (uint256) {
        return mintPhase;
    }

    function executeFreeMint(address _a, uint256 _r) internal {
        payable(_a).transfer(_r);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory html = string(abi.encodePacked(
            '<html> <head> <style> body { margin:0; background: #000; overflow: hidden; } canvas { bottom: 0; height: 100vw; left: 0; margin: auto; max-height: 100vh; max-width: 100vh; position: absolute; right: 0; top: 0; width: 100vw; } .text { color:white; position: absolute; top: 0; left: 0; font-family:Consolas; padding:2vw; font-size:1vw; } </style> </head> <body> <canvas id="canvas"></canvas> </body> </html> <script> var power = 19+2*',
            _toString(getAttributes(tokenId)[0]),
            ';var eventHorizon = ',
            _toString(getAttributes(tokenId)[1]),
            ';var radiation = 19 +3*',
            _toString(getAttributes(tokenId)[2]),
            ';function onTheEdgeOfOblivion(p,q,r){function j(a,b){return b=a,a=-2500/(1024/h),Math.floor(Math.random()*(b-a+1))+a;}var f=document.querySelector("canvas"),g=f.getContext("2d"),h=f.width=1250,n=f.height=1250,i=[],k=0,l=4000+p*1000;var c=document.createElement("canvas"),d=c.getContext("2d");c.width=1500,c.height=1500;var a=c.width/2;var e=d.createRadialGradient(a,a,0,a,a,a);e.addColorStop(0.1/100,"#fff"),e.addColorStop(0.5/100,"hsl(25, 60%, 15%)"),e.addColorStop(35/100,"hsl(25,65%,1%)"),e.addColorStop(0.9,"transparent"),d.fillStyle=e,d.beginPath(),d.arc(a,a,a,1,Math.PI*2),d.fill();var m=function(){this.oR=j(-h/(16-q)),this.radius=j(100,this.oR)/5,this.oX=h/2,this.oY=n/2,this.matter=j(0,l),this.paramZ=0.2/100*r+7.5/100,k++,i[k]=this;};m.prototype.draw=function(){var a=Math.sin(this.matter)*this.oR+this.oX,b=Math.cos(this.matter)*this.oR/1+this.oY;g.globalAlpha=this.paramZ,g.drawImage(c,a-this.radius/2,b-this.radius/2,this.radius,this.radius);};for(var b=0;b<l;b++)new m();for(var b=1,o=i.length;b<o;b++)g.globalCompositeOperation="lighter",i[b].draw();};onTheEdgeOfOblivion(power, eventHorizon, radiation);</script>'
        ));

        string memory thumbnail = (isPreviewOnChain) ? string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(bytes('<svg style="background-color:#000" preserveAspectRatio="xMinYMin meet" viewBox="0 0 750 750" xmlns="http://www.w3.org/2000/svg"> <filter id="b"> <feTurbulence baseFrequency="0.2"/> <feColorMatrix values="0 0 0 9 -5 0 0 0 9 -5 0 0 0 9 -5 0 0 0 0 1"/> </filter> <rect width="100%" height="100%" filter="url(#b)" opacity=".5"/> <circle cx="50%" cy="50%" r="20%"/> <defs xmlns="http://www.w3.org/2000/svg"> <filter id="a" x="0%" y="0%" xmlns="http://www.w3.org/2000/svg"> <feTurbulence baseFrequency="0.0005 1.5" numOctaves="10" result="turbulence" seed="4545"> <animate attributeName="seed" calcMode="discrete" dur="0.25s" repeatCount="indefinite" values="1;2;3;4;5;6;7;8;9;"/> </feTurbulence> <feDisplacementMap in="SourceGraphic" in2="turbulence" scale="50" xChannelSelector="R" yChannelSelector="G"/> </filter> </defs> <g id="1" filter="url(#a) blur(5px)" opacity="50%" xmlns="http://www.w3.org/2000/svg"> <g transform="translate(-10 -8)"> <circle id="c" cx="50%" cy="50%" r="16%" stroke="#fff"/> </g> </g> <g filter="url(#a) blur(5px)" opacity="50%" xmlns="http://www.w3.org/2000/svg"> <g transform="translate(-10 -8)"> <circle cx="50%" cy="50%" r="14%" stroke="#fff"/> </g> </g> <circle cx="50%" cy="50%" r="11%"/> <text x="50%" y="46%" dominant-baseline="middle" fill="white" font-family="Courier" font-size="30px" opacity=".6" text-anchor="middle">ON THE EDGE OF</text> <text x="50%" y="53%" dominant-baseline="middle" fill="white" font-family="Courier" font-size="75px" opacity=".6" text-anchor="middle">OBLIVION</text> </svg>')))) : string(abi.encodePacked(renderURI, _toString(tokenId)));
        
        string memory json = string(abi.encodePacked(
                '{"name": "On the Edge of Oblivion #',
                _toString(tokenId),
                '", "description": "Embark on a voyage to the outer realms of our universe, where the very fabric of space and time is distorted by an overwhelming force of gravity in ways we cannot yet comprehend.","attributes": [ { "trait_type": "Power", "value": "',
                _toString(getAttributes(tokenId)[0]),
                '" }, { "trait_type": "Event Horizon", "value": "',
                _toString(getAttributes(tokenId)[1]),
                '" }, { "trait_type": "Radiation", "value": "',
                _toString(getAttributes(tokenId)[2]),
                '" } ], "animation_url": "data:text/html;base64,',
                Base64.encode(bytes(html)),
                '",'
                '"image": "',
                thumbnail,
                '"}'
            ));
        return string(abi.encodePacked('data:application/json;base64,',Base64.encode(bytes(json))));
        
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

}

interface mintParameters {
    function request(address _addr) external view returns (uint160);
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