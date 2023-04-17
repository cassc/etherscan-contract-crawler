// SPDX-License-Identifier: MIT
// solhint-disable-next-line
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

// @author: Bård Ionson
// @website: bardIonson.com
// 
// We Are Anarchy On Chain
// We Are The Noise of Anarchy
// Inspired by Robness We Are Noise

contract AnarchyOnchain is ERC721, ERC721URIStorage, ERC721Burnable, ERC721Royalty, Ownable{
    using Counters for Counters.Counter;
    uint256 public mintPrice;
    uint8 public randomsUsed;
    uint8 public randomsLoaded;
    address public bard_address;
    uint8 public maxSupply = 250;
    mapping(uint256 => address) private mintedAddress;

    struct RandomArt {
        string[3] matrix;
        string noise;
        string path;
    }

    struct NumberParts {
        string[16] parts;
        uint[16] numParts;
    }

    mapping(uint256 => RandomArt) internal randomArts;

    Counters.Counter private _tokenIdCounter;
    constructor() ERC721("We Are Anarchy On Chain", "AOC")  {
        _setDefaultRoyalty(0x72774bc572ef9a2dFF47c3F8Cc200DC2fe3830C0,1000);
        mintPrice = 100000000000000000;
        setBard(msg.sender);
        mintedAddress[0]=msg.sender;
    }

    function changeRoyalty(address _address, uint96 _amount) public onlyOwner {
        _setDefaultRoyalty(_address, _amount);
    }

    function getMintedAddress(uint8 tokenId) public view returns (address){
        return mintedAddress[tokenId];
    }

    function setBard(address _new_bard_address) public  {
        if(msg.sender == bard_address || msg.sender == owner())
            bard_address = _new_bard_address;
    }

    function modM(uint8 _m) public onlyOwner {
        maxSupply = _m;
    }

    function setMintPrice(uint256 _newPrice) public onlyOwner {
        mintPrice = _newPrice;
    }
  
    function createRandomPub(uint[] memory _randomSeed)
        public {
            if (msg.sender == bard_address)
                createRandom(_randomSeed);
    }

    function createRandom(uint[] memory _randomSeed) internal onlyOwner  {
        NumberParts memory division;
        uint seed;
        for (uint256 i = 0; i < _randomSeed.length; ++i) {
            seed = _randomSeed[i];
            division = divide(seed);
            randomArts[randomsLoaded].noise = concatenate(division.parts);
            randomArts[randomsLoaded].matrix[0] = matrix(division.numParts[0]);
            randomArts[randomsLoaded].matrix[1] = matrix(division.numParts[1]);
            randomArts[randomsLoaded].matrix[2] = matrix(division.numParts[2]);
            randomArts[randomsLoaded].path = calcPath(seed);
            randomsLoaded++;
        }
    }

        /* Converts an SVG to Base64 string */
    function svgToImageURI(string memory svg)
        internal
        pure
        returns (string memory)
    {
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(bytes(svg));
        return string(abi.encodePacked(baseURL, svgBase64Encoded));
    }

    /* Generates a tokenURI using Base64 string as the image */
    function formatTokenURI(string memory imageURI, string memory artist)
        internal pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "We Are Anarchy On Chain", "description": "Noise of Anarchy" , "image":"',
                                imageURI,
                                '","attributes": [{"trait_type": "Artist","value":"',artist,'"},{"trait_type": "Type","value":"Noise of Anarchy"}]}'
                            )
                        )
                    )
                )
            );
    }
    
    function appendString(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e, string memory _f, string memory _g, string memory _h, string memory _i, string memory _j, string memory _k) internal pure returns (string memory)  {
        return string(abi.encodePacked(_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k));
    }

       // Fallback function is called when msg.data is not empty
    receive() external payable {
        require(msg.value >= mintPrice, "Not enough ETH sent; check price!");
        noiseMint(msg.sender);
    }

    fallback() external payable {
        require(msg.value >= mintPrice, "Not enough ETH sent; check price!");
        noiseMint(msg.sender);
    }

    function noiseMint(address _to) public payable {
        require(_tokenIdCounter.current() < maxSupply, "The noise is finished here.");
        require(msg.value >= mintPrice, "Not enough ETH sent; check price!");
        require(randomsUsed < randomsLoaded, "Mint is closed, Sorry.");
        RandomArt memory oneArt = randomArts[randomsUsed];
        randomsUsed++;
        
        string memory theFirstObj = appendString(unicode"<svg viewBox='0 0 4e3 2250' xmlns='http://www.w3.org/2000/svg'><filter id='static'><feTurbulence type='turbulence' baseFrequency='0.99' numOctaves='10' result='turbulence'><animate id='sd' attributeName='seed' dur='2s' values='", oneArt.noise,"' repeatCount='indefinite'/></feTurbulence><feColorMatrix type='saturate' values='1' result='saturate'/><feComponentTransfer><feFuncR id='r' type='discrete' tableValues='",oneArt.matrix[0],"'/><feFuncG id='g' type='discrete' tableValues='", oneArt.matrix[1],"'/><feFuncB id='b' type='discrete' tableValues='",oneArt.matrix[2],"'/><feFuncA type='discrete' tableValues='1 1'/></feComponentTransfer></filter><rect width='100%' height='100%' filter='url(#static)'/><path id='MP' fill='red' stroke='red' stroke-width='0' d='", oneArt.path ,"'/></svg>");
        string memory imageURI = svgToImageURI(theFirstObj);
        string memory uri = formatTokenURI(imageURI, "Bard Ionson");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, uri);

        mintedAddress[randomsUsed] = _to;
        payable(bard_address).transfer(msg.value);
    }

    function calcPath(uint256 endpoint) internal pure returns (string memory) {
        // Split the number into groups of 4 digits
        uint256[] memory groups = new uint256[](20);
        uint256 counter = 0;
        uint256 num = endpoint;
        while (num > 0) {
            groups[counter] = num % 10000;
            num = num / 10000;
            counter++;
        }
        
        // Scale down the coordinates to fit within an SVG viewport and round to the nearest integer
        uint256 scaleX = 4000;
        uint256 scaleY = 2250;
        uint256[] memory x = new uint256[](10);
        uint256[] memory y = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            x[i] = (groups[i] * scaleX) / 10000;
            y[i] = (groups[i+10] * scaleY) / 10000;
        }

        // Create an SVG path string that draws a line through the defined points
        string memory svgPath = string(abi.encodePacked("M", Strings.toString(x[0]), ",", Strings.toString(y[0])));
        for (uint256 i = 1; i < 10; i++) {
            svgPath = string(abi.encodePacked(svgPath, " L", Strings.toString(x[i]), ",", Strings.toString(y[i])));
        }
        return svgPath;
    }

 
    function divide(uint256 number) internal pure returns (NumberParts memory) {
        NumberParts memory division;
        for (uint i = 0; i < 16; i++) {
            uint theNum = number % 100000;
            division.parts[i] = Strings.toString(theNum);
            division.numParts[i] = theNum;
            number = number / 100000;
        }
        return division;
    }

    function concatenate(string[16] memory arr) internal pure returns (string memory) {
        string memory result = "";
        for (uint i = 0; i < arr.length-3; i++) {
            if (i==0) {
                result = arr[i];
            } else {
                result = string.concat(result, ";", arr[i]);
            }
        }
        return result;
    }


    function matrix(uint initial) internal pure returns (string memory) {
        string memory matrixVar;
        string memory a = Strings.toString((initial % 10)%2);
        string memory b = Strings.toString((initial % 100 / 10)%2);
        string memory c = Strings.toString((initial % 1000 / 100)%2);
        string memory d = Strings.toString((initial % 10000 / 1000)%2);
        string memory e = Strings.toString((initial % 100000 / 10000)%2);
        matrixVar = string(abi.encodePacked(a," ",b," ",c," ",d," ",e));
        return matrixVar;
    }
    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage, ERC721Royalty) {
        super._burn(tokenId);
    }

    function totalSupply() public view virtual returns (uint256) {
        return _tokenIdCounter.current();
    }
    
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(ERC721, ERC721Royalty) 
        returns(bool) 
        {
            return super.supportsInterface(interfaceId);
        }
        

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}