// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./libraries/TransferHelper.sol";

contract NGNFT is ERC721Enumerable, ERC721URIStorage {
    uint public tokenIdTracker;

    bool public publicMint = false;
    bool public canTransfer = false;

    uint256 public maxVikingsTotal;
    uint256 public pricePerViking;
    uint public maxVikingPerTransaction;

    string public baseURIValue;

    mapping (address => bool) private admins;

    constructor(
        string memory name,
        string memory symbol,
        uint256 _pricePerViking,
        uint256 _maxVikings,
        uint _maxVikingPerTransaction,
        string memory _baseUri
    ) ERC721(name, symbol) {
        admins[msg.sender] = true;

        pricePerViking = _pricePerViking;
        maxVikingsTotal = _maxVikings;
        maxVikingPerTransaction = _maxVikingPerTransaction;
        baseURIValue = _baseUri;
    }

    function isAdmin(address maybeAdmin) private view returns (bool) {
        return admins[maybeAdmin];
    }

    modifier onlyAdmin {
        require(isAdmin(msg.sender), "NG::NFT: No admin.");
        _;
    }

    function freeMint(address to, uint amount) external onlyAdmin {
        require((tokenIdTracker + amount) < maxVikingsTotal, "NG::NFT: All vikings have been minted.");

        _mintMultiple(amount, to);
    }

    function mint(uint amount) external payable {
        require(publicMint, "NG::NFT: Minting currently disabled.");
        require(msg.value >= (amount * pricePerViking), "NG::NFT: Insufficient funds.");
        require((tokenIdTracker + amount) < maxVikingsTotal, "NG::NFT: All vikings have been minted.");
        require(amount <= maxVikingPerTransaction, "NG::NFT: Too many vikings in single transaction.");

        _mintMultiple(amount, msg.sender);
    }

    function _mintMultiple(uint amount, address to) private {
        for (uint i = 0; i < amount; i++) {
            _mint(to, tokenIdTracker);

            tokenIdTracker++;
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURIValue;
    }

    function setBaseURI(string memory baseURI_) external onlyAdmin {
        baseURIValue = baseURI_;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyAdmin {
        _setTokenURI(tokenId, _tokenURI);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        return ERC721URIStorage._burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from != address(0) && to != address(0)) {
            require(canTransfer, "NG::NFT: Transfers currently disabled.");
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function flipPublicMint() external onlyAdmin {
        publicMint = !publicMint;
    }

    function flipCanTrade() external onlyAdmin {
        canTransfer = !canTransfer;
    }

    function setAdmin(address maybeAdmin, bool _isAdmin) external onlyAdmin {
        admins[maybeAdmin] = _isAdmin;
    }

    function withdrawErc(address token, address recipient, uint256 amount) external onlyAdmin {
        TransferHelper.safeApprove(token, recipient, amount);
        TransferHelper.safeTransfer(token, recipient, amount);
    }

    function withdrawETH(address recipient, uint256 amount) external onlyAdmin {
        TransferHelper.safeTransferETH(recipient, amount);
    }
}