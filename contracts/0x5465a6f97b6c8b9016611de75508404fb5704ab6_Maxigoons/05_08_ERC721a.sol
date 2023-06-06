// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "./ERC721TokenReceiver.sol";

/// @notice Credits: https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol

/// @dev Note Assumes serials are sequentially minted starting at 1 (e.g. 1, 2, 3, 4...).
/// @dev Note Does not support burning tokens to address(0).

/// @author Modified from solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)

abstract contract ERC721a {
  /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

  event Transfer(address indexed from, address indexed to, uint256 indexed id);

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 indexed id
  );

  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

  string public name;

  string public symbol;

  function tokenURI(uint256 id) public view virtual returns (string memory);

  /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

  uint256 public totalSupply;

  mapping(address => uint256) public balanceOf;

  mapping(uint256 => address) public getApproved;

  mapping(address => mapping(address => bool)) public isApprovedForAll;

  mapping(uint256 => address) internal owners;

  /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  constructor(string memory _name, string memory _symbol) {
    name = _name;
    symbol = _symbol;
  }

  /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

  function setApprovalForAll(address operator, bool approved) public virtual {
    isApprovedForAll[msg.sender][operator] = approved;

    emit ApprovalForAll(msg.sender, operator, approved);
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
      "UNSAFE_RECIPIENT"
    );
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    bytes memory data
  ) public virtual {
    transferFrom(from, to, id);

    require(
      to.code.length == 0 ||
        ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
        ERC721TokenReceiver.onERC721Received.selector,
      "UNSAFE_RECIPIENT"
    );
  }

  /*///////////////////////////////////////////////////////////////
                              ERC721a LOGIC
    //////////////////////////////////////////////////////////////*/

  function ownerOf(uint256 id) public view returns (address) {
    return _ownerOf(id);
  }

  function approve(address spender, uint256 id) public {
    address owner = _ownerOf(id);

    require(
      msg.sender == owner || isApprovedForAll[owner][msg.sender],
      "NOT_AUTHORIZED"
    );

    getApproved[id] = spender;

    emit Approval(owner, spender, id);
  }

  function transferFrom(
    address from,
    address to,
    uint256 id
  ) public {
    address owner = _ownerOf(id);

    require(from == owner, "WRONG_FROM");

    require(to != address(0), "INVALID_RECIPIENT");

    require(
      msg.sender == from ||
        msg.sender == getApproved[id] ||
        isApprovedForAll[from][msg.sender],
      "NOT_AUTHORIZED"
    );

    // https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol#L395
    unchecked {
      balanceOf[from]--;

      balanceOf[to]++;
    }

    owners[id] = to;

    // https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol#L405
    if (id + 1 <= totalSupply && owners[id + 1] == address(0)) {
      owners[id + 1] = owner;
    }

    delete getApproved[id];

    emit Transfer(from, to, id);
  }

  function _safeMintBatch(address to, uint256 amount) internal {
    _safeMintBatch(to, amount, "");
  }

  function _safeMintBatch(
    address to,
    uint256 amount,
    bytes memory data
  ) internal {
    _mintBatch(to, amount, data, true);
  }

  function _mintBatch(address to, uint256 amount) internal {
    _mintBatch(to, amount, "", false);
  }

  function _mintBatch(
    address to,
    uint256 amount,
    bytes memory data
  ) internal {
    _mintBatch(to, amount, data, false);
  }

  function _mintBatch(
    address to,
    uint256 amount,
    bytes memory data,
    bool safe
  ) internal {
    require(to != address(0), "INVALID_RECIPIENT");

    unchecked {
      uint256 id = totalSupply + 1;

      totalSupply += amount;
      balanceOf[to] += amount;
      owners[id] = to;

      for (uint256 i = 0; i < amount; i++) {
        emit Transfer(address(0), to, id);

        if (safe) {
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

        id++;
      }
    }
  }

  function _ownerOf(uint256 id) internal view returns (address) {
    if (id > totalSupply) {
      return address(0);
    }

    unchecked {
      while (id > 0) {
        if (owners[id] != address(0)) {
          return owners[id];
        }

        id--;
      }
    }

    // Happens only when `id == 0`
    return address(0);
  }

  /// @notice Credits: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol#L15

  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT licence
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }

  /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

  function supportsInterface(bytes4 interfaceId)
    public
    pure
    virtual
    returns (bool)
  {
    return
      interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
      interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
      interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
  }
}