// SPDX-License-Identifier: MIT

/**
*   @title ERC-721 TL Creator
*   @notice ERC-721 contract with owner and admin for execution and each token has a separate token URI. Only can mint tokens to the artist's wallet
*   @author transientlabs.xyz
*/

/*
   ___       _ __   __  ___  _ ______                 __ 
  / _ )__ __(_) /__/ / / _ \(_) _/ _/__ _______ ___  / /_
 / _  / // / / / _  / / // / / _/ _/ -_) __/ -_) _ \/ __/
/____/\_,_/_/_/\_,_/ /____/_/_//_/ \__/_/  \__/_//_/\__/                                                          
 ______                  _          __    __        __     
/_  __/______ ____  ___ (_)__ ___  / /_  / /  ___ _/ /  ___
 / / / __/ _ `/ _ \(_-</ / -_) _ \/ __/ / /__/ _ `/ _ \(_-<
/_/ /_/  \_,_/_//_/___/_/\__/_//_/\__/ /____/\_,_/_.__/___/ 
*/

pragma solidity 0.8.14;

import "ERC721.sol";
import "Ownable.sol";
import "EIP2981AllToken.sol";

contract ERC721TLCreator is ERC721, EIP2981AllToken, Ownable {

    address public adminAddress;

    uint256 internal _counter;
    mapping(uint256 => string) internal _tokenURIs;

    modifier adminOrOwner {
        require(msg.sender == adminAddress || msg.sender == owner(), "ERC721TLCreator: Address not admin or owner");
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == adminAddress, "ERC721TLCreator: Address not admin");
        _;
    }

    /**
    *   @param name is the name of the contract
    *   @param symbol is the symbol
    *   @param royaltyRecipient is the royalty recipient
    *   @param royaltyPercentage is the royalty percentage to set
    *   @param admin is the admin address
    */
    constructor (
        string memory name,
        string memory symbol,
        address royaltyRecipient,
        uint256 royaltyPercentage,
        address admin
    )
        ERC721(name, symbol)
        EIP2981AllToken(royaltyRecipient, royaltyPercentage)
        Ownable()
    {
        adminAddress = admin;
    }

    /**
    *   @notice function to change the royalty info
    *   @dev requires owner
    *   @dev this is useful if the amount was set improperly at contract creation.
    *   @param newAddr is the new royalty payout addresss
    *   @param newPerc is the new royalty percentage, in basis points (out of 10,000)
    */
    function setRoyaltyInfo(address newAddr, uint256 newPerc) external virtual onlyOwner {
        _setRoyaltyInfo(newAddr, newPerc);
    }

    /**
    *   @notice function for minting new token to the owner's address
    *   @dev requires owner or admin
    *   @dev using _mint function as owner() should always be an EOA
    *   @param uri is the token uri
    */
    function mint(string memory uri) external virtual adminOrOwner {
        _counter++;
        _tokenURIs[_counter] = uri;
        _mint(owner(), _counter);
    }

    /**
    *   @notice function to set uri for a token id
    *   @dev requires owner or admin
    */
    function setTokenURI(uint256 tokenId, string memory newURI) external virtual adminOrOwner {
        require(_exists(tokenId), "ERC721TLCreator: URI set of nonexistent token");
        _tokenURIs[tokenId] = newURI;
    }

    /**
    *   @notice function to renounce admin rights
    *   @dev requires admin only
    */
    function renounceAdmin() external virtual onlyAdmin {
        adminAddress = address(0);
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
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(_exists(tokenId), "ERC721TLCreator: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    /**
    *   @notice function to show current supply of NFTs minted
    */
    function totalSupply() external view returns (uint256) {
        return _counter;
    }

    /**
    *   @notice overrides supportsInterface function
    *   @param interfaceId is supplied from anyone/contract calling this function, as defined in ERC 165
    *   @return a boolean saying if this contract supports the interface or not
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, EIP2981AllToken) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || EIP2981AllToken.supportsInterface(interfaceId);
    }
}