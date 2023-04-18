//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol"; 
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {OperatorFilterer} from "./OperatorFilterer.sol";

contract VocalGhost is ERC721A, OperatorFilterer, Ownable, ReentrancyGuard, ERC2981 {
    using Strings for uint256;
    bool public operatorFilteringEnabled;
    uint256 public newTokenId = 47; 
    uint256 public charSetCounter = 0;
    uint256 public cost = 0.005 ether;
    uint256 public maxSupply = 4147;
    bool private mintLive = false;
    bool private combineLive = false;
    bool private revealed = false;
    string public prerevealed = "?";
    uint256 private _maxCharacters = 11;
    mapping(uint256 => string) public _charactersTokenId; 
   


    constructor() ERC721A("Vocal Ghost", "VG") {
        _registerForOperatorFiltering();
         operatorFilteringEnabled = true;
        _setDefaultRoyalty(msg.sender, 690);
        _safeMint(msg.sender, 47); 

    }
    
    //--------------------------------Mint---------------------------------------
    function Mint(uint256 _amount) public payable {
        require(mintLive, "Mint Not Live Yet");
        require(msg.value >= cost * _amount, "Insufficient Funds");
        require(balanceOf(msg.sender) + _amount <= 11, "Max per wallet exceeded");
        uint256 supply = totalSupply();
        require(supply + _amount <= maxSupply, "Max supply exceeded!");
        _safeMint(msg.sender, _amount); 
        newTokenId += _amount;
    }

    //--------------------------------Combine---------------------------------------
    function Combine(uint256 tokenId1, uint256 tokenId2, string memory word) public {
        require(combineLive, "Combining tokens is not live yet");
        require(ownerOf(tokenId1) == msg.sender && ownerOf(tokenId2) == msg.sender, "Must own both tokens");
        string memory characters1 = _charactersTokenId[tokenId1];
        string memory characters2 = _charactersTokenId[tokenId2];
        string memory combined = string(abi.encodePacked(characters1, characters2));
        require(canCreate(combined, word), "The combined characters cannot form the given word");
        _burn(tokenId1);
        _burn(tokenId2);
        _safeMint(msg.sender, 1);
         newTokenId++;
        _charactersTokenId[newTokenId] = word;
    }

    function canCreate(string memory combined, string memory word) internal view returns (bool) {
        bytes memory lngth = bytes(combined);
        bytes memory wrd = bytes(word);
        uint256 length = lngth.length;
        uint256 wlength = wrd.length;
        
        if (length != wlength || wlength > _maxCharacters) {
             return false;
         }

        uint8[256] memory charCounts;
        for (uint i = 0; i < length; i++) {
            charCounts[uint8(lngth[i])] += 1;
         }

        for (uint i = 0; i < wlength; i++) {
            uint8 charCode = uint8(wrd[i]);
            if (charCounts[charCode] == 0) {
                 return false;
         }
            charCounts[charCode] -= 1;
        }

        return true;
    }

    //--------------------------------Uncombine------------------------
    function Uncombine(uint256 tokenId) public payable{
        require(combineLive, "Cannot uncombine pre Revealed Token");
        require(msg.value >= cost, "Insufficient Funds");
        require(ownerOf(tokenId) == msg.sender, "Must Own The Token");
        bytes memory characters = bytes(_charactersTokenId[tokenId]);
        require(characters.length >= 2, "Cannot uncombine single character");
        _burn(tokenId);
        for (uint i = 0; i < characters.length; i++) {
            bytes1 charb = characters[i];
            _safeMint(msg.sender, 1);
            newTokenId++;
            _charactersTokenId[newTokenId] = string(abi.encodePacked(charb)); 
        }
    }
    //--------------------------------TokenURI--------------------------------------
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        if(!revealed){
            return generateMetadata(prerevealed, tokenId);  
        } 
            return generateMetadata(_charactersTokenId[tokenId], tokenId);     
     }

   function generateMetadata(string memory characters, uint256 tokenId) internal view returns(string memory){
        bytes memory charBytes = bytes(characters);
        string memory attributes = "";
        for (uint i = 0; i < charBytes.length; i++) {
            attributes = string(abi.encodePacked(attributes, '{"trait_type":"', string(abi.encodePacked(charBytes[i])), '","value":"Yes"},'));
        }
        string memory svg = string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 700 700" fill="none"><rect width="700" height="700" fill="#0C0C0C"/><text x="50%" y="50%" text-anchor="middle" dominant-baseline="central" font-size="80" fill="', _colors[charBytes.length -1], '" font-family="helvetica" font-weight="500">', escapeAmpersand(characters), '</text></svg>'));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name":"#', tokenId.toString(), '","description":"A collection of on chain A11ographic tokens to be fused into words.","image":"data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '","attributes":[{"trait_type":"Word","value":"', characters, '"},', attributes, '{"trait_type":"Color","value":"', _colors[charBytes.length -1], '"}]}'))));
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function escapeAmpersand(string memory input) internal pure returns (string memory) {
        string memory output = "";
        uint256 inputLength = bytes(input).length;

        for (uint256 i = 0; i < inputLength; i++) {
            if (bytes(input)[i] == "&") {
                output = string(abi.encodePacked(output, "&amp;"));
            } else {
                output = string(abi.encodePacked(output, bytes(input)[i]));
            }
        }

        return output;
    }
 
    string[11] private _colors = ["#7F7F7F", "#727B84", "#5E8D96", "#A0B5BA", "#6A8174", "#8B997A", "#BAB37F", "#BF8A67", "#B27F8B", "#8888AA", "#BEBDF9"];
    
    //--------------------------------Owner Set Functions----------------------------------
    function setInitialMetadata(string[] memory _initialMetadata) public onlyOwner{
        require(!revealed, "Cannot set metadata once revealed");
        uint len = _initialMetadata.length;
        for (uint i= 1; i<=len; i++){
            _charactersTokenId[charSetCounter + i] = _initialMetadata[i-1];
        }
          charSetCounter = charSetCounter + len;
    }

    function resetcharSetCounter() public onlyOwner{
        charSetCounter = 0;
     }

     function setCombineLive(bool _bool) public onlyOwner{
         combineLive = _bool;
     }

     function setCost(uint256 _cost) public onlyOwner{
         cost = _cost;
     }

     function setMaxSupply(uint256 _supply) public onlyOwner{
         maxSupply = _supply;
     }

     function setMintLive(bool _bool) public onlyOwner{
         mintLive = _bool;
     }

     function setRevealed() public onlyOwner{
         revealed = true;
     }

     function setPreReveal(string memory _string) public onlyOwner{
         prerevealed = _string;
     }

     function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }
    //--------------------------------Operator Filterer-----------------------------------------
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

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }
    
    function _isPriorityOperator(address operator)
        internal
        pure
        override
        returns (bool)
    {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
     }
    
    //--------------------------------Royalty Functions--------------------------------------------
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
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
}