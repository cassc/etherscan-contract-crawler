// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
/**
* FMOMM -> Fork me or merge me////////////////////////
*/
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract FMOMM is  ERC721, ERC721Burnable, Ownable, ERC721Enumerable, ERC721URIStorage {
    
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    uint constant MAX = 10;

    struct Prop{
        string bg;
        string fg;
        string dur;

    }
    mapping(uint256 => Prop) props;
    constructor() ERC721("Fork me or merge me","FMOMM"){        
        props[0] = Prop("#fff","#000","30s");
        props[1] = Prop("#000","#fff","40s");
        props[2] = Prop("#fff","#000","50s");
        props[3] = Prop("#000","#fff","60s");
        props[4] = Prop("#fff","#000","70s");
        props[5] = Prop("#000","#fff","80s");
        props[6] = Prop("#fff","#000","90s");
        props[7] = Prop("#000","#fff","100s");
        props[8] = Prop("#fff","#000","110s");
        props[9] = Prop("#000","#fff","120s");
    }

    function generateSVG(uint256 tokenId) public view returns(string memory){
        uint256 id = tokenId-1;
        uint256 ss = tokenId * 5;
        bytes memory svg = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000" width="1000" height="1000" style="background: ',props[id].bg,'">',
                '<defs>',
                    '<filter id="disp">',
                        '<feTurbulence type="turbulence" baseFrequency="0.1 0.1" numOctaves="400" result="turbulence">',
                            '<animate attributeName="baseFrequency" values="0.1 0.1;0.01 0.01;0.1 0.1" dur="',props[id].dur,'" repeatCount="indefinite" />',
                        '</feTurbulence>',
                        '<feDisplacementMap in2="turbulence" in="SourceGraphic" scale="50" xChannelSelector="R" yChannelSelector="G">',
                            '<animate attributeName="scale" values="0;-120;0;120;0" dur="',props[id].dur,'" repeatCount="indefinite" />',
                        '</feDisplacementMap>',
                    '</filter>',
                '</defs>',
                '<circle cx="500" filter="url(#disp)" cy="500" r="300" stroke-width="',ss.toString(),'" stroke="',props[id].fg,'" fill="none" />',
            '</svg>'
        );
        return string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(svg)
            ));
    }

    function getTokenURI(uint256 tokenId) public view returns (string memory){
        bytes memory dataURI = abi.encodePacked(
            '{',
                '"name": "FMOMM #', tokenId.toString(), '",',
                '"description": "Fork me or merge me ', tokenId.toString(), '/10 - by Andres Senn (2022)",',
                '"image": "', generateSVG(tokenId), '"',
            '}'
        );
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }
    function mint() public onlyOwner{
        require(totalSupply()<MAX, "Full minted");  
        _tokenIdCounter.increment();      
         uint256 tokenId  = _tokenIdCounter.current();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, getTokenURI(tokenId));
    }
    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}