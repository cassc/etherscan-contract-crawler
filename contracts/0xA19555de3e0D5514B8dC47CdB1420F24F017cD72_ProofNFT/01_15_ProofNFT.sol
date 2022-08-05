// SPDX-License-Identifier: MIT
// Created by masataka.eth
pragma solidity ^0.8.6;

import { IAssetStore } from './interfaces/IAssetStore.sol';
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import { Base64 } from 'base64-sol/base64.sol';

contract ProofNFT is ERC721A("Proof NFT", "PFN") {
    using Strings for uint256;

    struct ProofInfo {
        string[] message;
        string blocknumber;
        address soulbound;
    }

    // external contract
    address AssetStoreContractAddress = 0x847A044aF5225f994C60f43e8cF74d20F756187C; //mainnet
    IAssetStore public immutable assetStore = IAssetStore(AssetStoreContractAddress);

    mapping(uint256 => ProofInfo) private proofs;
    uint256 private AssetIndex = 0;

    // description
    string constant description = "This is FullOnchain NFT with Soulbound.Your credentials.";

    function mint(string[] calldata _message) external {
       require(bytes(_message[0]).length > 0,"no message");
       ProofInfo storage proof = proofs[AssetIndex++];
       uint messageLength = _message.length;
       for(uint i =0;i < messageLength;i++){
            //nocheck,self-responsibility!
            proof.message.push(_message[i]);
       }
       proof.blocknumber = Strings.toString(block.number);
       proof.soulbound = msg.sender;

       _mint(msg.sender, 1);
    }

    // for SVG Generate
    string constant SVGHeader = '<svg viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">\n';
    string constant AddFill = '<use href="#asset101" fill="#FF0000"/>\n';
    string constant TextPart_F =  '<text x="100" y="';
    string constant TextPart_T =  '" font-family="Arial" font-size="100" font-weight="bold">';
    string constant TextPart_Hooter = '<text x="80" y="900" font-family="Arial" font-size="30" font-weight="bold" fill="#00008b">';
    string constant TextPart_End = '</text>\n';

    function generateSVG(ProofInfo memory assetinfo) public view returns (string memory) {
        bytes memory _svgPart = bytes(assetStore.generateSVGPart(101, "asset101")); // get Material Icons
        bytes memory _textPart = '';

        for(uint i =0;i < assetinfo.message.length;i++){
            assetinfo.message[i] = string(_sanitizeSvg( assetinfo.message[i]));
        }

        if(assetinfo.message.length == 1){
                _textPart = abi.encodePacked(  
                TextPart_F,'550',TextPart_T, assetinfo.message[0], TextPart_End
            );
        }else if(assetinfo.message.length == 2){
                _textPart = abi.encodePacked(  
                TextPart_F,'450',TextPart_T, assetinfo.message[0], TextPart_End,
                TextPart_F,'650',TextPart_T,  assetinfo.message[1], TextPart_End
            );
        }else{  // 3
                _textPart = abi.encodePacked(  
                TextPart_F,'350',TextPart_T, assetinfo.message[0], TextPart_End,
                TextPart_F,'550',TextPart_T, assetinfo.message[1], TextPart_End,
                TextPart_F,'750',TextPart_T, assetinfo.message[2], TextPart_End
            );
        }
        _textPart =  abi.encodePacked(_textPart,TextPart_Hooter, assetinfo.blocknumber, ' : ', assetinfo.soulbound ,TextPart_End);

        bytes memory image = abi.encodePacked(
        SVGHeader,
        _svgPart,
        AddFill,
        _textPart,
        '</svg>\n'
        );

        return string(image);
    }

    function _generateTraits(ProofInfo memory _attr) internal pure returns (bytes memory) {
        bytes memory writemessage = "";
        for(uint i =0;i < _attr.message.length;i++){
            writemessage = abi.encodePacked(writemessage,_attr.message[i],'');
        }
        writemessage = _sanitizeJson(string(writemessage));
        return abi.encodePacked(
            '{'
                '"trait_type":"message",'
                '"value":"', writemessage, '"' 
            '},{'
                '"trait_type":"blocknumber",'
                '"value":"', _attr.blocknumber, '"' 
            '},{'
                '"trait_type":"soulband",'
                '"value":"', _attr.soulbound, '"' 
            '}'
        );
    }

    function _sanitizeSvg(string memory _str) internal pure returns(bytes memory) {
        bytes memory src = bytes(_str);
        bytes memory res;
        uint i;
        for (i=0; i<src.length; i++) {
            uint8 b = uint8(src[i]);
            // Skip control codes, escape '<' '>' '#'
            if (b >= 0x20) {
                if  (b == 0x3c || b == 0x3e || b == 0x23) {
                    res = abi.encodePacked(res, '');
                }
                else{
                    res = abi.encodePacked(res, b);
                }    
            }
        }
        return res;
    }  

    function _sanitizeJson(string memory _str) internal pure returns(bytes memory) {
        bytes memory src = bytes(_str);
        bytes memory res;
        uint i;
        for (i=0; i<src.length; i++) {
            uint8 b = uint8(src[i]);
            // Skip control codes, escape backslash and double-quote
            if (b >= 0x20) {
                if  (b == 0x5c || b == 0x22) {
                    res = abi.encodePacked(res, '');
                }
                else{
                    res = abi.encodePacked(res, b);
                }    
            }
        }
        return res;
    }  

    function proofOfToken(uint256 _tokenId) public view returns(ProofInfo memory ) {
        require(_exists(_tokenId), 'proofOfToken: nonexistent token');
        return proofs[_tokenId];
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), 'tokenURI: nonexistent token');
        ProofInfo memory getproofinfo = proofOfToken(_tokenId);
        bytes memory image = bytes(generateSVG(getproofinfo));
        return string(
        abi.encodePacked(
            'data:application/json;base64,',
            Base64.encode(
            bytes(
                abi.encodePacked(
                '{"name":"', 'Proof NFT #',_tokenId.toString(), 
                    '","description":"', description, 
                    '","attributes":[', _generateTraits(getproofinfo), 
                    '],"image":"data:image/svg+xml;base64,', 
                    Base64.encode(image), 
                '"}')
            )
            )
        )
        );
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal pure override {
        // for SoulBand
        // mint-> OK
	    // transfer-> NG
        require(from == address(0),"this nft is the soulbound");
    }

}