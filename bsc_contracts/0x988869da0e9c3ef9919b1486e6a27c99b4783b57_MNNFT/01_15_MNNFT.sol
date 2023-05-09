// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MNNFT is  ERC721, ERC721Enumerable, AccessControl {

    string public baseTokenURI;

    bytes32 public constant M_ROLE = keccak256("M_ROLE");

    string private _name;
    string private _symbol;

    constructor() ERC721 ("MNNFT", "MNNFT")  {
        _name = "MNNFT";
        _symbol = "MNNFT";
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(M_ROLE, _msgSender());
        baseTokenURI = "";
    }

    function tokensOfOwner(address owner) public view virtual returns (uint256[] memory) {
        uint256 length = ERC721.balanceOf(owner);
        uint256[] memory values = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = tokenOfOwnerByIndex(owner,i);
        }
        return values;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function mint(address to, uint256 tokenId) external onlyRole(M_ROLE) {
        _safeMint(to, tokenId);
    }

    function burn(uint256 tokenId) public virtual onlyRole(M_ROLE) {
        require(ERC721.ownerOf(tokenId) == msg.sender, "ERC721: transfer from incorrect owner");
        _burn(tokenId);
    }

    function transfer(address to, uint256 tokenId) public virtual {
        _transfer(_msgSender(),to,tokenId);
    }

    /// @dev Returns an URI for a given token ID
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @dev Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI) external onlyRole(DEFAULT_ADMIN_ROLE)  {
        baseTokenURI = _baseTokenURI;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Enumerable).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || interfaceId == type(AccessControl).interfaceId
            || interfaceId == type(IERC165).interfaceId
            || super.supportsInterface(interfaceId);
    }
}