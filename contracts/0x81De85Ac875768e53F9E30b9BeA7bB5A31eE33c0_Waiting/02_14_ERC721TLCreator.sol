// SPDX-License-Identifier: MIT

/**
*   @title ERC-721 TL Creator
*   @notice ERC-721 contract with owner and admin for execution and each token has a separate token URI. Only can mint tokens to the artist's wallet
*   @author Transient Labs
*/

/*
   ___                            __  ___         ______                  _         __    __       __     
  / _ \___ _    _____ _______ ___/ / / _ )__ __  /_  _________ ____  ___ (____ ___ / /_  / / ___ _/ /  ___
 / ___/ _ | |/|/ / -_/ __/ -_/ _  / / _  / // /   / / / __/ _ `/ _ \(_-</ / -_/ _ / __/ / /_/ _ `/ _ \(_-<
/_/   \___|__,__/\__/_/  \__/\_,_/ /____/\_, /   /_/ /_/  \_,_/_//_/___/_/\__/_//_\__/ /____\_,_/_.__/___/
                                        /___/                                                             
*/

pragma solidity ^0.8.0;

import "ERC721.sol";
import "Ownable.sol";
import "EIP2981AllToken.sol";

contract ERC721TLCreator is ERC721, EIP2981AllToken, Ownable {

    uint256 internal _tokenId;
    address public adminAddress;
    mapping(uint256 => string) internal tokenURIs;

    modifier adminOrOwner {
        require(msg.sender == adminAddress || msg.sender == owner(), "ERC721TLCreator: Address not admin or owner");
        _;
    }

    /**
    *   @param name is the name of the contract
    *   @param symbol is the symbol
    *   @param royaltyRecipient is the royalty recipient
    *   @param royaltyPercentage is the royalty percentage to set
    *   @param admin is the admin address
    */
    constructor (string memory name, string memory symbol,
        address royaltyRecipient, uint256 royaltyPercentage, address admin)
        ERC721(name, symbol) EIP2981AllToken(royaltyRecipient, royaltyPercentage) Ownable() {
            adminAddress = admin;
            _tokenId++;
    }

    /**
    *   @notice function to change the royalty info
    *   @dev requires admin or owner
    *   @dev this is useful if the amount was set improperly at contract creation.
    *   @param newAddr is the new royalty payout addresss
    *   @param newPerc is the new royalty percentage, in basis points (out of 10,000)
    */
    function setRoyaltyInfo(address newAddr, uint256 newPerc) external virtual adminOrOwner {
        require(newAddr != address(0), "ERC721TLCreator: Cannot set royalty receipient to the zero address");
        require(newPerc < 10000, "ERC721TLCreator: Cannot set royalty percentage above 10000");
        royaltyAddr = newAddr;
        royaltyPerc = newPerc;
    }

    /**
    *   @notice function for minting new token to the owner's address
    *   @dev requires owner or admin
    *   @param uri is the token uri
    */
    function mint(string memory uri) external virtual adminOrOwner {
        tokenURIs[_tokenId] = uri;
        _safeMint(owner(), _tokenId);
        _tokenId++;
    }

    /**
    *   @notice function to set uri for a token id
    *   @dev requires owner or admin
    */
    function setTokenURI(uint256 tokenId, string memory tokenURI) external virtual adminOrOwner {
        require(_exists(tokenId), "ERC721TLCreator: URI set of nonexistent token");
        tokenURIs[tokenId] = tokenURI;
    }

    /**
    *   @notice function to set the admin address on the contract
    *   @dev requires owner
    *   @param newAdmin is the new admin address
    */
    function setAdminAddress(address newAdmin) external virtual onlyOwner {
        require(newAdmin != address(0), "ERC721TLCreator: New admin cannot be the zero address");
        adminAddress = newAdmin;
    }

    /**
    *   @notice burn function for owners to use at their discretion
    *   @dev requires the msg sender to be the owner or an approved delegate
    *   @param tokenId is the token ID to burn
    */
    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Burn: Not Approved or Owner");
        _burn(tokenId);
    }

    /**
    *   @notice function to override tokenURI
    */
    function tokenURI(uint256 tokenId) override public view returns(string memory) {
        require(_exists(tokenId), "ERC721TLCreator: URI query for nonexistent token");

        string memory _tokenURI = tokenURIs[tokenId];
        return _tokenURI;
    }

    /**
    *   @notice overrides supportsInterface function
    *   @param interfaceId is supplied from anyone/contract calling this function, as defined in ERC 165
    *   @return a boolean saying if this contract supports the interface or not
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, EIP2981AllToken) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}