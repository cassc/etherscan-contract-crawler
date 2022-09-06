// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title ERC721s
/// @notice Custom ERC721. Batch minting. Timestamps for ownerships. 
///         Inspiration: ERC721A by Chiru Labs, Solmate by Rari Capital
/// @author filio.eth (https://twitter.com/filmakarov)
/// @dev Check the repo and readme at https://github.com/filmakarov/erc721s 

abstract contract ERC721S {

    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;
    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    uint256 public nextTokenIndex;
    mapping(uint256 => uint256) internal _packedOwnerships;
    mapping(uint256 => address) internal _tokenApprovals;
    mapping(address => mapping(address => bool)) internal _operatorApprovals;
    mapping(address => uint256) internal _balanceOf;
    mapping(uint256 => bool) public isBurned;
    uint256 public burnedCounter;

    uint256 private constant ADDRESS_BITMASK = (1 << 160) - 1;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        nextTokenIndex = _startTokenIndex();
    }

    /*///////////////////////////////////////////////////////////////
                              APPROVALS LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf(id);
        require(msg.sender == owner || _operatorApprovals[owner][msg.sender], "ERC721S: Not authorized to approve");
        _tokenApprovals[id] = spender;
        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId) public view virtual returns (address) {
        require(_exists(tokenId), "ERC721S: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /*///////////////////////////////////////////////////////////////
                              OWNERSHIPS
    //////////////////////////////////////////////////////////////*/

    function _exists(uint256 id) internal view returns (bool) {
        return (id < nextTokenIndex && !isBurned[id] && id >= _startTokenIndex());
    }

    function ownerOf(uint256 id) public view returns (address) {
        return address(uint160( _packedOwnershipOf(id) ));
    }

    function _packedOwnershipOf(uint256 id) internal view returns (uint256) {
        if (id >= _startTokenIndex()) {
            if (id<nextTokenIndex) {
                if (!isBurned[id]) { 
                    uint256 curr = id;
                    unchecked {
                        uint256 packed = _packedOwnerships[curr];
                        
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
            }
        }
        revert('ERC721S: Token does not exist');
    }

    function _packOwnership(address owner) internal virtual returns (uint256 result) {
        assembly {
            owner := and(owner, ADDRESS_BITMASK)
            result := or(owner, shl(160, timestamp()))
        }
    }

    /*///////////////////////////////////////////////////////////////
                              TRANSFERS LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {

        uint256 prevOwnership = _packedOwnershipOf(id);
        
        require(from == address(uint160(prevOwnership)), "ERC721S: From is not the owner");
        require(to != address(0), "ERC721S: Can not transfer to 0 address");

        // msg.sender should be authorized to transfer
        // i.e. msg.sender should be owner, approved or unlocker
        require(
            msg.sender == from || 
            msg.sender == getApproved(id) || isApprovedForAll(from, msg.sender), 
            "ERC721S: Not authorized to transfer"
        );

        _beforeTokenTransfers(from, to, id, 1);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;
            _balanceOf[to]++;
        }

        _packedOwnerships[id] = _packOwnership(to);

        uint256 nextId = id+1;

        if (_exists(nextId)) {
            // _packedOwnerships[nextId] == 0 is true only if the token ownership has not been initialized
            // burned token has non-zero ownership and if it was burned, the next token after burned one
            // was initialized 
            if (_packedOwnerships[nextId] == 0) {
                _packedOwnerships[nextId] = prevOwnership;
            }
        }     

        delete _tokenApprovals[id];

        emit Transfer(from, to, id);
        _afterTokenTransfers(from, to, id, 1);
    } 

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "ERC721S: Transfer to unsafe recepient"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "ERC721S: Transfer to unsafe recepient"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              Views
    //////////////////////////////////////////////////////////////*/

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ERC721S: BalanceOf query for zero address");
        return _balanceOf[owner];
    }

    function totalSupply() public view returns (uint256) {
        return totalMinted() - burnedCounter;
    }

    function totalMinted() public view returns (uint256) {
        return nextTokenIndex - _startTokenIndex();
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     * Inspired by ERC721A
     */
    function _startTokenIndex() internal view virtual returns (uint256) {
        return 0;
    }

    function _mint(address to, uint256 qty) internal virtual {
        require(to != address(0), "ERC721S: Can not mint to 0 address");
        require(qty != 0, "ERC721S: Can not mint 0 tokens");

        uint256 startTokenIndex = nextTokenIndex;

        _beforeTokenTransfers(address(0), to, startTokenIndex, qty);

        // put just the first owner in the batch
        _packedOwnerships[nextTokenIndex] = _packOwnership(to);

        // Counter overflow is incredibly unrealistic here.
        unchecked {
                nextTokenIndex += qty;
            }
          
        //balanceOf change thru assembly
        assembly {
            mstore(0, to)
            mstore(32, _balanceOf.slot)
            let hash := keccak256(0, 64)
            sstore(hash, add(sload(hash), qty))
        } 

        for (uint256 i=startTokenIndex; i<nextTokenIndex; i++) {
            emit Transfer(address(0), to, i);
        }

        _afterTokenTransfers(address(0), to, startTokenIndex, qty);
        
    }

    function _safeMint(address to, uint256 qty) internal virtual {
        _mint(to, qty);
        
        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), nextTokenIndex-qty, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "ERC721S: Mint to unsafe recepient"
        );
    }

    function _safeMint(
        address to,
        uint256 qty,
        bytes memory data
    ) internal virtual {
        _mint(to, qty);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), nextTokenIndex-qty, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "ERC721S: Mint to unsafe recepient"
        );
    }

    /*///////////////////////////////////////////////////////////////
                       BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _burn(uint256 id) internal virtual {
        
        address owner = ownerOf(id);
        uint256 prevOwnership = _packedOwnershipOf(id);

        _beforeTokenTransfers(owner, address(0), id, 1);

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }
        
        _packedOwnerships[id] = _packOwnership(address(0)); // thus we have time of burning the token

        isBurned[id] = true;
        burnedCounter++;

        uint256 nextId = id+1;
        if (_packedOwnerships[nextId] == 0) {  //if that was not the last token of batch
            if (_exists(nextId)) { //and the next token exists (was minted) and has not been burned
                _packedOwnerships[nextId] = prevOwnership; //explicitly set the owner for that token
            }
        }
        
        delete _tokenApprovals[id];

        emit Transfer(owner, address(0), id);
        _afterTokenTransfers(owner, address(0), id, 1);
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                              HOOKS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

}

/*///////////////////////////////////////////////////////////////
                              TOKEN RECEIVER
//////////////////////////////////////////////////////////////*/

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}