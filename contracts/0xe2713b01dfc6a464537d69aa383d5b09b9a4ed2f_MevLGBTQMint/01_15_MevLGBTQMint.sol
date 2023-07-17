//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Counters.sol";


contract MevLGBTQMint is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(uint256 => string ) _tokenURI;

    // Constants
    //uint256 public constant MAX_SUPPLY = 88; //function
    function maxSupply() internal pure returns (uint){
        return 88;
    }

    constructor() ERC721("BubbleMum","BM"){

    }

    function lgbtqMint(address[] calldata wAddresses) public onlyOwner {
        require(
            wAddresses.length < maxSupply(),
            "Too many Addresses"
        );
        require(
            totalSupply() < maxSupply(),
            "Max Supply"
        );

        for (uint i = 0; i < wAddresses.length; ) {
            uint newTokenID = _tokenIds.current() + 1;
            _mint(wAddresses[i],newTokenID);
            _tokenIds.increment();
            unchecked {
                ++i;
            }
        }
    }

    function baseURI() internal pure returns (string memory) {
        return "ipfs://bafybeictvbz2vhyrfqkhj6odo3fjwps4txoyzim263i4x2xrl262kyuzau/bubblemum";
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
      require(_exists(tokenId), "");
      if (bytes(_tokenURI[tokenId]).length > 0) {
          return _tokenURI[tokenId];
      }
      return string(abi.encodePacked(baseURI(), tokenId.toString(), ".json"));
    }

    function setTokenURI(string memory uri, uint tokenId ) public onlyOwner {
        if (tokenId == 0){
            for(uint i = 1; i<=totalSupply(); ){
                string memory linktext = string(abi.encodePacked(uri, i.toString(), ".json"));
                _tokenURI[i] = linktext;
                unchecked {
                    ++i;
                }
            }
        }else{
            _tokenURI[tokenId] = uri;
        }
    }

}