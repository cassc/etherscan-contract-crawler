// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
    ''''''''''''''''''''''''''''''''''''''''''''''''''
    ''''''''''''''''''''''''''''''''''''''''''''''''''
    ''''''''''''''''''''''''''''''''''''''''''''''''''
    ''''''''''''''''''''''''''''''''''''''''''''''''''
    ''''''''''''''''''''''''''''''''''''''''''''''''''
    ''''''''''''''''''''''''''''',''''''''''''''''''''
    ''''''''''''''''''''''''''.;okx;.'''''''''''''''''
    ''''''''''''''''''''''''..'ok00:.'''''''''''''''''
    '''''''''''''''.'';::;,'..cxkXx'''''''''''''''''''
    ''''''''''.''',lx0KNXOdlodxdOKc.''''''''''''''''''
    ''''''''''''''lXWMMMMMMWNNxdNXxl:,''''''''''''''''
    '''''''''''''',lONWMMMMMWNKXMMMWN0xl;'''''''''''''
    ''''''''''''''..':ox0XWMMMMMMMMMMMMW0l''''''''''''
    '''''''''.'',:ll:,'.';codxkO0KXXNNXK0o,.''''''''''
    ''''''''''''.':oO0Oxdolc:::::clodxxkx:''''''''''''
    '''''''''''''''',dXMMMWWNNNXXXXNNNXkc'''''''''''''
    ''''''''''''''''''c0WMMWNXXK0Okdoc;'''''''''''''''
    ''''''''''''''''''.,xXWN0Oxl,''..'''''''''''''''''
    '''''''''''''''''''.'coc;,'.''''''.'''''''''''''''
    '''''''''''''''''''''..'''''''''''''''''''''''''''
    ''''''''''''''''''''''''''''''''''''''''''''''''''
    ''''''''''''''''''''''''''''''''''''''''''''''''''
    ''''''''''''''''''''''''''''''''''''''''''''''''''
    ''''''''''''''''''''''''''''''''''''''''''''''''''
    ''''''''''''''''''''''''''''''''''''''''''''''''''
*/

/// @title Spintop NFT
/// @author @takez0_o
/// @notice This contract is being used to gift Spintop NFTs to users.
/// @dev Owner can mint with no limit/restrictions.
contract SpintopNFT is ERC721, Ownable {
    string public baseUri;

    constructor() ERC721("Spintop NFT", "SPINTOP") {
        baseUri = "https://spintop-files.fra1.digitaloceanspaces.com/nft/metadata/";
    }

    function mint(address to, uint256 tokenId) external onlyOwner {
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function setBaseURI(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        return string(abi.encodePacked(baseUri, _toString(_tokenId)));
    }
}