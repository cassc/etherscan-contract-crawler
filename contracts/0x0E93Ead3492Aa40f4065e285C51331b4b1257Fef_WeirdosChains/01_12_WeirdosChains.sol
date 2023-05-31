// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WeirdosChains is ERC1155, ERC1155Burnable, Ownable {
    using Strings for uint256;

    mapping(uint256 => bool) public validChainTypes;
    string private baseURI;

    constructor(string memory _baseURI) ERC1155(_baseURI) {
        baseURI = _baseURI;
        validChainTypes[0] = true;
        validChainTypes[1] = true;
    }

    function setValidChainType(uint256 _typeId, bool _valid) external onlyOwner {
        validChainTypes[_typeId] = _valid;
    }

    function mintBatch(uint256[] memory _tokenIds, uint256[] memory _amounts) external onlyOwner {
        _mintBatch(owner(), _tokenIds, _amounts, "");
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function uri(uint256 _typeId) public view override returns (string memory) {
        require(
            validChainTypes[_typeId],
            "Chain typeId does not exist."
        );

        return bytes(baseURI).length != 0
            ? string(abi.encodePacked(baseURI, _typeId.toString()))
            : "";
    }
}