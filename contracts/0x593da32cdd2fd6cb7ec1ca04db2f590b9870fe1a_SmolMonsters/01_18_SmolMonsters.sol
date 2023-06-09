// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
pragma abicoder v2;

import "./SmolMintable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SmolMonsters is
    Context,
    ERC721Enumerable,
    ERC721Burnable,
    SmolMintable
{
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;
    string private _baseTokenURI;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;        
        _tokenLimit = 7337;
        validatorWallet = 0x6b96F977e17641460D8f7489e60224A3ce76D512;
        payoutWallet = 0x1B78A3C3ABdA8Fceb15e83ece78Cf3232A38b65a;
        whitelistEnabled = true;
        publicMintEnabled = false;
        _maxTokensPerWallet = 100;
        _maxTokensPerWhitelistWallet = 5;
        _maxTokensPerTransactionPublic = 10;
        _maxTokensPerTransactionWhitelist = 5;
        pricePerToken = 0.0773 ether;
        pricePerTokenTier1 = 0.0737 ether;
        pricePerTokenTier2 = 0.07 ether;
        pricePerTokenTier3 = 0.0673 ether;
        pricePerTokenTier4 = 0.0637 ether;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }


    function setBaseURI(string memory permanentBaseURI) public virtual onlyOwner() {
        _baseTokenURI = permanentBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Not found");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }



    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}