// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "erc721a/contracts/ERC721A.sol";
import "hardhat/console.sol";
import "./libraries/Base64.sol";

contract MinimalNFT is ERC721A, ReentrancyGuard, Ownable {
    string description;
    string image;
    bool minted;

    constructor(string memory _name, string memory _symbol, string memory _description, string memory _image, address _owner) ERC721A(_name, _symbol) Ownable() {
        description = _description;
        image = _image;
        if (_owner != address(0)) {
            transferOwnership(_owner);
        }
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "', name(), ' #', toString(tokenId), '", "description": "', description, '", "image": "', image, '"}'))));
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function mint(uint256 _totalSupply) onlyOwner external {
        require(!minted, "Mint already completed");
        _mint(msg.sender, _totalSupply);
        minted = true;
    }

    function setDescription(string memory _description) onlyOwner external {
        description = _description;
    }

    function setImage(string memory _image) onlyOwner external {
        image = _image;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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
}