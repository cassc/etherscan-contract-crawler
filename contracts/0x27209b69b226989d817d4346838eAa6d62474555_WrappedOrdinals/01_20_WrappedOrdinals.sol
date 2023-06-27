// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract WrappedOrdinals is ERC721Enumerable, ERC2981, DefaultOperatorFilterer, Ownable {

    address private _treasuryAddress;
    address private _burnAddress = 0x000000000000000000000000000000000000dEaD;
    
    mapping(uint256 => string) private _tokenURIs;

    constructor(address treasuryAddress) ERC721("WRAPPED ORDINALS", "WROR") {
      _treasuryAddress = treasuryAddress;
    }

    // Withdraw contract balance to creator (mnemonic seed address 0)
    function withdraw() public onlyOwner {
        (bool os, ) = payable(_treasuryAddress).call{value: address(this).balance}('');
        require(os);
    }

    function mintToken(address userAddress, string memory _tokenURI) public onlyOwner  {
        uint256 mintIndex = totalSupply();
        _safeMint(userAddress, mintIndex);
        _tokenURIs[mintIndex] = _tokenURI;
    }

    function supply() public view returns (uint256) {
        uint256 burnedAmount = balanceOf(_burnAddress);
        uint256 curSupply = totalSupply() - burnedAmount;
        return curSupply;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return ownerOf(tokenId) == _burnAddress 
            ? ""
            : 
            bytes(_tokenURIs[tokenId]).length > 0 
                ? _tokenURIs[tokenId]
                : "";
    }

    function isBurned(uint256 tokenId) public view returns (bool) {
        bool _isBurned = (ownerOf(tokenId) == _burnAddress) ? true : false;
        return _isBurned;
    }

    function setTreasuryAddress(address treasuryAddress) external onlyOwner {
        _treasuryAddress = treasuryAddress;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return 
            ERC721Enumerable.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     */
    function burn(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Only owner of token can burn");
        safeTransferFrom(msg.sender, _burnAddress, tokenId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC721-approve}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721, IERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}