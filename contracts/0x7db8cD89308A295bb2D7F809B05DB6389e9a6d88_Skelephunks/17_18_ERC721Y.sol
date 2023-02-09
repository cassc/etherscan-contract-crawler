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

contract ERC721Y is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using Address for address;
    using Strings for uint256;

    uint256 private currentIndex = 1;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Base URI
    string internal _basedURI;
    string internal _preRevealURI;

    mapping(uint => uint) private _availableTokens;
    uint256 private _numAvailableTokens;
    uint256 immutable _maxSupply;

    struct MintInfo {
        address minter;
        uint64 timeMinted;
    }

    struct TokenInfo {
        address owner;
        uint96 auxData;
    }

    mapping(uint256 => MintInfo) private _minters;
//    mapping(uint256 => address) private _ownerships;
    mapping(uint256 => TokenInfo) private _ownerships;
    mapping(address => uint256) private _balances;
    mapping(uint256 => MintInfo) private _mintOrdering;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxTokens_
    ) {
        _name = name_;
        _symbol = symbol_;
        _maxSupply = maxTokens_;
        _numAvailableTokens = maxTokens_;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
    **/
    function totalSupply() public view override returns (uint256) {
        return _maxSupply - _numAvailableTokens;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        require(index > 0, "i0");
        uint256 pseudoIndex = index - 1;
        uint256 supply = totalSupply();
        require(pseudoIndex < supply, "g");
        uint256 curIndex = 0;
        for (uint256 i = 0; i < _maxSupply; i++) {
            if (_ownerships[i].owner != address(0)) {
                if (curIndex == pseudoIndex) {
//                    return i;
                    return (i + 1);
                }
                curIndex++;
            }
        }
        revert("u");
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        require(index < balanceOf(owner), "b");
        uint256 curIndex = 0;
        for (uint256 i = 0; i < _maxSupply; i++) {
            if (_ownerships[i].owner == owner) {
                if (curIndex == index) {
//                    return i;
                    return (i + 1);
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
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "e");
        return _ownerships[tokenId - 1].owner;
    }

    function gadOf(uint256 tokenId) internal view returns (uint256) {
        require(_exists(tokenId), "e");
        return uint256(_ownerships[tokenId - 1].auxData);
    }

    function setGAD(uint256 tokenId, uint256 newGAD) internal {
        require(ownerOf(tokenId) == msg.sender, "e");
        _ownerships[tokenId - 1].auxData = uint96(newGAD);
    }

    /**
     * @dev gets the address that minted a token
    **/
    function minterOf(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "e");
        return _minters[tokenId - 1].minter;
    }

    function mintedAt(uint256 tokenId) public view returns (uint64) {
        require(_exists(tokenId), "e");
        return _minters[tokenId - 1].timeMinted;
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
        address owner = ERC721Y.ownerOf(tokenId);
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
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "a");
        return _tokenApprovals[tokenId - 1];
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
        if (tokenId == 0) { return false; }
        return (_ownerships[tokenId - 1].owner != address(0));
    }

    /******************/

    function _mintIdWithoutBalanceUpdate(address to, uint256 tokenId, uint256 gad) private {
        _ownerships[tokenId].owner = to;
        _ownerships[tokenId].auxData = uint96(gad);
        _minters[tokenId].minter = to;
        _minters[tokenId].timeMinted = uint64(block.timestamp);
        emit Transfer(address(0), to, tokenId + 1);
    }

    function _mintRandom(address to, uint _quantity, uint256 gad) internal virtual returns (uint256[] memory) {
        require(to != address(0), "0");
        require(_quantity > 0, "1");

        uint256[] memory toReturn = new uint256[](_quantity);

        uint updatedNumAvailableTokens = _numAvailableTokens;

        uint256 randomNum;
        for (uint256 i = 0; i < _quantity; i++) { // Do this ++ unchecked?
            uint256 modPos = i%16;
            if (modPos == 0) {
                randomNum = getRandomAvailableTokenId(to, updatedNumAvailableTokens);
            }

            uint256 randomIndex = (randomNum>>(modPos*16)) % updatedNumAvailableTokens;
            uint256 tokenId = getAvailableTokenAtIndex(randomIndex, updatedNumAvailableTokens);

            _mintIdWithoutBalanceUpdate(to, tokenId, gad);
            toReturn[i] = (tokenId + 1);
            updatedNumAvailableTokens--;
        }

        _numAvailableTokens = updatedNumAvailableTokens;
        _balances[to] += _quantity;

        _mintOrdering[currentIndex].minter = to;
        _mintOrdering[currentIndex].timeMinted = uint64(block.timestamp);
        currentIndex += _quantity;

        return toReturn;
    }

    function getRandomAvailableTokenId(
        address to,
        uint updatedNumAvailableTokens
    ) internal view returns (uint256) {
        uint256 randomNum = uint256(
            keccak256(
                abi.encode(
                    to,
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - 1),
                    address(this),
                    updatedNumAvailableTokens
                )
            )
        );
        return randomNum;
//        uint256 randomIndex = randomNum % updatedNumAvailableTokens;
//        return getAvailableTokenAtIndex(randomIndex, updatedNumAvailableTokens);
    }

    // Implements https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle. Code taken from CryptoPhunksV2
    function getAvailableTokenAtIndex(
        uint256 indexToUse,
        uint256 updatedNumAvailableTokens
    ) internal returns (uint256) {
        uint256 valAtIndex = _availableTokens[indexToUse];
        uint256 result;
        if (valAtIndex == 0) {
            // This means the index itself is still an available token
            result = indexToUse;
        } else {
            // This means the index itself is not an available token, but the val at that index is.
            result = valAtIndex;
        }

        uint256 lastIndex = updatedNumAvailableTokens - 1;
        if (indexToUse != lastIndex) {
            // Replace the value at indexToUse, now that it's been used.
            // Replace it with the data from the last index in the array, since we are going to decrease the array size afterwards.
            uint256 lastValInArray = _availableTokens[lastIndex];
            if (lastValInArray == 0) {
                // This means the index itself is still an available token
                _availableTokens[indexToUse] = lastIndex;
            } else {
                // This means the index itself is not an available token, but the val at that index is.
                _availableTokens[indexToUse] = lastValInArray;
                // Gas refund courtsey of @dievardump
                delete _availableTokens[lastIndex];
            }
        }

        return result;
    }

    function getMintOrderInfoByIndex(uint256 index) private view returns (MintInfo memory) {
        if (index > totalSupply()) {
            return _mintOrdering[0];
        }

        for (uint256 i = index; i > 0; i--) {
            if (_mintOrdering[i].minter != address(0)) {
                return _mintOrdering[i];
            }
        }

        return _mintOrdering[0];

//        revert("u");
    }

    function getMinterByOrderIndex(uint256 index) public view returns (address) {
        MintInfo memory info = getMintOrderInfoByIndex(index);
        return info.minter;
    }

    function getMintTimeByOrderIndex(uint256 index) public view returns (uint64) {
        MintInfo memory info = getMintOrderInfoByIndex(index);
        return info.timeMinted;
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
        _ownerships[tokenId - 1].owner = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId - 1] = to;
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