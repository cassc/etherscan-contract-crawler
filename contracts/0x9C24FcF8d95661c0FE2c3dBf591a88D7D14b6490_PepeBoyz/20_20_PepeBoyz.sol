// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PepeBoyz is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Royalty,
    Pausable,
    Ownable
{
    uint256 public constant MAX_SUPPLY = 6969;
    address public constant PEPE_TOKEN_ADDRESS =
        0x6982508145454Ce325dDbE47a25d4ec3d2311933;
    IERC20 public constant PEPE_TOKEN = IERC20(PEPE_TOKEN_ADDRESS);

    string private _baseTokenURI;
    uint256 private _nextToMint = 469;
    uint256 private _maxTokenIdForAirdrop = _nextToMint - 1;

    mapping(address => uint256) private _mintedSoFar;

    constructor(string memory baseTokenURI) ERC721("PepeBoyz", "PBOYZ") {
        _baseTokenURI = baseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // Base URI is settable by the owner
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    // Token URI is settable by the owner
    function setTokenURI(uint256 tokenId, string memory uri) public onlyOwner {
        _setTokenURI(tokenId, uri);
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 numerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 numerator
    ) public onlyOwner {
        _setTokenRoyalty(tokenId, receiver, numerator);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // Public minting function
    // Caller needs to hold at least one PEPE token
    // Caller can only mint 2 tokens
    function mint() public {
        require(_nextToMint < MAX_SUPPLY, "PBOYZ: Max supply reached");
        require(
            PEPE_TOKEN.balanceOf(msg.sender) > 0,
            "PBOYZ: You need at least one PEPE token to mint"
        );
        require(
            _mintedSoFar[msg.sender] < 2,
            "PBOYZ: You can only mint 2 tokens"
        );

        _safeMint(msg.sender, _nextToMint);
        _nextToMint++;

        _mintedSoFar[msg.sender]++;
    }

    // Airdrop function
    // Only callable by the owner
    // Recipient needs to hold at least one PEPE token
    // Recipient can only hold 2 tokens
    function airdrop(address recipient, uint256 tokenId) public onlyOwner {
        require(
            tokenId <= _maxTokenIdForAirdrop,
            "PBOYZ: You can only airdrop certain token IDs"
        );
        require(
            PEPE_TOKEN.balanceOf(recipient) > 0,
            "PBOYZ: The receiver needs to hold at least one PEPE token"
        );

        _safeMint(recipient, tokenId);
    }

    // Batch airdrop function
    // Only callable by the owner
    function batchAirdrop(
        address[] memory recipients,
        uint256[] memory tokenIds
    ) public onlyOwner {
        require(
            recipients.length == tokenIds.length,
            "PBOYZ: The arrays must have the same length"
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            airdrop(recipients[i], tokenIds[i]);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage, ERC721Royalty) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}