// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/interfaces/IERC721AQueryable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";


contract z00tzAnchorClub is  DefaultOperatorFilterer, ERC721Enumerable, AccessControl {
    
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string public _URI;



    
    constructor() ERC721("z00tz Anchor Club", "ZAC") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721,IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721,IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721,IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721,IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721,IERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI,Strings.toString(_tokenId+1),".json"))
            : "";
    }

    function safeMint(address to, uint256 tokenId) public onlyRole(MINTER_ROLE) {
        
        _safeMint(to,tokenId);

    }

    function safeBurn(uint256 tokenId) public onlyRole(MINTER_ROLE) {
        _burn(tokenId);
    }


   
    function _baseURI() internal view override returns (string memory) {
        return _URI;
    }
    
    function setBaseURI(string memory uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _URI = uri;
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}