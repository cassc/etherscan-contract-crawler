// SPDX-License-Identifier: Unlicense
// Creator: CrudeBorne
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

//contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
contract ERC721 is Context, ERC165 {//, IERC721, IERC721Metadata, IERC721Enumerable {
    using Address for address;
    using Strings for uint256;

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    uint256 private currentIndex = 0;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

//    // Base URI
//    string private _baseURI;
//    string private _preRevealURI;

    mapping(uint256 => address) private _ownerships;
    mapping(address => uint256) private _balances;

    address public immutable burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 private numTokensBurned;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(
        string memory name_,
        string memory symbol_
    ) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
    **/
//    function totalSupply() public view override returns (uint256) {
    function totalSupply() public view returns (uint256) {
        return (currentIndex - numTokensBurned);
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
//    function tokenByIndex(uint256 index) public view override returns (uint256) {
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "g");
        require(ownerOf(index) != burnAddress, "b");
        return index;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
//    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "b");
        uint256 numMintedSoFar = totalSupply();
        uint256 tokenIdsIdx = 0;
        address currOwnershipAddr = address(0);
        for (uint256 i = 0; i < numMintedSoFar; i++) {
            address ownership = _ownerships[i];
            if (ownership != address(0)) {
                currOwnershipAddr = ownership;
            }
            if (currOwnershipAddr == owner) {
                if (tokenIdsIdx == index) {
                    return i;
                }
                tokenIdsIdx++;
            }
        }
        revert("u");
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
//    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        interfaceId == type(IERC721Enumerable).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
//    function balanceOf(address owner) public view override returns (uint256) {
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "0");
        return uint256(_balances[owner]);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
//    function ownerOf(uint256 tokenId) public view override returns (address) {
    function ownerOf(uint256 tokenId) public view returns (address) {
        //        return ownershipOf(tokenId);

        require(tokenId < currentIndex, "t");

        for (uint256 curr = tokenId; curr >= 0; curr--) {
            address ownership = _ownerships[curr];
            if (ownership != address(0)) {
                return ownership;
            }
        }

        revert("o");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
//    function name() public view virtual override returns (string memory) {
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
//    function symbol() public view virtual override returns (string memory) {
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
    * @dev See {IERC721-approve}.
     */
//    function approve(address to, uint256 tokenId) public override {
    function approve(address to, uint256 tokenId) public {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "o");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "a"
        );

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
//    function getApproved(uint256 tokenId) public view override returns (address) {
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "a");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
//    function setApprovalForAll(address operator, bool approved) public override {
    function setApprovalForAll(address operator, bool approved) public {
//        require(operator != _msgSender() && !(operatorRestrict[operator]), "a;r");
        require(operator != _msgSender(), "a");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
//    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
//    ) public override {
    ) public {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
//    ) public override {
    ) public {
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
//    ) public override {
    ) public {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "z"
        );
    }

    function burnToken(uint256 tokenId) public {
        _transfer(ownerOf(tokenId), burnAddress, tokenId);
        numTokensBurned++;
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return (tokenId < currentIndex && ownerOf(tokenId) != burnAddress);
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, "");
    }

    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity);
        require(_checkOnERC721Received(address(0), to, currentIndex - 1, _data), "z");
    }

    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = currentIndex;
        require(to != address(0), "0");
        // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
        require(!_exists(startTokenId), "a");

        _balances[to] = _balances[to] + quantity;
        _ownerships[startTokenId] = to;

        uint256 updatedIndex = startTokenId;

        for (uint256 i = 0; i < quantity; i++) {
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

        require(isApprovedOrOwner && prevOwnership == from, "a");
        require(prevOwnership == from, "o");
        require(to != address(0), "0");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership);

        _balances[from] -= 1;
        _balances[to] += 1;
        _ownerships[tokenId] = to;

        // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
        // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
        uint256 nextTokenId = tokenId + 1;
        if (_ownerships[nextTokenId] == address(0)) {
            if (_exists(nextTokenId)) {
                _ownerships[nextTokenId] = prevOwnership;
            }
        }

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