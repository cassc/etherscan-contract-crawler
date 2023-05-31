// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./interfaces/IERC721AProxy.sol";
import "./interfaces/IERC721Manager.sol";
import "./ExternalContracts.sol";

// @author: miinded.com

abstract contract ERC721AProxy is IERC721AProxy, ERC721AQueryable, ERC2981, ExternalContracts, DefaultOperatorFilterer {

    string public baseTokenURI;
    IERC721Manager public contractManager;

    constructor(string memory _name, string memory _symbol)
    ERC721A(_name, _symbol){ }

    function setManager(address _contractManager) public onlyOwnerOrAdmins {
        MultiSigProxy.validate("setManager");

        _setManager(_contractManager);
    }
    function _setManager(address _contractManager) internal {
        contractManager = IERC721Manager(_contractManager);
        ExternalContracts._setExternalContract(_contractManager, true);
    }

    function mint(address _wallet, uint256 _count) public override externalContract {
        _safeMint(_wallet, _count);
    }
    function burn(uint256 _tokenId) public virtual override externalContract{
        _burn(_tokenId, true);
    }
    function _startTokenId() internal pure override returns(uint256) {
        return 1;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    function setBaseUri(string memory baseURI) public virtual onlyOwnerOrAdmins {
        baseTokenURI = baseURI;
    }
    function totalMinted() public view virtual override returns (uint256) {
        return _totalMinted();
    }
    function totalBurned() public view virtual override returns (uint256) {
        return _totalBurned();
    }

    /**
     * @notice Allows the owner to set default royalties following EIP-2981 royalty standard.
    */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwnerOrAdmins {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, IERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
        ERC721A.supportsInterface(interfaceId) ||
        ERC2981.supportsInterface(interfaceId);
    }

    /**
    @notice Add the Operator filter functions
    */
    function setApprovalForAll(address operator, bool approved) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        require(contractManager.transferFrom(from, to, tokenId), "ERC721AProxy: TokenId not transferable");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        require(contractManager.transferFrom(from, to, tokenId), "ERC721AProxy: TokenId not transferable");
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        require(contractManager.transferFrom(from, to, tokenId), "ERC721AProxy: TokenId not transferable");
        super.safeTransferFrom(from, to, tokenId, data);
    }
}