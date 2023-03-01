// SPDX-License-Identifier: MIT

/*
* https://twitter.com/GammaMuNFT
*/

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/DefaultOperatorFilter.sol";


contract GammaMu is DefaultOperatorFilterer, ERC2981, ERC721AQueryable, Ownable {

    uint256 constant MAX_SUPPLY = 8888;
    uint256 constant MAX_MINT_PER_TX = 4;
    uint256 constant MINT_COST_EACH = 0.002496 ether; // Reverse 69,420 heh
    
    bool mintActive;
    bool revealed;
    string baseURI;

    error InsufficientEther();
    error MaxSupplyReached();
    error OnlyEOAAllowed();
    error TooManyMintsRequested();
    error MintEnded();
    
    //------------- Modifiers -------------//
    modifier onlyEOA {
        if (msg.sender != tx.origin) revert OnlyEOAAllowed();
        _;
    }

    modifier mintIsActive {
        if (!mintActive) revert MintEnded();
        _;
    }
    
    constructor(string memory baseURI_) ERC721A("GammaMu", "GM") {
        baseURI = baseURI_;
        _setDefaultRoyalty(msg.sender, 150); // 1.5%
        mintActive = true;
    }

    //------------- Mint & Burn -------------//

    function mint() external payable onlyEOA mintIsActive {
        _handleMint(2);
    }

    function mint(uint256 amount) external payable onlyEOA mintIsActive {
        _handleMint(amount);
    }

    function _handleMint(uint256 amount) internal {
        
        if (_nextTokenId() + amount > MAX_SUPPLY) revert MaxSupplyReached();
        if (amount > MAX_MINT_PER_TX) revert TooManyMintsRequested();
        if (msg.value < amount * MINT_COST_EACH ) revert InsufficientEther();

        _mint(msg.sender, amount);
    }

    // Why we need dis? It's a secret babes ;)
    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
    }

    //------------- Read -------------//

    function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (revealed) {
            return string(abi.encodePacked(baseURI, _toString(tokenId)));
        } else {
            return _baseURI();
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    //------------- Admin -------------//

    function reveal(string memory baseURI_) external onlyOwner {
        revealed = true;
        baseURI = baseURI_;
    }

    function endMint() external onlyOwner {
        mintActive = false;
    }

    function withdraw() external onlyOwner() {
        payable(msg.sender).transfer(address(this).balance);
    }

    function rescueERC20(address token, address recipient) external onlyOwner() {
        IERC20(token).transfer(recipient, IERC20(token).balanceOf(address(this)));
    }

    function rescueERC721(address token, uint256 tokenId, address recipient) external onlyOwner() {
        IERC721(token).transferFrom(address(this), recipient, tokenId);
    }

    //------------- Other -------------//

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A, IERC721A) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setRoyalty(address recipient, uint96 royaltyBips) external onlyOwner() {
        _setDefaultRoyalty(recipient, royaltyBips);
    }

    receive() external payable {}

    fallback() external payable {}
}