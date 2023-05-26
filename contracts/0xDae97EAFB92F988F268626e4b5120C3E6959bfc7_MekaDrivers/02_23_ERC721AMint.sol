// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./Admins.sol";

// @author: miinded.com

abstract contract ERC721AMint is ERC721A, ERC721AQueryable, ERC2981, Admins, ReentrancyGuard, DefaultOperatorFilterer {

    uint32 public MAX_SUPPLY;
    uint32 public RESERVE;

    string public baseTokenURI;

    //******************************************************//
    //                      Modifier                        //
    //******************************************************//
    modifier notSoldOut(uint256 _count) {
        require(_totalMinted() + _count <= MAX_SUPPLY, "Sold out!");
        _;
    }
    modifier onlyApprovedOrOwner(uint256 tokenId) {
        require(
            _ownershipOf(tokenId).addr == _msgSender() ||
            getApproved(tokenId) == _msgSender(),
            "ERC721ACommon: Not approved nor owner"
        );
        _;
    }

    //******************************************************//
    //                      Setters                         //
    //******************************************************//
    function setMaxSupply(uint32 _maxSupply) internal {
        MAX_SUPPLY = _maxSupply;
    }
    function setReserve(uint32 _reserve) internal {
        RESERVE = _reserve;
    }
    function setBaseUri(string memory baseURI) public onlyOwnerOrAdmins {
        baseTokenURI = baseURI;
    }
    function _startTokenId() internal pure override returns(uint256) {
        return 1;
    }

    //******************************************************//
    //                      Getters                         //
    //******************************************************//
    function _baseURI() internal override view returns(string memory){
        return baseTokenURI;
    }
    function totalMinted() public view returns(uint256){
        return _totalMinted();
    }

    //******************************************************//
    //                      Mint                            //
    //******************************************************//
    function _mintTokens(address wallet, uint256 _count) internal{
        _safeMint(wallet, _count);
    }

    function reserve(address _to, uint256 _count) public virtual onlyOwnerOrAdmins {
        require(_totalMinted() + _count <= RESERVE, "Exceeded RESERVE_NFT");
        require(_totalMinted() + _count <= MAX_SUPPLY, "Sold out!");
        _mintTokens(_to, _count);
    }

    //******************************************************//
    //                      Burn                            //
    //******************************************************//
    function burn(uint256 _tokenId) public virtual{
        _burn(_tokenId, true);
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
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public payable
    override(ERC721A, IERC721A)
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}