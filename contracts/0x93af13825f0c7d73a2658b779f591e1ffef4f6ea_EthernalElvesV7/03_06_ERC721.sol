// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

/// @notice Modern and gas efficient ERC-721 + ERC-20/EIP-2612-like implementation,
/// including the MetaData, and partially, Enumerable extensions.
contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    address implementation_;
    address public admin;

    /*///////////////////////////////////////////////////////////////
                             ERC-721 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;
    uint256 public maxSupply;

    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                             VIEW FUNCTION
    //////////////////////////////////////////////////////////////*/

    function owner() external view returns (address) {
        return admin;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC-20-LIKE LOGIC
    //////////////////////////////////////////////////////////////*/

    function transfer(address to, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId], "NOT_OWNER");

        _transfer(msg.sender, to, tokenId);
    }

    /*///////////////////////////////////////////////////////////////
                              ERC-721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        external
        pure
        returns (bool supported)
    {
        supported = interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }

    function approve(address spender, uint256 tokenId) external {
        address owner_ = ownerOf[tokenId];

        require(
            msg.sender == owner_ || isApprovedForAll[owner_][msg.sender],
            "NOT_APPROVED"
        );

        getApproved[tokenId] = spender;

        emit Approval(owner_, spender, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        address owner_ = ownerOf[tokenId];

        require(
            msg.sender == owner_ ||
                msg.sender == getApproved[tokenId] ||
                isApprovedForAll[owner_][msg.sender],
            "NOT_APPROVED"
        );

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        transferFrom(from, to, tokenId);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }


    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, tokenId);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
    /*
        function safeTransferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, "");
    }
    
    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        transferFrom(from, to, tokenId);

        if (to.code.length != 0) {
            // selector = `onERC721Received(address,address,uint,bytes)`
            (, bytes memory returned) = to.staticcall(
                abi.encodeWithSelector(
                    0x150b7a02,
                    msg.sender,
                    from, 
                    tokenId,
                    data
                )
            );

            bytes4 selector = abi.decode(returned, (bytes4));

            require(selector == 0x150b7a02, "NOT_ERC721_RECEIVER");
        }
    }*/

    /*///////////////////////////////////////////////////////////////
                          INTERNAL UTILS
    //////////////////////////////////////////////////////////////*/

    function _transfer(address from, address to, uint256 tokenId) internal {
        
        require(ownerOf[tokenId] == from);

        balanceOf[from]--;
        balanceOf[to]++;

        delete getApproved[tokenId];

        ownerOf[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal {
        require(ownerOf[tokenId] == address(0), "ALREADY_MINTED");
        require(totalSupply++ <= maxSupply, "MAX SUPPLY REACHED");

        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal {
        address owner_ = ownerOf[tokenId];

        require(ownerOf[tokenId] != address(0), "NOT_MINTED");

        totalSupply--;
        balanceOf[owner_]--;

        delete ownerOf[tokenId];

        emit Transfer(owner_, address(0), tokenId);
    }
}


/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
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