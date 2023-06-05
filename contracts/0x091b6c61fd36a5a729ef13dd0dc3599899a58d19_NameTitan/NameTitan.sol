/**
 *Submitted for verification at Etherscan.io on 2023-04-09
*/

// SPDX-License-Identifier: MIT

/*
     .____    .__             .__    .___
     |    |   |__| ________ __|__| __| _/
     |    |   |  |/ ____/  |  \  |/ __ |
     |    |___|  < <_|  |  |  /  / /_/ |
     |_______ \__|\__   |____/|__\____ |
             \/      |__|             \/
 ___________.__  __
 \__    ___/|__|/  |______    ____   ______
   |    |   |  \   __\__  \  /    \ /  ___/
   |    |   |  ||  |  / __ \|   |  \\___ \
   |____|   |__||__| (____  /___|  /____  >
                          \/     \/     \/

   Name your Titan. Prepare for the Arena.
*/

pragma solidity ^0.8.0;

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function getApproved(uint256 tokenId) external view returns (address);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract NameTitan {
    address public Titans = 0x21d6Fe3B109808Fc69CDaF9829457B0d780Bd975;

    mapping(uint256 => string) private _tokenName;
    mapping(string => bool) private _nameExists;
    uint256 totalSupply = 420;

    constructor(){}

    function nameTitan(uint256 tokenId, string memory name) external {
        require(
            IERC721(Titans).ownerOf(tokenId) == msg.sender,
            "NamedNFT: caller is not owner"
        );
        require(bytes(name).length > 0, "NamedNFT: name cannot be empty");
        require(!_nameExists[name], "NamedNFT: name already exists");

        _tokenName[tokenId] = name;
        _nameExists[name] = true;
    }

    function getTokenName(uint256 tokenId) external view returns (string memory) {
        return _tokenName[tokenId];
    }

    function getAllNames() external view returns (string[] memory) {
        string[] memory names = new string[](totalSupply);

        for (uint256 i = 0; i < totalSupply; i++) {
            uint256 tokenId = i + 1; // assuming token IDs start from 1
            if (bytes(_tokenName[tokenId]).length > 0) {
                names[i] = _tokenName[tokenId];
            }
        }

        return names;
    }

}