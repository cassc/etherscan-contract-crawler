// SPDX-License-Identifier: MIT

/**
 * ERC721Keg is a slight modification from the recently created ERC721A standard to meet
 * the Keg Plebs needs.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    struct AddressStats {
        uint128 balance;
        uint128 totalMints;
    }

    string private _name;
    string private _symbol;

    uint256 private currentMintCount = 0;

    mapping(uint256 => address) private _owners;
    mapping(address => AddressStats) private _addressStats;


    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev 
     */
    function totalSupply() public view returns (uint256) {
        return currentMintCount;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) 
        public 
        view 
        virtual 
        override 
        returns (uint256) 
    {
        require(owner != address(0), "ERC721Keg: balance query for the zero address");
        return _addressStats[owner].balance;
    }

    function _totalMints(address owner)
        internal
        view
        returns (uint256) 
    {
        require( owner != address(0),"ERC721Keg: total minted query for the zero address");
        return _addressStats[owner].totalMints;    
    }

    /**
     * @dev Helper function for ownerOf()
     */
    function findOwner(uint256 tokenId) internal view returns (address) 
    {
        require(_exists(tokenId), "ERC721Keg: token does not exist");

        if(_owners[tokenId] != address(0)) return _owners[tokenId]; // check to see if the token is the first of a batch

        uint256 lowest = 0; 
        if(tokenId > 19) { // 20 will be the highest number you can mint per tx; so lowest needs to be at least 1 greater than 19
            lowest = tokenId - 20;
        }
        
        for(uint256 idx = tokenId; idx + 1 > lowest; idx-- ) {
            address owner = _owners[idx];
            if(owner != address(0)) return owner; 
        }

        revert("ERC721Keg: owner not found.");
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address)
    {
        return findOwner(tokenId);
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() external view virtual override returns (string memory) 
    {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() external view virtual override returns (string memory) 
    {
        return _symbol;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) 
        external 
        virtual 
        override 
    {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721Keg: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721Keg: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721Keg: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        external
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721Keg: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual override {
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
            "ERC721Keg: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by who owns them or approved accounts via {approve} or {setApprovalForAll}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId < currentMintCount;
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId, address owner) internal view virtual returns (bool) {
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }


    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 _mintAmt) internal virtual {
        _safeMint(to, _mintAmt, "");
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - there must be `quantity` tokens remaining unminted in the total collection.
     * - `to` cannot be the zero address
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 _mintAmt,
        bytes memory _data
    ) internal {
        require(to != address(0), "ERC721Keg: mint to the zero address");
        uint256 firstTokenId = currentMintCount;

        require(!_exists(firstTokenId), "ERC721K: token already minted"); 
        _beforeTokenTransfer(address(0), to, firstTokenId, _mintAmt); 

        _owners[firstTokenId] = to; // set the id to the minter's addi

        AddressStats memory addressStats = _addressStats[to];
        _addressStats[to] = AddressStats(
            addressStats.balance + uint128(_mintAmt),
            addressStats.totalMints + uint128(_mintAmt)
        );

        uint256 updatedIndex = firstTokenId;

        for(uint128 i = 0; i < _mintAmt; i++) {
            emit Transfer(address(0), to, updatedIndex);

            require(
                _checkOnERC721Received(address(0), to, updatedIndex, _data),
                "ERC721Keg: transfer to non ERC721Receiver implementer"
            );
            updatedIndex++;
        }
        currentMintCount = updatedIndex;
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        address currOwner = findOwner(tokenId);

        require(
            _isApprovedOrOwner(_msgSender(), tokenId, currOwner), 
            "ERC721Keg: transfer not called by owner or approved of."
        );

        require(
            currOwner == from,
            "ERC721Keg: transfer of token that is not own."
        );
        require(to != address(0), "ERC721Keg: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, currOwner);
        _addressStats[from].balance -= 1;
        _addressStats[to].balance += 1;
        _owners[tokenId] = to;

        // check/update the following token id
        if(_owners[tokenId + 1] == address(0)) {
            if(_exists(tokenId + 1)) {
                _owners[tokenId + 1] = currOwner;
            }
        }

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId, address owner) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721Keg: transfer to non ERC721Receiver implementer"
                    );
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

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint mintAmt
    ) internal virtual {}
}