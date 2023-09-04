// Koios NFT  for https://www.koios.world
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./SignedTokenVerifier.sol";

contract KoiosECDSA is ERC721Enumerable, Ownable, SignedTokenVerifier {
    using Strings for uint256;

    // Defines the burnable ERC20 token for the contract
    uint constant public _maxSupply = 1000;
    string constant public _NFTBaseURI = "ipfs://Qmaef1GCZhQMXSZnAPP8Yu6PGaZeQirHeYtzwZdDXjbSVN/";

    event tokenMinted(uint tokenID, address minterAddress);

    //Errors
    error InvalidToken();
    error MaxSupplyReached();
    error TokenIDDoesNotExist();

    constructor() ERC721("KOIOSNFT", "KOIOSNFT") {         
    }

    function claim(string calldata _salt, bytes calldata _token, uint256 tokenId) external {
        if(totalSupply() + 1 > _maxSupply) revert MaxSupplyReached();
        if(!verifyTokenForAddress(_salt, _token, tokenId, msg.sender)) revert InvalidToken();
        _safeMint(msg.sender, tokenId);
        emit tokenMinted(tokenId, msg.sender);
    }

    function setSigner(address _signer) public onlyOwner {
        _setSigner(_signer);
    }

    function _isTokenMinted(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if(!_exists(tokenId)) revert TokenIDDoesNotExist();
        string memory baseURI = _NFTBaseURI;
        string memory json = ".json";

        if (bytes(baseURI).length == 0)
           return '';
        return string(abi.encodePacked(baseURI, tokenId.toString(), json));
    }
}