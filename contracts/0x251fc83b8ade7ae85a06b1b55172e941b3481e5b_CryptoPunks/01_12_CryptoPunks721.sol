//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./strings.sol";

/**
*   ____                  _                          _ 
*  / ___|_ __ _   _ _ __ | |_ ___  _ __  _   _ _ __ | | _____
* | |   | '__| | | | '_ \| __/ _ \| '_ \| | | | '_ \| |/ / __|
* | |___| |  | |_| | |_) | || (_) | |_) | |_| | | | |   <\__ \
*  \____|_|   \__, | .__/ \__\___/| .__/ \__,_|_| |_|_|\_\___/
*             |___/|_|            |_|
*
* On-chain Cryptopunk images and attributes, by Larva Labs.
* Scam Alert : SoulBound CryptoPunks, Transfer Locked.
*/

interface CryptopunksData {
    function punkAttributes(uint16 index) external view returns (string memory text);
    function punkImageSvg(uint16 index) external view returns (string memory svg);
}

contract CryptoPunks is ERC721 {
    using Strings for uint256;
    using strings for *;
    using Address for address;

    string  private  SVG_HEADER = '<svg xmlns="http://www.w3.org/2000/svg" version="1.2" viewBox="0 0 24 24"><rect width="100%" height="100%" fill="#638596"/>';
    // You can use this hash to verify the image file containing all the punks
    string  public  imageHash = "ac39af4793119ee46bbff351d8cb6b5f23da60222126add4268e261199a2921b";
    string  private CryptoPunksDesc = "10,000 unique collectible characters with proof of ownership stored on the Ethereum blockchain.";
    address private punksData = 0x16F5A35647D6F03D5D3da7b35409D65ba03aF3B2;
    uint256 public  totalSupply;
    
        constructor() ERC721 ("CRYPTOPUNKS", unicode"Ͼ") {}

    function getPunk(uint256 punkIndex) external {
        require(punkIndex >= 0 && punkIndex < 10000 , "Out of punk");
        require(!_exists(punkIndex),"punkClimed");
        _mint(msg.sender , punkIndex);
        totalSupply++;
    }
  
    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal override(ERC721) {
        require(_from == address(0) , "Transfer Locked.");
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }       

    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }
    //from: Wiiides | 0x72A94e6c51CB06453B84c049Ce1E1312f7c05e2c & CryptoPunks: Data | 0x16F5A35647D6F03D5D3da7b35409D65ba03aF3B2
    function tokenURI(uint256 punkIndex) public view override returns (string memory) {
        require(_exists(punkIndex), "CryptoPunksMetadata: URI query for nonexistent punk");
        string memory punkSVG = CryptopunksData(punksData).punkImageSvg(uint16(punkIndex));
        strings.slice memory slicePunk = punkSVG.toSlice();            
        // cut the head off
        slicePunk.beyond('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" version="1.2" viewBox="0 0 24 24">'.toSlice());
        string[2] memory punkparts;
        punkparts[0] = SVG_HEADER;
        punkparts[1] = slicePunk.toString();
        string memory Svg = string.concat(punkparts[0], punkparts[1]);
        // get attributes which come in as a string like "Male 1, Smile, Mohawk"
        string memory attrs = CryptopunksData(punksData).punkAttributes(uint16(punkIndex));
        strings.slice memory sliceAttr = attrs.toSlice();            
        strings.slice memory delimAttr = ", ".toSlice();
        // break up that string into an array of independent values
        string[] memory attrParts = new string[](sliceAttr.count(delimAttr)+1); 
        for (uint i = 0; i < attrParts.length; i++) {                              
        attrParts[i] = sliceAttr.split(delimAttr).toString();                               
        }
        string memory Trait = string.concat('","attributes": [{"trait_type": "Type","value": "', attrParts[0] , '"}');
        // all the accessories
        for(uint256 i = 1; i < attrParts.length; i++){
        Trait = string.concat(Trait,',{"trait_type": "Accessory","value": "', attrParts[i], '"}');
        }
        // count the traits
        Trait = string.concat(Trait,',{"trait_type": "Attributes","value": "', Strings.toString(attrParts.length-1) , ' Attributes"}]');
        string memory CryptoPunksMetadata = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "CryptoPunk #', punkIndex.toString(),'","description": "', CryptoPunksDesc,'","created_by": "Larva Labs.","image": "data:image/svg+xml;base64,', 
                        Base64.encode(bytes(Svg)), Trait, '}'
                    )
                )
            )
        );
        return string(abi.encodePacked('data:application/json;base64,', CryptoPunksMetadata));
    }

}