// SPDX-License-Identifier: Unlicense
// Creator: 0xYeety/YEETY.eth - Co-Founder/CTO, Virtue Labs

pragma solidity ^0.8.17;

import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "lib/openzeppelin-contracts/contracts/utils/Address.sol";
import "lib/openzeppelin-contracts/contracts/utils/Context.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";

contract ERC721Keys is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    event PseudoTransfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event PseudoApproval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    using Address for address;
    using Strings for uint256;

    uint256 private currentIndex = 1;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Base(d) URI
    string internal _basedURI;
    string internal _preRevealURI;

    mapping(uint256 => address) private _ownerships;

    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    //////////

    constructor(
        string memory name_,
        string memory symbol_
    ) {
        _name = name_;
        _symbol = symbol_;
    }

    //////////

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
    **/
    function totalSupply() public view override returns (uint256) {
        return (currentIndex - 1);
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        require(index <= totalSupply() && index > 0, "g");
        return index;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        require(index < balanceOf(owner), "b");
        uint256 supply = totalSupply();
        uint256 curIndex = 0;
        for (uint256 i = 1; i <= supply; i++) {
            if (_ownerships[i] == owner) {
                if (curIndex == index) {
                    return i;
                }
                curIndex++;
            }
        }
        revert("u");
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        interfaceId == type(IERC721Enumerable).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "0");
        return uint256(_balances[owner]);
    }

    /**
     * @dev See {IERC721-ownerOf}.
    **/
    function ownerOf(uint256 tokenId) public view override returns (address) {
        require(tokenId < currentIndex && tokenId > 0, "t");
        return _ownerships[tokenId];
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
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "z");

        if (bytes(_basedURI).length > 0) {
            return string(abi.encodePacked(_basedURI, "/", tokenId.toString(), ".json"));
        }
        else {
            return _preRevealURI;
        }
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `basedURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function basedURI() public view virtual returns (string memory) {
        return _basedURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBasedURI(string memory basedURI_) internal virtual {
        _basedURI = basedURI_;
    }

    function preRevealURI() public view virtual returns (string memory) {
        return _preRevealURI;
    }

    function _setPreRevealURI(string memory preRevealURI_) internal virtual {
        _preRevealURI = preRevealURI_;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Keys.ownerOf(tokenId);
        require(to != owner, "o");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "a"
        );

        _approve(to, tokenId, owner);
    }

    function approveForSelf(address to, uint256 tokenId) internal {
        address owner = ERC721Keys.ownerOf(tokenId);
        require(to != owner, "o");

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "a");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "a");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function setApprovalForSelf(address operator, bool approved) internal {
        _operatorApprovals[address(this)][operator] = approved;
        emit ApprovalForAll(address(this), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "z"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return (tokenId < currentIndex && tokenId > 0);
    }

    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = currentIndex;
        require(to != address(0), "0");
        // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
        require(!_exists(startTokenId), "a");

        _balances[to] = _balances[to] + quantity;

        uint256 updatedIndex = startTokenId;

        for (uint256 i = 0; i < quantity; i++) {
            _ownerships[updatedIndex] = to;
            emit Transfer(address(0), to, updatedIndex);
            updatedIndex++;
        }

        currentIndex = updatedIndex;
    }

    /******************/

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        address prevOwnership = ownerOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership ||
        getApproved(tokenId) == _msgSender() ||
        isApprovedForAll(prevOwnership, _msgSender()));

        require(isApprovedOrOwner, "a");

        require(prevOwnership == from, "o");
        require(to != address(0), "0");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership);

        _balances[from] -= 1;
        _balances[to] += 1;
        _ownerships[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _transferToSelf(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        address prevOwnership = ownerOf(tokenId);

        require(prevOwnership == from, "o");
        require(to != address(0), "0");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership);

        _balances[from] -= 1;
        _balances[to] += 1;
        _ownerships[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /********/

//    function setRelatedApprovalForAll(address owner) internal {
//        _operatorApprovals[owner][address(this)] = true;
//    }

    /******************/

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("z");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}

////////////////////////////////////////