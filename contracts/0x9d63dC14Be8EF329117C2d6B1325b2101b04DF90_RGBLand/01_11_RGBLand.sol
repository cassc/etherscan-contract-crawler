// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// Invalid TokenId. `tokenId` is not be between 0 and 16_777_215"
error InvalidTokenId(uint256 tokenId);

/// Insufficient value for transfer. Needed `required` but only
/// `recieved` available.
/// @param recieved Ether sent.
/// @param required Ether required fro purchase
error InsufficientValue(uint256 recieved, uint256 required);

contract RGBLand is Ownable, ERC721 {
    string private _baseTokenURI;

    uint256 private constant RGBCap = 16_777_215;

    constructor(string memory initialBaseTokenURI) ERC721("RGBLand", "RGB") {
        _baseTokenURI = initialBaseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string memory newBaseTokenURI) public onlyOwner {
        _baseTokenURI = newBaseTokenURI;
    }

    function mintTo(address to, uint256 tokenId) public payable {
        if (tokenId > RGBCap) {
            revert InvalidTokenId(tokenId);
        }

        if (msg.value < .001 ether) {
            revert InsufficientValue(msg.value, .001 ether);
        }

        // checks and reverts if the token is already owned by someone
        super._safeMint(to, tokenId);
    }

    function withdraw(address payable beneficiary) public onlyOwner {
        address rgblandAddress = address(this);
        beneficiary.transfer(rgblandAddress.balance);
    }
}