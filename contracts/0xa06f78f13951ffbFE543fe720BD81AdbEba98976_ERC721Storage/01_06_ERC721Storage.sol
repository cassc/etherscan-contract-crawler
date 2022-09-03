// SPDX-License-Identifier: Unlicense
// Creator: 0xVeryBased

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract ERC721Storage is Ownable {
    using Address for address;
    using Strings for uint256;

    // Tracker for calculating number minted/total supply and assigning token indices
    uint256 private currentIndex = 0;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Token owners and token balances
    mapping(uint256 => address) private _ownerships;
    mapping(address => uint256) private _balances;

    // Burn address and counter
    address public immutable burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 private numTokensBurned;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping from operators to whether or not they are restricted
    mapping(address => bool) private _operatorRestrictions;
    // Bool indicating whether one can still restrict an operator or not
    bool private _canRestrict;

    ERC721TopLevelProto public topLevelContract;

    constructor(
        string memory name_,
        string memory symbol_
    ) {
        _name = name_;
        _symbol = symbol_;
//        topLevelContract = ERC721TopLevelProto(msg.sender);
    }

    function setTopLevelContract(address _topLevelContract) public onlyOwner {
        topLevelContract = ERC721TopLevelProto(_topLevelContract);
        transferOwnership(_topLevelContract);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
    **/
    function storage_totalSupply() public view returns (uint256) {
        return (currentIndex - numTokensBurned);
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
    **/
    function storage_tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < storage_totalSupply(), "g");
        require(storage_ownerOf(index) != burnAddress, "b");
        return index;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
    **/
    function storage_tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < storage_balanceOf(owner), "b");
        uint256 numMintedSoFar = storage_totalSupply();
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

    function storage_tokenOfOwnerByIndexStepped(address owner, uint256 index, uint256 lastToken, uint256 lastIndex) public view returns (uint256) {
        require(index < storage_balanceOf(owner), "b");
        uint256 numTokenIds = currentIndex;
        uint256 tokenIdsIdx = ((lastIndex == 0) ? 0 : (lastIndex + 1));
        address currOwnershipAddr = address(0);
        for (uint256 i = ((lastToken == 0) ? 0 : (lastToken + 1)); i < numTokenIds; i++) {
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

//    /**
//     * @dev See {IERC165-supportsInterface}.
//    **/
//    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
//        return (interfaceId == type(IERC721).interfaceId ||
//        interfaceId == type(IERC721Metadata).interfaceId ||
//        interfaceId == type(IERC721Enumerable).interfaceId ||
//        super.supportsInterface(interfaceId));
//    }

    /**
     * @dev See {IERC721-balanceOf}.
    **/
    function storage_balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "0");
        return uint256(_balances[owner]);
    }

    /**
     * @dev See {IERC721-ownerOf}.
    **/
    function storage_ownerOf(uint256 tokenId) public view returns (address) {
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
    **/
    function storage_name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
    **/
    function storage_symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721-approve}.
    **/
    function storage_approve(address to, uint256 tokenId, address msgSender) public onlyOwner {
        address owner = ERC721Storage.storage_ownerOf(tokenId);
        require(to != owner, "o");

        require(
            msgSender == owner || storage_isApprovedForAll(owner, msgSender),
            "a"
        );

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
    **/
    function storage_getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "a");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
    **/
    function storage_setApprovalForAll(address operator, bool approved, address msgSender) public {
        //        require(operator != msgSender && !(operatorRestrict[operator]), "a;r");
        require(operator != msgSender, "a");

        _operatorApprovals[msgSender][operator] = approved;
        topLevelContract.emitApprovalForAll(msgSender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
    **/
    function storage_isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
    **/
    function storage_transferFrom(
        address from,
        address to,
        uint256 tokenId,
        address msgSender
    ) public onlyOwner {
        _transfer(from, to, tokenId, msgSender);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
    **/
    function storage_safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        address msgSender
    ) public onlyOwner {
        storage_safeTransferFrom(from, to, tokenId, "", msgSender);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
    **/
    function storage_safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data,
        address msgSender
    ) public onlyOwner {
        _transfer(from, to, tokenId, msgSender);
        require(
            _checkOnERC721Received(from, to, tokenId, _data, msgSender),
            "z"
        );
    }

    /**
     * @dev Burns a token to the designated burn address
    **/
    function storage_burnToken(uint256 tokenId, address msgSender) public onlyOwner {
        _transfer(storage_ownerOf(tokenId), burnAddress, tokenId, msgSender);
        numTokensBurned++;
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
    **/
    function _exists(uint256 tokenId) internal view returns (bool) {
        return (tokenId < currentIndex && storage_ownerOf(tokenId) != burnAddress);
    }

    function storage_exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function storage_safeMint(address to, uint256 quantity, address msgSender) public onlyOwner {
        storage_safeMint(to, quantity, "", msgSender);
    }

    function storage_safeMint(
        address to,
        uint256 quantity,
        bytes memory _data,
        address msgSender
    ) public onlyOwner {
        storage_mint(to, quantity);
        require(_checkOnERC721Received(address(0), to, currentIndex - 1, _data, msgSender), "z");
    }

    function storage_mint(address to, uint256 quantity) public onlyOwner {
        uint256 startTokenId = currentIndex;
        require(to != address(0), "0");
        // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
        require(!_exists(startTokenId), "a");

        _balances[to] = _balances[to] + quantity;
        _ownerships[startTokenId] = to;

        uint256 updatedIndex = startTokenId;

        for (uint256 i = 0; i < quantity; i++) {
            topLevelContract.emitTransfer(address(0), to, updatedIndex);
            updatedIndex++;
        }

        currentIndex = updatedIndex;
    }

    function storage_contractURI(string memory _description, string memory _img, string memory _self) public view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;utf8,{\"name\":\"", storage_name(),"\",",
                "\"description\":\"", _description, "\",",
                "\"image\":\"", _img, "\",",
                "\"external_link\":\"https://crudeborne.wtf\",",
                "\"seller_fee_basis_points\":420,\"fee_recipient\":\"",
                _self, "\"}"
            )
        );
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId,
        address msgSender
    ) private {
        address prevOwnership = storage_ownerOf(tokenId);

        bool isApprovedOrOwner = (msgSender == prevOwnership ||
        storage_getApproved(tokenId) == msgSender ||
        storage_isApprovedForAll(prevOwnership, msgSender));

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

        topLevelContract.emitTransfer(from, to, tokenId);
    }

    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        topLevelContract.emitApproval(owner, to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data,
        address msgSender
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msgSender, from, tokenId, _data) returns (bytes4 retVal) {
                return retVal == IERC721Receiver(to).onERC721Received.selector;
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

////////////////////

abstract contract ERC721TopLevelProto {
    function emitTransfer(address from, address to, uint256 tokenId) public virtual;
    function emitApproval(address owner, address approved, uint256 tokenId) public virtual;
    function emitApprovalForAll(address owner, address operator, bool approved) public virtual;
}

////////////////////////////////////////