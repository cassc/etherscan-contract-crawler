// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract IRIDION is ERC721, DefaultOperatorFilterer, PullPayment, Ownable, Pausable {
    using Counters for Counters.Counter;

    // Constants
    uint256 public constant TOTAL_SUPPLY = 667;

    uint256 public mintPrice;

    Counters.Counter private currentTokenId;
    
    /// @dev Base token URI used as a prefix by tokenURI().
    string public baseTokenURI;

    constructor() ERC721("IRIDION", "IRDN") {
        baseTokenURI = "";
        mintPrice = 0.05 ether;
    }
    
    function mintTo(address recipient) external payable whenNotPaused returns (uint256) {
        uint256 tokenId = currentTokenId.current();
        require(tokenId < TOTAL_SUPPLY, "Max supply reached");
        require(msg.value == mintPrice, "Transaction value did not equal the mint price");

        currentTokenId.increment();
        uint256 newItemId = currentTokenId.current();
        _safeMint(recipient, newItemId);
        return newItemId;
    }

    function giveaway(address recipient) external onlyOwner returns (uint256) {
        uint256 tokenId = currentTokenId.current();
        require(tokenId < TOTAL_SUPPLY, "Max supply reached");
        currentTokenId.increment();
        uint256 newItemId = currentTokenId.current();
        _safeMint(recipient, newItemId);
        return newItemId;
    }
    
    /// @dev Returns an URI for a given token ID
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @dev Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    /// @dev Overridden in order to make it an onlyOwner function
    function withdrawPayments(address payable payee) public override onlyOwner virtual {
        super.withdrawPayments(payee);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}