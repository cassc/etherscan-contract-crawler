// from solmate but changed to implement the actual IERC721.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IERC721Metadata} from "src/interfaces/IERC721.sol";

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 is IERC721Metadata {
    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC & ERRORS
    //////////////////////////////////////////////////////////////*/
    error Unauthorized();

    string public name;
    string public symbol;

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id)
        external
        view
        virtual
        returns (address owner)
    {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) external view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) external virtual {
        address owner = _ownerOf[id];

        require(
            msg.sender == owner || isApprovedForAll[owner][msg.sender],
            "NOT_AUTHORIZED"
        );

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved)
        external
        virtual
    {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 id)
        external
        virtual
    {
        _transferFrom(from, to, id);
    }

    function safeTransferFrom(address from, address to, uint256 id)
        external
        virtual
    {
        _transferFrom(from, to, id);

        require(
            to.code.length == 0
                || ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "")
                    == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    )
        external
        virtual
    {
        _transferFrom(from, to, id);

        require(
            to.code.length == 0
                || ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data)
                    == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        external
        view
        virtual
        returns (bool)
    {
        return interfaceId == 0x01ffc9a7
            || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd
            || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL TRANSFER LOGIC
    //////////////////////////////////////////////////////////////*/

    function _transferFrom(address from, address to, uint256 id) private {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        _requireAuthorized(id);
        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0
                || ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "")
                    == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(address to, uint256 id, bytes memory data)
        internal
        virtual
    {
        _mint(to, id);

        require(
            to.code.length == 0
                || ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data)
                    == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _requireAuthorized(uint256 tokenId) internal virtual {
        address owner = _ownerOf[tokenId];
        if (
            !(
                msg.sender == owner || isApprovedForAll[owner][msg.sender]
                    || msg.sender == getApproved[tokenId]
            )
        ) {
            revert Unauthorized();
        }
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata)
        external
        virtual
        returns (bytes4)
    {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}