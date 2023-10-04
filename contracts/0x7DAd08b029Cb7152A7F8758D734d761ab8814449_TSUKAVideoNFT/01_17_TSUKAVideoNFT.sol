// SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.18;                                                                                                 
//  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒ 
//  ▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒█████▒▓▒▓▒▓████▒▓▒▓▒▓▒████▒▓▒▓▒▓▒████▒▓▒▓▒▓▒████▒▓▒▓▒████▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▒ 
//  ▒▒▒██████████████████  ██▒▒████  ████▒████  ███▒▒████  ████▓▒███  ████▒██  ███████▓████▒▒▒████▒▒▒▒ 
//  ▒▒▒█         ██        ██▒▒█        █▒█       █▒▒█        █▓▒█       █▒█         █▓█  █▒▒▒█  █▒▒▓▒ 
//  ▒▓▒█  █████  ████ ████  █▒▒████  ████▒████  ███▒▒████  ████▓▒█████  ██▒██  ████  █▓█  █▒▒▒█  █▒▒▒▒ 
//  ▒▒▒█  █▒██░ ███       ███▒▒▒▒▒█  █▒▒▒▒▒▒▒█  █▒▒▒▒▒▒▒█  █▒▒▒▒██  ███  ██▒█  ██   ██▒█  █▒▒██  █▒▒▒▒ 
//  ▒▒▒██████   █▒██  ███████▒▓████  █▒▒▒▓████ ████▓▒▓▒▒█  ███▒██      █  ███  █   ███▓█  ████   █▒▒▓▒ 
//  ▒▓▒█      ███▒▒██       █▒████   █▒▒▓████  █████▒▒▒▒██   █▒██  ██████  ██  ████  █▓█         █▒▒▒▒ 
//  ▒▒▒████████▒▒▒▒▒███     █▒█    ███▒▒▒█         █▒▒▓▒▒███ █▒██ ██▒▒▒██ ██▒███▒▒████▓███████████▒▒▒▒ 
//  ▒▒▒▒▒▒▒▒█████▒▓▒▒▓███████▒██████▒███▒█████████████████████▒█████▒▒▒▒███▓██▓▒▒▒▒▒▒▓███▒▒▒▒▒▒▒▒▒▒▓▒▒ 
//  ▒▓▒██████   ███████▒▒▒▒▒▒▒▒▒▒▒▒▒██ ██▒▒▒▒█              █▒▒█   █▒▒▓▒▒▒▒▒▒▒▒▒▓▒▒▒▒██ ██▒▒▒▒▒▒▒▒▒▒▒▒ 
//  ▒▒▒█▒████   █████▒█▒█████████████   ██▒▒▒████████████████▒▒█   █▒▒▒▒▒█████▒▒▒█████   ██████▒▓▒▒▓▒▒ 
//  ▒▒▒█              █▒█                ██▒▒█   █▒▒▒▒▒▒█   █▒▒█   █▒█████   █▒▓▒█            █▒▒▒▒▒▒▒ 
//  ▒▓▒██████   ███████▒███   █████████   █▒▒█   █▒▒▒▒▒▒█   █▒▒█   ███       █▒▒▒███████   ████▒▒▓▒▒▓▒ 
//  ▒▒▒▒▒▒▒▒█   █▒▒▒▒▒▒▒▒▒█   █████████▓ ██▒▒█   █▒▒▓▒▓▒█   █▒▒█         █████▒▒▒▒███████   ██▒▒▒▒▒▒▒▒ 
//  ▒▒▒▒▒▒▒▒█   █▒▒▒▒▒▒▒▒▒█               █▒▒█   █▒▒▒▒▒██   █▒▒█      █   ██▒▒▒▓▒██   █▓█    ██▒▓▒▒▓▒▒ 
//  ▒▓▒▓▒▓▒▒█   ██▒▓▒▓▒▓▒▒██              █▒▒█   █▒▒▒▒███   █▒▒█   █████   ██▒▒▒██   █████    ██▒▒▒▒▒▒ 
//  ▒▒▒▒▒▒▒▒██   ██▒▒▒▒▒███████████████  ░█▒▒█   ██████     █▒▒█   █▒▒▒██   ██▒██    █    █    █▓▒▓▒▒▓ 
//  ▒▒▒▒▒▒▓▒▒█    ███▒▒▒█   ██████████   ██▒▒█              █▒▒█   █▒▒▒▒█    ███    ██    ██   ██▒▒▒▒▒ 
//  ▒▓▒▓▒▒▒▒▒██     █▒▒▒██               █▒▒▒█         ██   █▒▒█   █▒▒▓▒██   ██    ██████████   █▒▒▓▒▒ 
//  ▒▒▒▒▒▒▓▒▒▒███████▒▒▒▒███          ████▒▒▒█   ████████   █▒▒█   █▒▒▒▒█   ████  ██▒▒▒▒▒▒▒▒██  █▒▒▒▒▒ 
//  ▒▒▒▒▓▒▒▒▓▒▒▒▒████▒▒▓▒▒▓████████████▓▒▒▒▓▒█████▒▒▒▒▒▒█████▒▒█████▒▒▒▒█████▒▒████▒▒▒▒▒▒▒▒▒▒████▒▒▒▓▒ 
//  ▒▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▒▓▒▓▒▓▒▒▒▒▒▒▒▓▒▒▒ 
                                                                                                    
import "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

/// @title TSUKAVideoNFT
/// @dev A contract for the TSUKA Video Animation NFTs.
contract TSUKAVideoNFT is ERC721URIStorage, Ownable {
    /// @notice The URI for the contract metadata.
    string public contractURI;

    /// @dev Initializes the contract by setting a name and a symbol for the token.
    constructor() ERC721("TSUKA Video Animation NFT", "TSUKAV") {
        contractURI = "https://eykooeds6ixfq7srarpfl6vq7gyxv5th5tbcsabskpfjmc5xwpja.arweave.net/JhTnEHLyLlh-UQReVfqw-bF69mfswikAMlPKlgu3s9I";
    }

    /// @notice Mints a new token.
    /// @dev Only the owner can mint tokens.
    /// @param to The address that will receive the minted token.
    /// @param tokenId The token id to mint.
    function mint(address to, uint256 tokenId) public onlyOwner {
        _mint(to, tokenId);
    }

    /// @notice Mints a new token and sets its token URI.
    /// @dev Only the owner can mint tokens.
    /// @param to The address that will receive the minted token.
    /// @param tokenId The token id to mint.
    /// @param _tokenURI The token URI to set.
    function mintWithTokenURI(address to, uint256 tokenId, string memory _tokenURI) public onlyOwner {
        _mint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }

    /// @notice Sets the contract URI.
    /// @dev Only the owner can set the contract URI.
    /// @param _contractURI The URI to set.
    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    /// @notice Sets a token URI.
    /// @dev Only the owner can set token URIs.
    /// @param tokenId The token id to set the URI for.
    /// @param _tokenURI The URI to set.
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(tokenId, _tokenURI);
    }

    /// @notice Checks if a token exists.
    /// @param tokenId The token id to check.
    /// @return A boolean indicating if the token exists.
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    /// @notice Burns a token.
    /// @dev Only the owner of the token can burn it.
    /// @param tokenId The token id to burn.
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller neither owner nor approved");
        _burn(tokenId);
    }
}