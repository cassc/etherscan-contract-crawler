// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/* 
    ___     _______ _______  _______ __ _______ _______ 
    |   |   |   _   |   _   \|   _   |__|   _   |   _   |
    |.  |   |.  |   |.  1   /|   1___|__|   1___|.  1___|
    |.  |___|.  |   |.  _   \|____   |__|____   |.  __)_ 
    |:  1   |:  1   |:  1    |:  1   |  |:  1   |:  1   |
    |::.. . |::.. . |::.. .  |::.. . |  |::.. . |::.. . |
    `-------`-------`-------'`-------'  `-------`-------'
                                                                                                                                                                           
    The Lobstars: Special Editions. All Rights Reserved 2022
    Developed by ATOMICON.PRO ([email protected])
*/

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract LobstarsSpecialEditions is ERC1155, Ownable, ERC1155Supply {

    /// @dev URI linked to each token ID
    mapping(uint256 => string) private _tokenUris;
    
    constructor() ERC1155("") {}

    /// @notice Airdrop a specific token to a list of accounts
    function airdrop(address[] memory accounts, uint256 id, uint256 amount)
        external
        onlyOwner
    {
        require(bytes(uri(id)).length != 0, "A token id must have metadata URI linked to be airdropped");

        for(uint64 i = 0; i < accounts.length; i++) {
            _mint(accounts[i], id, amount, "");
        }
    }

    /// @notice Set metadata URI of a specific token ID
    function setURI(uint256 id, string memory newUri) 
        external 
        onlyOwner 
    {
        _tokenUris[id] = newUri;
        emit URI(newUri, id);
    }

    /// @notice URI with metadata of each token with a given id
    function uri(uint256 id) public view virtual override returns (string memory) {
        return _tokenUris[id];
    }

    /// @notice URI with contract metadata for opensea
    function contractURI() public pure returns (string memory) {
        return "ipfs://QmNvmy2vomxSwh8o9ZNWzNMWaYzJ2VHcqzwYkEX6RTnhgp";
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}