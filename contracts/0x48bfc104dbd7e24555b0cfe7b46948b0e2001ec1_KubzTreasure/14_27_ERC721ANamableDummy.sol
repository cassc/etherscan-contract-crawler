// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";

contract ERC721ANamableDummy is ERC721AQueryableUpgradeable {
    mapping(uint256 => string) public bio;

    // Mapping from token ID to name
    mapping(uint256 => string) private _tokenName;

    // Mapping if certain name string has already been reserved
    mapping(string => bool) private _nameReserved;

    event NameChange(uint256 indexed tokenId, string newName);
    event BioChange(uint256 indexed tokenId, string bio);


    function __ERC721ANamable_init(string memory _name, string memory _symbol)
        internal
        initializerERC721A
    {
        ERC721AUpgradeable.__ERC721A_init(_name, _symbol);
    }
}