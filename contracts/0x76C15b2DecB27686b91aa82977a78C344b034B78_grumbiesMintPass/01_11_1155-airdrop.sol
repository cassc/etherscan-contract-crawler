// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract grumbiesMintPass is ERC1155, Ownable {
    using Strings for uint256;

    constructor(string memory _baseURI) ERC1155(_baseURI) {
        baseURI = _baseURI;
    }

    string private baseURI;

    function airdrop(address[] calldata addrs, uint256 _tokenID)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            _mint(addrs[i], _tokenID, 1, "");
        }
    }

    function updateBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function uri(uint256 typeId) public view override returns (string memory) {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, typeId.toString()))
                : baseURI;
    }
}