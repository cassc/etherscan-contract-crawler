// SPDX-License-Identifier: MIT
// base64.tech
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Errors.sol";

/*

   ▄████████  ▄█        ▄██████▄     ▄████████     ███      ▄█  ███▄▄▄▄      ▄██████▄        ▄████████  ▄█      ███     ▄██   ▄   
  ███    ███ ███       ███    ███   ███    ███ ▀█████████▄ ███  ███▀▀▀██▄   ███    ███      ███    ███ ███  ▀█████████▄ ███   ██▄ 
  ███    █▀  ███       ███    ███   ███    ███    ▀███▀▀██ ███▌ ███   ███   ███    █▀       ███    █▀  ███▌    ▀███▀▀██ ███▄▄▄███ 
 ▄███▄▄▄     ███       ███    ███   ███    ███     ███   ▀ ███▌ ███   ███  ▄███             ███        ███▌     ███   ▀ ▀▀▀▀▀▀███ 
▀▀███▀▀▀     ███       ███    ███ ▀███████████     ███     ███▌ ███   ███ ▀▀███ ████▄       ███        ███▌     ███     ▄██   ███ 
  ███        ███       ███    ███   ███    ███     ███     ███  ███   ███   ███    ███      ███    █▄  ███      ███     ███   ███ 
  ███        ███▌    ▄ ███    ███   ███    ███     ███     ███  ███   ███   ███    ███      ███    ███ ███      ███     ███   ███ 
  ███        █████▄▄██  ▀██████▀    ███    █▀     ▄████▀   █▀    ▀█   █▀    ████████▀       ████████▀  █▀      ▄████▀    ▀█████▀  
             ▀                                                                                                                    
   ▄▄▄▄███▄▄▄▄      ▄████████     ███        ▄████████ ████████▄     ▄████████     ███        ▄████████                           
 ▄██▀▀▀███▀▀▀██▄   ███    ███ ▀█████████▄   ███    ███ ███   ▀███   ███    ███ ▀█████████▄   ███    ███                           
 ███   ███   ███   ███    █▀     ▀███▀▀██   ███    ███ ███    ███   ███    ███    ▀███▀▀██   ███    ███                           
 ███   ███   ███  ▄███▄▄▄         ███   ▀   ███    ███ ███    ███   ███    ███     ███   ▀   ███    ███                           
 ███   ███   ███ ▀▀███▀▀▀         ███     ▀███████████ ███    ███ ▀███████████     ███     ▀███████████                           
 ███   ███   ███   ███    █▄      ███       ███    ███ ███    ███   ███    ███     ███       ███    ███                           
 ███   ███   ███   ███    ███     ███       ███    ███ ███   ▄███   ███    ███     ███       ███    ███                           
  ▀█   ███   █▀    ██████████    ▄████▀     ███    █▀  ████████▀    ███    █▀     ▄████▀     ███    █▀                            
                                                                                                                                  

*/
contract FloatingCityMetadata is Ownable
{
    using Strings for uint256;
    string private _baseTokenURI;

    constructor() 
    {}

    function getBaseURI() external view returns(string memory) {
       return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getMetadata(uint256 tokenId) external view returns (string memory) {
        string memory baseURI = _baseTokenURI;
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : '';
    }

}