// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AussieSnacks is ERC1155, ERC1155Burnable, Ownable {
    struct metadata {
        string name;
        string description;
        string image;
    }
    mapping (uint256 => metadata) private uris;

    constructor() ERC1155("") {}

    function setURI(uint256 tokenId, metadata memory m) external onlyOwner {
        uris[tokenId] = m;
    }

    function mint(address account, uint256 id, uint256 amount) public {
        require(id <= 4, "invalid token ID");
        _mint(account, id, amount, "");
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) public {
        for(uint i; i < ids.length; i++) {
            require(ids[i] <= 4, "invalid token ID");
        }

        _mintBatch(to, ids, amounts, "");
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        super.uri(tokenId);

        metadata storage m = uris[tokenId];

        return string(
            abi.encodePacked(
                'data:application/json;utf8,',
                '{"name": "', m.name, '",',
                '"description": "', m.description, '",',
                '"image": "', m.image, '",',
                '"image_url": "', m.image, '"',
                '}'
            )
        );
    }

    function isCardoCool() external pure returns (bool) {
        return true;
    }

    function isJCCool() external pure returns (bool) {
        return true;
    }
}