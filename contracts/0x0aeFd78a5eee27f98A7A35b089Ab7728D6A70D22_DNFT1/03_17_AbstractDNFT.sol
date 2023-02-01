pragma solidity ^0.8.0;

// SPDX-License-Identifier: apache 2.0
/*
    Copyright 2022 Debond Protocol <[email protected]>
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IDNFT.sol";


abstract contract AbstractDNFT is ERC721, Ownable, AccessControl, IDNFT {
    using Strings for uint256;


    // EVENTS
    event WithdrawnToOwner(address indexed _operator, uint256 _ethWei);
    event NftMinted(address indexed _operator, address indexed _to, uint256 _quantity);
    event NftBurned(address indexed _operator, uint256[] _tokenIds);

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bool public revealed;
    string public baseURI;
    string public notRevealedURI;
    Counters.Counter private _tokenId;
    uint256 totalSupply;

    constructor(
        string memory _name,
        string memory _symbol,
        uint _totalSupply
    ) ERC721(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        totalSupply = _totalSupply;
    }


    modifier canMint(uint256 _quantity){
        require(Counters.current(_tokenId) + _quantity <= totalSupply, "exceed the max supply limit");
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function mint(address to, uint256 quantity) external onlyRole(MINTER_ROLE) canMint(quantity)
    {
        require(quantity > 0, "You need to indicate a number of nft to mint greater than 0");
        for (uint256 i= 0; i < quantity; i++)
        {
            _safeMint(to, Counters.current(_tokenId));
            Counters.increment(_tokenId);
        }
        emit NftMinted(_msgSender(), to, quantity);
    }

    function burn(uint256[] calldata tokenIds) external onlyRole(MINTER_ROLE) {
        for (uint i; i < tokenIds.length; i++) {
            require(_exists(tokenIds[i]), "DNFT Error: The given id is not found");
            _burn(tokenIds[i]);
        }
        emit NftBurned(_msgSender(), tokenIds);
    }

    function isOwnerOf(address owner, uint256[] calldata tokenIds) external view returns(bool) {
        for (uint i; i < tokenIds.length; i++) {
            if(ownerOf(tokenIds[i]) != owner) {
                return false;
            }
        }
        return true;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _newNotRevealedURI) public onlyOwner {
        notRevealedURI = _newNotRevealedURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns(string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(!revealed) {
            return notRevealedURI;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
    }

    function tokenCount() external view returns (uint256) {
        return Counters.current(_tokenId);
    }
}