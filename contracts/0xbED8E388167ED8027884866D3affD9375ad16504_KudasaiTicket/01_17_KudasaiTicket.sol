// SPDX-License-Identifier: MIT
//  ___   _  __   __  ______   _______  _______  _______  ___  
// |   | | ||  | |  ||      | |   _   ||       ||   _   ||   | 
// |   |_| ||  | |  ||  _    ||  |_|  ||  _____||  |_|  ||   | 
// |      _||  |_|  || | |   ||       || |_____ |       ||   | 
// |     |_ |       || |_|   ||       ||_____  ||       ||   | 
// |    _  ||       ||       ||   _   | _____| ||   _   ||   | 
// |___| |_||_______||______| |__| |__||_______||__| |__||___| 

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract KudasaiTicket is ERC721Enumerable, ERC721Royalty, Ownable {
    uint256 private constant _tokenMaxSupply = 2000;
    uint256 private _tokenIdCounter;
    string public image;
    event Mint(uint256 id);

    constructor() ERC721("KudasaiTicket", "KT") {}

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function importImage(string memory _image) external onlyOwner {
        image = _image;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(tokenId < _tokenIdCounter, "call to a non-exisitent token");

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "KudasaiTicket #',
                        Util.toStr(tokenId),
                        '", "description": "This NFT collection is mint ticket of the  KudasaiNFT V2 which will be start minting soon. It is a collection of 2,000 unique onchain NFT and it will play an important role in Kudasai Governance", "image": "data:image/png;base64,',
                        image,
                        '"}'
                    )
                )
            )
        );

        string memory output;
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function setRoyaltyInfo(address _receiver, uint96 _feeNumerator) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function ownerMint(address _to, uint256 _quantity) public onlyOwner {
        require(_tokenIdCounter + _quantity <= _tokenMaxSupply, "No more");
        for (uint256 i = 0; i < _quantity; i++) {
            _safeMint(_to, _tokenIdCounter);
            emit Mint(_tokenIdCounter);
            _tokenIdCounter++;
        }
    }
}

library Util {
    function toStr(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory buffer = new bytes(len);
        while (_i != 0) {
            len -= 1;
            buffer[len] = bytes1(uint8(48 + uint256(_i % 10)));
            _i /= 10;
        }
        return string(buffer);
    }
}