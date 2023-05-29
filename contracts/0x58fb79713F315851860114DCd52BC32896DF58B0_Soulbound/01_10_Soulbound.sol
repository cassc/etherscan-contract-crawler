// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Soulbound is Context, Ownable, ERC165, IERC721, IERC721Metadata {

    error DisabledForSoulbound();
    error OnePerAddress();
    error OnlyUkraines();
    error MintNotOpen();
    
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping owner address to whether or not token has been minted
    mapping(address => bool) private _bound;

    bool public mintOpen = false;

    address public UKRAINES;

    string private _metadataURI;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_, string memory metadataURI) {
        _name = name_;
        _symbol = symbol_;
        _metadataURI = metadataURI;
    }

    function toggleMintOpen() public onlyOwner {
        mintOpen = !mintOpen;
    }

    function setUkraines(address addr) public onlyOwner {
        UKRAINES = addr;
    }

    function setMetadataURI(string memory metadataURI) public onlyOwner {
        _metadataURI = metadataURI;
    }

    function redeem(address addr) public {
        if (_msgSender() != UKRAINES) {
            revert OnlyUkraines();
        }
        _bound[_msgSender()] = false;
        emit Transfer(addr, address(0), address_to_int(addr));
    }

    function mint() external payable {
        if (_bound[_msgSender()]){
            revert OnePerAddress();
        }
        if (!mintOpen) {
            revert MintNotOpen();
        }
        _bound[_msgSender()] = true;
        emit Transfer(address(0), _msgSender(), address_to_int(_msgSender()));
    }

    function bound(address addr) public view returns (bool) {
        return _bound[addr];
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        return bool_to_int(_bound[owner]);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return int_to_address(tokenId);
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256) public view virtual override returns (string memory) {
        return _metadataURI;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address, uint256) public virtual override {
        revert DisabledForSoulbound();
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256) public view virtual override returns (address) {
        return address(0);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address, bool) public virtual override {
        revert DisabledForSoulbound();
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address, address) public view virtual override returns (bool) {
        return false;
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address, address, uint256) public virtual override {
        //solhint-disable-next-line max-line-length
        revert DisabledForSoulbound();
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address, address, uint256) public virtual override {
        revert DisabledForSoulbound();
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address, address, uint256, bytes memory) public virtual override {
        revert DisabledForSoulbound();
    }

    /**
     * @dev Return integer from address - used for knowing which tokenID is owned by a particular address.
     */
    function address_to_int(address a) internal pure returns (uint256) {
        return uint256(uint160(a));
    }

    /**
     * @dev Return address from integer - used for knowing which address owns a particular tokenId.
     */
    function int_to_address(uint256 i) internal pure returns (address) {
        return address(uint160(i));
    }

    function bool_to_int(bool x) internal pure returns (uint r) {
        assembly { r := x }
    }
}