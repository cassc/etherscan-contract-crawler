// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

error MintingPaused(string error);
error MaxSupplyReached(string error);
error MaxPerWalletReached(string error);
error ContractMint();

contract UniHeroes is Ownable, ERC721A, DefaultOperatorFilterer {

    uint256 public constant MAX_SUPPLY = 4888;
    uint256 public constant max_per_wallet = 5;
    uint256 public constant PRICE = 0.0059 ether;

    string private baseUri;

    bool public mintActive = false;

    constructor(string memory _baseUri) ERC721A("UniHeroes", "UHRS") {
        baseUri = _baseUri;
    }

    function mint(uint256 quantity) external payable {
        if (!mintActive) revert MintingPaused("Sale hasn't started yet");
        if (_totalMinted() + quantity > MAX_SUPPLY) revert MaxSupplyReached("SOLD OUT");
        if (balanceOf(msg.sender) + quantity > max_per_wallet) revert MaxPerWalletReached( "Max per wallet");
        if (msg.sender != tx.origin) revert ContractMint();
        if (_getAux(msg.sender) < 1) {
            _setAux(msg.sender, 1);
            if (quantity > 1){
                require(PRICE * (quantity - 1) <= msg.value,"Insufficient funds sent");
            }
        } else {
            require(PRICE * quantity <= msg.value,"Insufficient funds sent");
        }
        _mint(msg.sender, quantity);
    }
    
    function mintForAddress(uint256 quantity, address[] memory adresses) external payable onlyOwner {
        require(totalSupply() + quantity * adresses.length <= MAX_SUPPLY,"SOLD OUT");
        for (uint32 i = 0; i < adresses.length;){
            _mint(adresses[i], quantity);
            unchecked {i++;}
        }
    }

    function changeBaseUri(string memory newURI) external onlyOwner {
        baseUri = newURI;
    }

    function setSale(bool state) external onlyOwner {
        mintActive = state;
    }

    function withdrawAll() external onlyOwner {
        (bool os, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}