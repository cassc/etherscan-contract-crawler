// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Keisuke OHNO

/*

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

import { Base64 } from 'base64-sol/base64.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity >=0.7.0 <0.9.0;


interface iNFT {
    function balanceOf(address _address) external view returns (uint256);
    function name() external view returns (string memory);
}

interface iSBT {
    function ownerOf(uint256 _tokenId) external view returns (address);
}


contract SBTtokenURI is Ownable{

    string baseURI;
    string public baseExtension = ".json";
    string public baseImageExtension = ".png";
    iSBT public SBT;
    string public tokenName = "Your score is";
    string public tokenNameExtension = "!";
    uint256 public levelExp = 1000000;
    uint256 public maxImageNumber = 45;

    struct NFTCollection {
        iNFT NFTinterface;
        uint256 coefficient;
        string name;
        bool isVisible;
    }

    uint256 numberOfNFTCollections;
    mapping(uint256 => NFTCollection) public NFT;

    constructor(){
        setBaseURI("https://data.zqn.wtf/qnrank/images/");

        //main net
        SBT  = iSBT(0x3Af3A277b6F5ff2162669Df804fb8aeb2589F672);
        uint256 i = 1;
        setCollectionData( i++ , 0x3Af3A277b6F5ff2162669Df804fb8aeb2589F672 , 1 , "NFT Checker SBT" , true);
        setCollectionData( i++ , 0x79d43460f3CB215bB78a8761aca0C6808263b0d4 , 1 , "KareQN!" , true);
        setCollectionData( i++ , 0x891AA1C3964D3a83554E4D1108c5964cE5441a1a , 1 , "QN Passport Genesis" , true);
        setCollectionData( i++ , 0xA728453157BBf28177462AbFEa5E7db9d7D70774 , 1 , "QN" , true);
        setCollectionData( i++ , 0xB270Ab4B03dbf46c6697E600671Bd4917d6Ea0De , 1 , "ZQN! Phase Zero" , true);
        setCollectionData( i++ , 0xe62482263Ac31d229875dCb9E5CfdadD7627e495 , 1 , "SanuQN!" , true);
        setCollectionData( i++ , 0x845a007D9f283614f403A24E3eB3455f720559ca , 1 , "CryptoNinja Partners" , true);
        setCollectionData( i++ , 0xFE5A28F19934851695783a0C8CCb25d678bB05D3 , 1 , "CNP Jobs" , true);
        setCollectionData( i++ , 0x488D69DEA61D097158dCD5221d6792FAf1E6Ab4C , 1 , "Ninja Anniversary Girls" , true);
        setNumberOfNFTCollections(i-1);
/*
        //test
        SBT  = iSBT(0x4e566bAee00E799a884f35CCe06C7D806C024A7F);
        uint256 i = 1;
        setCollectionData( i++ , 0x4e566bAee00E799a884f35CCe06C7D806C024A7F , 1 , "CollectionA" , true);
        setCollectionData( i++ , 0x4e566bAee00E799a884f35CCe06C7D806C024A7F , 1 , "CollectionB" , true);
        setCollectionData( i++ , 0x4e566bAee00E799a884f35CCe06C7D806C024A7F , 1 , "CollectionC" , true);
        setCollectionData( i++ , 0x4e566bAee00E799a884f35CCe06C7D806C024A7F , 1 , "CollectionD" , true);
        setCollectionData( i++ , 0x4e566bAee00E799a884f35CCe06C7D806C024A7F , 1 , "CollectionE" , true);
        setCollectionData( i++ , 0x4e566bAee00E799a884f35CCe06C7D806C024A7F , 1 , "CollectionF" , true);
        setCollectionData( i++ , 0xB4aF0fb5484ff75409375536C24Ad93728A1541c , 1 , "CollectionG" , true);
        setCollectionData( i++ , 0xB4aF0fb5484ff75409375536C24Ad93728A1541c , 1 , "CollectionH" , true);
        setCollectionData( i++ , 0xB4aF0fb5484ff75409375536C24Ad93728A1541c , 1 , "CollectionI" , true);
        setCollectionData( i++ , 0xB4aF0fb5484ff75409375536C24Ad93728A1541c , 1 , "CollectionJ" , true);
        setCollectionData( i++ , 0xB4aF0fb5484ff75409375536C24Ad93728A1541c , 1 , "CollectionK" , true);
        setCollectionData( i++ , 0xB4aF0fb5484ff75409375536C24Ad93728A1541c , 1 , "CollectionL" , true);
        setCollectionData( i++ , 0xB4aF0fb5484ff75409375536C24Ad93728A1541c , 1 , "CollectionM" , true);
        setCollectionData( i++ , 0xB4aF0fb5484ff75409375536C24Ad93728A1541c , 1 , "CollectionN" , true);
        setCollectionData( i++ , 0xB4aF0fb5484ff75409375536C24Ad93728A1541c , 1 , "CollectionO" , true);
        setCollectionData( i++ , 0xB4aF0fb5484ff75409375536C24Ad93728A1541c , 1 , "CollectionP" , true);
        setCollectionData( i++ , 0xB4aF0fb5484ff75409375536C24Ad93728A1541c , 1 , "CollectionQ" , true);
        setCollectionData( i++ , 0xB4aF0fb5484ff75409375536C24Ad93728A1541c , 1 , "CollectionR" , true);
        setCollectionData( i++ , 0xB4aF0fb5484ff75409375536C24Ad93728A1541c , 1 , "CollectionS" , true);
        setCollectionData( i++ , 0xB4aF0fb5484ff75409375536C24Ad93728A1541c , 1 , "CollectionT" , true);
        setCollectionData( i++ , 0xB4aF0fb5484ff75409375536C24Ad93728A1541c , 1 , "CollectionU" , true);
        setCollectionData( i++ , 0xB4aF0fb5484ff75409375536C24Ad93728A1541c , 1 , "CollectionV" , true);
        setCollectionData( i++ , 0xB4aF0fb5484ff75409375536C24Ad93728A1541c , 1 , "CollectionW" , true);
        setCollectionData( i++ , 0xB4aF0fb5484ff75409375536C24Ad93728A1541c , 1 , "CollectionX" , true);
        setCollectionData( i++ , 0xB4aF0fb5484ff75409375536C24Ad93728A1541c , 1 , "CollectionY" , true);
        setCollectionData( i++ , 0xB4aF0fb5484ff75409375536C24Ad93728A1541c , 1 , "CollectionZ" , true);
        setCollectionData( i++ , 0xB4aF0fb5484ff75409375536C24Ad93728A1541c , 1 , "Collection1" , true);
        setCollectionData( i++ , 0xB4aF0fb5484ff75409375536C24Ad93728A1541c , 1 , "Collection2" , true);
        setCollectionData( i++ , 0xB4aF0fb5484ff75409375536C24Ad93728A1541c , 1 , "Collection3" , true);
        setCollectionData( i++ , 0xB4aF0fb5484ff75409375536C24Ad93728A1541c , 1 , "Collection4" , true);
        setCollectionData( i++ , 0xB4aF0fb5484ff75409375536C24Ad93728A1541c , 1 , "Collection5" , true);
        setCollectionData( i++ , 0xB4aF0fb5484ff75409375536C24Ad93728A1541c , 1 , "Collection6" , true);
        setCollectionData( i++ , 0xB4aF0fb5484ff75409375536C24Ad93728A1541c , 1 , "Collection7" , true);
        setCollectionData( i++ , 0xB4aF0fb5484ff75409375536C24Ad93728A1541c , 1 , "Collection8" , true);
        setCollectionData( i++ , 0xB4aF0fb5484ff75409375536C24Ad93728A1541c , 1 , "Collection9" , true);
        setNumberOfNFTCollections(i-1);
        */
    }


    function setSBT(address _address) public onlyOwner() {
        SBT = iSBT(_address);
    }

    function setNumberOfNFTCollections(uint256 _numberOfNFTCollections) public onlyOwner{
        numberOfNFTCollections = _numberOfNFTCollections;
    }

    function setCoefficient(uint256 _CollectionId , uint256 _coefficient) public onlyOwner{
        NFT[_CollectionId].coefficient = _coefficient;
    }
    
    function setIsVisible(uint256 _CollectionId , bool _isVisible) public onlyOwner{
        NFT[_CollectionId].isVisible = _isVisible;
    }

    function setCollectionData(uint256 _CollectionId , address _address , uint256 _coefficient , string memory _name , bool _isVisible) public onlyOwner{
        NFT[_CollectionId].NFTinterface = iNFT(_address);  
        NFT[_CollectionId].coefficient = _coefficient;
        NFT[_CollectionId].name = _name;
        NFT[_CollectionId].isVisible = _isVisible;
    }

    // internal
    function _baseURI() internal view returns (string memory) {
        return baseURI;        
    }

    //public
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return string( abi.encodePacked( 'data:application/json;base64,' , Base64.encode(bytes(encodePackedJson(tokenId))) ) );
    }

    function encodePackedJson(uint256 _tokenId) public view returns (bytes memory) {
        string memory name = _toString(calcPoint(_tokenId));
        string memory description = "If you do not need this token, please transfer it to 0x000000000000000000000000000000000000dEaD.";
        return abi.encodePacked(
            '{',
                '"name":"', tokenName , ' ' , name, ' ' , tokenNameExtension , '",' ,
                '"description":"', description, '",' ,
                '"image": "', _baseURI(), _toString(imageNumber(_tokenId)) , baseImageExtension , '",' ,
                '"attributes": [' ,
                        collectionDataOutput(_tokenId) ,
                ']',
            '}'
        );
    }

    function collectionDataOutput(uint256 _tokenId) public view returns(string memory){
        address ownerAddress = SBT.ownerOf(_tokenId);
        string memory outputStr;
        for(uint256 i = numberOfNFTCollections ; 1 <= i ; i--){
            if( NFT[i].isVisible == false){
                continue;
            }
            if( NFT[i].NFTinterface.balanceOf(SBT.ownerOf(_tokenId)) == 0){
                continue ;
            }
            outputStr = string(abi.encodePacked( outputStr , '{'));
            outputStr = string(abi.encodePacked( outputStr , '"trait_type": '));
            outputStr = string(abi.encodePacked( outputStr , '"'));
            outputStr = string(abi.encodePacked( outputStr , NFT[i].name ));
            outputStr = string(abi.encodePacked( outputStr , '"'));
            outputStr = string(abi.encodePacked( outputStr , ','));
            outputStr = string(abi.encodePacked( outputStr , '"value": '));
            outputStr = string(abi.encodePacked( outputStr , _toString(NFT[i].NFTinterface.balanceOf(ownerAddress))) );
            outputStr = string(abi.encodePacked( outputStr , '}'));
            if( 1 < i ){
                outputStr = string(abi.encodePacked( outputStr , ','));
            }
        }
        return outputStr;
    }

    function calcPoint(uint256 _tokenId)public view returns ( uint256 ){
        uint256 point = 0;
        for(uint256 i = 1 ; i <= numberOfNFTCollections ; i++){
            if( NFT[i].isVisible == false){
                continue;
            }
            point += NFT[i].NFTinterface.balanceOf(SBT.ownerOf(_tokenId)) * NFT[i].coefficient ;   
        }
        return point;
    }

    function imageNumber(uint256 _tokenId)public view returns ( uint256 ){
        uint256 number;
        number = (calcPoint(_tokenId) / levelExp) + 1;
        if( maxImageNumber < number ){
            number = maxImageNumber;
        }
        return number;
    }

    function setTokenName(string memory _tokenName) public onlyOwner {
        tokenName = _tokenName;
    }
    function setTokenNameExtension(string memory _tokenNameExtension) public onlyOwner {
        tokenNameExtension = _tokenNameExtension;
    }

    function setMaxImageNumber(uint256 _maxImageNumber) public onlyOwner {
        maxImageNumber = _maxImageNumber;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setLevelExp(uint256 _levelExp) public onlyOwner {
        levelExp = _levelExp;
    }

    function setBaseImageExtension(string memory _newBaseImageExtension) public onlyOwner {
        baseImageExtension = _newBaseImageExtension;
    }

    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 0x80 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 0x20 + 3 * 0x20 = 0x80.
            str := add(mload(0x40), 0x80)
            // Update the free memory pointer to allocate.
            mstore(0x40, str)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }


}