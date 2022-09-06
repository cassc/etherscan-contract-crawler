// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
      ___           ___                                 ___           ___                                      ___           ___           ___                  
     /  /\         /  /\           ___                 /  /\         /  /\           ___         __           /  /\         /  /\         /  /\           ___   
    /  /::|       /  /::\         /__/\               /  /::\       /  /:/          /__/\       |  |\        /  /::\       /  /::\       /  /:/          /__/\  
   /  /:|:|      /  /:/\:\        \__\:\             /  /:/\:\     /  /:/           \__\:\      |  |:|      /  /:/\:\     /__/:/\:\     /  /:/           \__\:\ 
  /  /:/|:|__   /  /::\ \:\       /  /::\           /  /::\ \:\   /  /::\____       /  /::\     |  |:|     /  /:/  \:\   _\_ \:\ \:\   /  /::\ ___       /  /::\
 /__/:/_|::::\ /__/:/\:\_\:\   __/  /:/\/          /__/:/\:\_\:\ /__/:/\:::::\   __/  /:/\/     |__|:|__  /__/:/ \__\:\ /__/\ \:\ \:\ /__/:/\:\  /\   __/  /:/\/
 \__\/  /~~/:/ \__\/  \:\/:/  /__/\/:/~~           \__\/  \:\/:/ \__\/~|:|~~~~  /__/\/:/~~      /  /::::\ \  \:\ /  /:/ \  \:\ \:\_\/ \__\/  \:\/:/  /__/\/:/~~ 
       /  /:/       \__\::/   \  \::/                   \__\::/     |  |:|      \  \::/        /  /:/~~~~  \  \:\  /:/   \  \:\_\:\        \__\::/   \  \::/    
      /  /:/        /  /:/     \  \:\                   /  /:/      |  |:|       \  \:\       /__/:/        \  \:\/:/     \  \:\/:/        /  /:/     \  \:\    
     /__/:/        /__/:/       \__\/                  /__/:/       |__|:|        \__\/       \__\/          \  \::/       \  \::/        /__/:/       \__\/    
     \__\/         \__\/                               \__\/         \__\|                                    \__\/         \__\/         \__\/                 
*/

contract MaiAkiyoshi is ERC1155Supply, Ownable {
    string public name;
    string public symbol;
    mapping (uint256 => bool) public collectionLocked;
    mapping (uint256 => string) public tokenURI;

    constructor(string memory uriBase, string memory _name, string memory _symbol) ERC1155(uriBase) {
        name = _name;
        symbol = _symbol;
    }

    /**
     * @notice Returns the custom URI for each token id. Overrides the default ERC-1155 single URI.
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        // If no URI exists for the specific id requested, fallback to the default ERC-1155 URI.
        if (bytes(tokenURI[tokenId]).length == 0) {
            return super.uri(tokenId);
        }
        return tokenURI[tokenId];
    }

    /**
     * @notice Sets a URI for a specific token id.
     */
    function setURI(string memory newTokenURI, uint256 tokenId) public onlyOwner {
        tokenURI[tokenId] = newTokenURI;
    }

    /**
     * @notice Set the global default ERC-1155 base URI to be used for any tokens without unique URIs
     */
    function setGlobalURI(string memory newTokenURI) public onlyOwner {
        _setURI(newTokenURI);
    }
    
    /**
     * @notice Allow minting of tokens to a single account
     */
    function mint(address account, uint256 id, uint256 amount) public onlyOwner
    {
        require(!collectionLocked[id], "CANNOT_MINT_LOCKED_TOKEN_ID");
        _mint(account, id, amount, "");
    }

    /**
     * @notice Allow batch minting of tokens to multiple accounts
     */
    function batchMint(address[] calldata accounts, uint256 id, uint256 amount) external onlyOwner
    {
        require(!collectionLocked[id], "CANNOT_MINT_LOCKED_TOKEN_ID");
        for (uint256 i = 0; i < accounts.length; i++) {
            _mint(accounts[i], id, amount, "");
        }
    }

    /**
     * @notice Lock a token id so that it can never be minted again
     */
    function lockToken(uint256 id) public onlyOwner {
        collectionLocked[id] = true;
    }

    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, amount);
    }

    /**
     * @notice Override ERC1155 such that zero amount token transfers are disallowed to prevent arbitrary creation of new tokens in the collection.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {
        require(amount > 0, "AMOUNT_CANNOT_BE_ZERO");
        return super.safeTransferFrom(from, to, id, amount, data);
    }
}