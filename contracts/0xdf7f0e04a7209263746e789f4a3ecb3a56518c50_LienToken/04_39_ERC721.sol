// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC721} from "core/interfaces/IERC721.sol";

import {Initializable} from "core/utils/Initializable.sol";

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 is Initializable, IERC721 {
  /* //////////////////////////////////////////////////////////////
    METADATA STORAGE/LOGIC
  ////////////////////////////////////////////////////////////// */

  uint256 private constant ERC721_SLOT =
    uint256(keccak256("xyz.astaria.ERC721.storage.location")) - 1;
  struct ERC721Storage {
    string name;
    string symbol;
    mapping(uint256 => address) _ownerOf;
    mapping(address => uint256) _balanceOf;
    mapping(uint256 => address) getApproved;
    mapping(address => mapping(address => bool)) isApprovedForAll;
  }

  function getApproved(uint256 tokenId) public view returns (address) {
    return _loadERC721Slot().getApproved[tokenId];
  }

  function isApprovedForAll(address owner, address operator)
    public
    view
    returns (bool)
  {
    return _loadERC721Slot().isApprovedForAll[owner][operator];
  }

  function tokenURI(uint256 id) external view virtual returns (string memory);

  /* //////////////////////////////////////////////////////////////
    ERC721 BALANCE/OWNER STORAGE
  ////////////////////////////////////////////////////////////// */

  function _loadERC721Slot() internal pure returns (ERC721Storage storage s) {
    uint256 slot = ERC721_SLOT;

    assembly {
      s.slot := slot
    }
  }

  function ownerOf(uint256 id) public view virtual returns (address owner) {
    require(
      (owner = _loadERC721Slot()._ownerOf[id]) != address(0),
      "NOT_MINTED"
    );
  }

  function balanceOf(address owner) public view virtual returns (uint256) {
    require(owner != address(0), "ZERO_ADDRESS");

    return _loadERC721Slot()._balanceOf[owner];
  }

  /* //////////////////////////////////////////////////////////////
  INITIALIZATION LOGIC
  ////////////////////////////////////////////////////////////// */

  function __initERC721(string memory _name, string memory _symbol) internal {
    ERC721Storage storage s = _loadERC721Slot();
    s.name = _name;
    s.symbol = _symbol;
  }

  /* //////////////////////////////////////////////////////////////
  ERC721 LOGIC
  ////////////////////////////////////////////////////////////// */

  function name() public view returns (string memory) {
    return _loadERC721Slot().name;
  }

  function symbol() public view returns (string memory) {
    return _loadERC721Slot().symbol;
  }

  function approve(address spender, uint256 id) external virtual {
    ERC721Storage storage s = _loadERC721Slot();
    address owner = s._ownerOf[id];
    require(
      msg.sender == owner || s.isApprovedForAll[owner][msg.sender],
      "NOT_AUTHORIZED"
    );

    s.getApproved[id] = spender;

    emit Approval(owner, spender, id);
  }

  function setApprovalForAll(address operator, bool approved) external virtual {
    _loadERC721Slot().isApprovedForAll[msg.sender][operator] = approved;

    emit ApprovalForAll(msg.sender, operator, approved);
  }

  function transferFrom(
    address from,
    address to,
    uint256 id
  ) public virtual override(IERC721) {
    ERC721Storage storage s = _loadERC721Slot();

    require(from == s._ownerOf[id], "WRONG_FROM");

    require(to != address(0), "INVALID_RECIPIENT");

    require(
      msg.sender == from ||
        s.isApprovedForAll[from][msg.sender] ||
        msg.sender == s.getApproved[id],
      "NOT_AUTHORIZED"
    );
    _transfer(from, to, id);
  }

  function _transfer(
    address from,
    address to,
    uint256 id
  ) internal {
    // Underflow of the sender's balance is impossible because we check for
    // ownership above and the recipient's balance can't realistically overflow.
    ERC721Storage storage s = _loadERC721Slot();

    unchecked {
      s._balanceOf[from]--;

      s._balanceOf[to]++;
    }

    s._ownerOf[id] = to;

    delete s.getApproved[id];

    emit Transfer(from, to, id);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 id
  ) external virtual {
    transferFrom(from, to, id);

    require(
      to.code.length == 0 ||
        ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
        ERC721TokenReceiver.onERC721Received.selector,
      "UNSAFE_RECIPIENT"
    );
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    bytes calldata data
  ) external override(IERC721) {
    transferFrom(from, to, id);

    require(
      to.code.length == 0 ||
        ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
        ERC721TokenReceiver.onERC721Received.selector,
      "UNSAFE_RECIPIENT"
    );
  }

  /* //////////////////////////////////////////////////////////////
  ERC165 LOGIC
  ////////////////////////////////////////////////////////////// */

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    returns (bool)
  {
    return
      interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
      interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
      interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
  }

  /* //////////////////////////////////////////////////////////////
  INTERNAL MINT/BURN LOGIC
  ////////////////////////////////////////////////////////////// */

  function _mint(address to, uint256 id) internal virtual {
    require(to != address(0), "INVALID_RECIPIENT");
    ERC721Storage storage s = _loadERC721Slot();
    require(s._ownerOf[id] == address(0), "ALREADY_MINTED");

    // Counter overflow is incredibly unrealistic.
    unchecked {
      s._balanceOf[to]++;
    }

    s._ownerOf[id] = to;

    emit Transfer(address(0), to, id);
  }

  function _burn(uint256 id) internal virtual {
    ERC721Storage storage s = _loadERC721Slot();

    address owner = s._ownerOf[id];

    require(owner != address(0), "NOT_MINTED");

    // Ownership check above ensures no underflow.
    unchecked {
      s._balanceOf[owner]--;
    }

    delete s._ownerOf[id];

    delete s.getApproved[id];

    emit Transfer(owner, address(0), id);
  }

  /* //////////////////////////////////////////////////////////////
  INTERNAL SAFE MINT LOGIC
  ////////////////////////////////////////////////////////////// */

  function _safeMint(address to, uint256 id) internal virtual {
    _mint(to, id);

    require(
      to.code.length == 0 ||
        ERC721TokenReceiver(to).onERC721Received(
          msg.sender,
          address(0),
          id,
          ""
        ) ==
        ERC721TokenReceiver.onERC721Received.selector,
      "UNSAFE_RECIPIENT"
    );
  }

  function _safeMint(
    address to,
    uint256 id,
    bytes memory data
  ) internal virtual {
    _mint(to, id);

    require(
      to.code.length == 0 ||
        ERC721TokenReceiver(to).onERC721Received(
          msg.sender,
          address(0),
          id,
          data
        ) ==
        ERC721TokenReceiver.onERC721Received.selector,
      "UNSAFE_RECIPIENT"
    );
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