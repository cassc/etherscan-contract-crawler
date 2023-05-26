// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "../OperatorFilterer.sol";

contract DelabsLadyBuggy is ERC721A, ERC721AQueryable, ERC721ABurnable, ReentrancyGuard,
    OperatorFilterer, Ownable, ERC2981 {

    string private baseURI;
    bool public operatorFilteringEnabled;

    constructor() ERC721A("DelabsLadyBuggy", "LADYBUGGY") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        baseURI="https://api.delabs.gg/ladybuggy/";
        _setDefaultRoyalty(msg.sender, 500);
    }
    
    function airdropNfts(address[] calldata wAddresses, uint256[] calldata quantity) external onlyOwner {
        for (uint i = 0; i < wAddresses.length; i++) {
           _mintNFT(wAddresses[i], quantity[i]);
        }
    }

    function _mintNFT(address wAddress, uint256 quantity) private{
        _safeMint(wAddress, quantity);
    }

    function bulkTransfer(uint256[] calldata tokenIds, address _to) external nonReentrant {
        for (uint256 i; i < tokenIds.length;i++) {
            transferFrom(msg.sender, _to, tokenIds[i]);
        }
    }

    function bulkBurn(uint256[] calldata tokenIds) external nonReentrant{
         for (uint i = 0; i < tokenIds.length; i++) {
            _burn(tokenIds[i], true);
        }
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    /**
     * @dev Both safeTransferFrom functions in ERC721A call this function
     * so we don't need to override them.
     */
    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC721A, ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}