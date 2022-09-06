/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Strings {
  bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
  uint8 private constant _ADDRESS_LENGTH = 20;

  function toString(uint256 value) internal pure returns (string memory) {
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

  function toHexString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
      return "0x00";
    }
    uint256 temp = value;
    uint256 length = 0;
    while (temp != 0) {
      length++;
      temp >>= 8;
    }
    return toHexString(value, length);
  }

  function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
    bytes memory buffer = new bytes(2 * length + 2);
    buffer[0] = "0";
    buffer[1] = "x";
    for (uint256 i = 2 * length + 1; i > 1; --i) {
      buffer[i] = _HEX_SYMBOLS[value & 0xf];
      value >>= 4;
    }
    require(value == 0, "Strings: hex length insufficient");
    return string(buffer);
  }

  function toHexString(address addr) internal pure returns (string memory) {
    return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
  }
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    _transferOwnership(_msgSender());
  }

  modifier onlyOwner() {
    _checkOwner();
    _;
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  function _checkOwner() internal view virtual {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
  }

  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

library Counters {
  struct Counter {
    uint256 _value; // default: 0
  }

  function current(Counter storage counter) internal view returns (uint256) {
    return counter._value;
  }

  function increment(Counter storage counter) internal {
    unchecked {
      counter._value += 1;
    }
  }

  function decrement(Counter storage counter) internal {
    uint256 value = counter._value;
    require(value > 0, "Counter: decrement overflow");
    unchecked {
      counter._value = value - 1;
    }
  }

  function reset(Counter storage counter) internal {
    counter._value = 0;
  }
}

abstract contract Pausable is Context {
  event Paused(address account);
  event Unpaused(address account);
  bool private _paused;

  constructor() {
    _paused = false;
  }

  modifier whenNotPaused() {
    _requireNotPaused();
    _;
  }
  modifier whenPaused() {
    _requirePaused();
    _;
  }

  function paused() public view virtual returns (bool) {
    return _paused;
  }

  function _requireNotPaused() internal view virtual {
    require(!paused(), "Pausable: paused");
  }

  function _requirePaused() internal view virtual {
    require(paused(), "Pausable: not paused");
  }

  function _pause() internal virtual whenNotPaused {
    _paused = true;
    emit Paused(_msgSender());
  }

  function _unpause() internal virtual whenPaused {
    _paused = false;
    emit Unpaused(_msgSender());
  }
}

interface IERC165 {
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  function balanceOf(address owner) external view returns (uint256 balance);

  function ownerOf(uint256 tokenId) external view returns (address owner);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function approve(address to, uint256 tokenId) external;

  function setApprovalForAll(address operator, bool _approved) external;

  function getApproved(uint256 tokenId) external view returns (address operator);

  function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Receiver {
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);
}

interface IERC721Metadata is IERC721 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function tokenURI(uint256 tokenId) external view returns (string memory);
}

library Address {
  function isContract(address account) internal view returns (bool) {
    return account.code.length > 0;
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    (bool success, ) = recipient.call{value: amount}("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }

  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, "Address: low-level call failed");
  }

  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    require(isContract(target), "Address: call to non-contract");
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    return functionStaticCall(target, data, "Address: low-level static call failed");
  }

  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    require(isContract(target), "Address: static call to non-contract");

    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionDelegateCall(target, data, "Address: low-level delegate call failed");
  }

  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: delegate call to non-contract");

    (bool success, bytes memory returndata) = target.delegatecall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      if (returndata.length > 0) {
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
}

abstract contract ERC165 is IERC165 {
  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC165).interfaceId;
  }
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
  using Address for address;
  using Strings for uint256;
  string private _name;
  string private _symbol;
  mapping(uint256 => address) private _owners;
  mapping(address => uint256) private _balances;
  mapping(uint256 => address) private _tokenApprovals;
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Metadata).interfaceId || super.supportsInterface(interfaceId);
  }

  function balanceOf(address owner) public view virtual override returns (uint256) {
    require(owner != address(0), "ERC721: address zero is not a valid owner");
    return _balances[owner];
  }

  function ownerOf(uint256 tokenId) public view virtual override returns (address) {
    address owner = _owners[tokenId];
    require(owner != address(0), "ERC721: invalid token ID");
    return owner;
  }

  function name() public view virtual override returns (string memory) {
    return _name;
  }

  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    _requireMinted(tokenId);

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
  }

  function _baseURI() internal view virtual returns (string memory) {
    return "";
  }

  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ERC721.ownerOf(tokenId);
    require(to != owner, "ERC721: approval to current owner");

    require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "ERC721: approve caller is not token owner nor approved for all");

    _approve(to, tokenId);
  }

  function getApproved(uint256 tokenId) public view virtual override returns (address) {
    _requireMinted(tokenId);

    return _tokenApprovals[tokenId];
  }

  function setApprovalForAll(address operator, bool approved) public virtual override {
    _setApprovalForAll(_msgSender(), operator, approved);
  }

  function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    //solhint-disable-next-line max-line-length
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

    _transfer(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public virtual override {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
    _safeTransfer(from, to, tokenId, data);
  }

  function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) internal virtual {
    _transfer(from, to, tokenId);
    require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
  }

  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return _owners[tokenId] != address(0);
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
    address owner = ERC721.ownerOf(tokenId);
    return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
  }

  function _safeMint(address to, uint256 tokenId) internal virtual {
    _safeMint(to, tokenId, "");
  }

  function _safeMint(
    address to,
    uint256 tokenId,
    bytes memory data
  ) internal virtual {
    _mint(to, tokenId);
    require(_checkOnERC721Received(address(0), to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
  }

  function _mint(address to, uint256 tokenId) internal virtual {
    require(to != address(0), "ERC721: mint to the zero address");
    require(!_exists(tokenId), "ERC721: token already minted");

    _beforeTokenTransfer(address(0), to, tokenId);

    _balances[to] += 1;
    _owners[tokenId] = to;

    emit Transfer(address(0), to, tokenId);

    _afterTokenTransfer(address(0), to, tokenId);
  }

  function _burn(uint256 tokenId) internal virtual {
    address owner = ERC721.ownerOf(tokenId);
    _beforeTokenTransfer(owner, address(0), tokenId);
    _approve(address(0), tokenId);
    _balances[owner] -= 1;
    delete _owners[tokenId];
    emit Transfer(owner, address(0), tokenId);
    _afterTokenTransfer(owner, address(0), tokenId);
  }

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {
    require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
    require(to != address(0), "ERC721: transfer to the zero address");
    _beforeTokenTransfer(from, to, tokenId);
    _approve(address(0), tokenId);
    _balances[from] -= 1;
    _balances[to] += 1;
    _owners[tokenId] = to;

    emit Transfer(from, to, tokenId);

    _afterTokenTransfer(from, to, tokenId);
  }

  function _approve(address to, uint256 tokenId) internal virtual {
    _tokenApprovals[tokenId] = to;
    emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
  }

  function _setApprovalForAll(
    address owner,
    address operator,
    bool approved
  ) internal virtual {
    require(owner != operator, "ERC721: approve to caller");
    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  function _requireMinted(uint256 tokenId) internal view virtual {
    require(_exists(tokenId), "ERC721: invalid token ID");
  }

  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) private returns (bool) {
    if (to.isContract()) {
      try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
        return retval == IERC721Receiver.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721: transfer to non ERC721Receiver implementer");
        } else {
          /// @solidity memory-safe-assembly
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}
}

library MerkleProof {
  function verify(
    bytes32[] memory proof,
    bytes32 root,
    bytes32 leaf
  ) internal pure returns (bool) {
    return processProof(proof, leaf) == root;
  }

  function verifyCalldata(
    bytes32[] calldata proof,
    bytes32 root,
    bytes32 leaf
  ) internal pure returns (bool) {
    return processProofCalldata(proof, leaf) == root;
  }

  function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
    bytes32 computedHash = leaf;
    for (uint256 i = 0; i < proof.length; i++) {
      computedHash = _hashPair(computedHash, proof[i]);
    }
    return computedHash;
  }

  function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
    bytes32 computedHash = leaf;
    for (uint256 i = 0; i < proof.length; i++) {
      computedHash = _hashPair(computedHash, proof[i]);
    }
    return computedHash;
  }

  function multiProofVerify(
    bytes32[] memory proof,
    bool[] memory proofFlags,
    bytes32 root,
    bytes32[] memory leaves
  ) internal pure returns (bool) {
    return processMultiProof(proof, proofFlags, leaves) == root;
  }

  function multiProofVerifyCalldata(
    bytes32[] calldata proof,
    bool[] calldata proofFlags,
    bytes32 root,
    bytes32[] memory leaves
  ) internal pure returns (bool) {
    return processMultiProofCalldata(proof, proofFlags, leaves) == root;
  }

  function processMultiProof(
    bytes32[] memory proof,
    bool[] memory proofFlags,
    bytes32[] memory leaves
  ) internal pure returns (bytes32 merkleRoot) {
    uint256 leavesLen = leaves.length;
    uint256 totalHashes = proofFlags.length;
    require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

    bytes32[] memory hashes = new bytes32[](totalHashes);
    uint256 leafPos = 0;
    uint256 hashPos = 0;
    uint256 proofPos = 0;

    for (uint256 i = 0; i < totalHashes; i++) {
      bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
      bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
      hashes[i] = _hashPair(a, b);
    }

    if (totalHashes > 0) {
      return hashes[totalHashes - 1];
    } else if (leavesLen > 0) {
      return leaves[0];
    } else {
      return proof[0];
    }
  }

  function processMultiProofCalldata(
    bytes32[] calldata proof,
    bool[] calldata proofFlags,
    bytes32[] memory leaves
  ) internal pure returns (bytes32 merkleRoot) {
    uint256 leavesLen = leaves.length;
    uint256 totalHashes = proofFlags.length;

    require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

    bytes32[] memory hashes = new bytes32[](totalHashes);
    uint256 leafPos = 0;
    uint256 hashPos = 0;
    uint256 proofPos = 0;

    for (uint256 i = 0; i < totalHashes; i++) {
      bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
      bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
      hashes[i] = _hashPair(a, b);
    }

    if (totalHashes > 0) {
      return hashes[totalHashes - 1];
    } else if (leavesLen > 0) {
      return leaves[0];
    } else {
      return proof[0];
    }
  }

  function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
    return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
  }

  function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
    assembly {
      mstore(0x00, a)
      mstore(0x20, b)
      value := keccak256(0x00, 0x40)
    }
  }
}

abstract contract ERC721URIStorage is ERC721 {
  using Strings for uint256;

  mapping(uint256 => string) private _tokenURIs;

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    _requireMinted(tokenId);

    string memory _tokenURI = _tokenURIs[tokenId];
    string memory base = _baseURI();

    if (bytes(base).length == 0) {
      return _tokenURI;
    }
    if (bytes(_tokenURI).length > 0) {
      return string(abi.encodePacked(base, _tokenURI));
    }

    return super.tokenURI(tokenId);
  }

  function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
    require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
    _tokenURIs[tokenId] = _tokenURI;
  }

  function _burn(uint256 tokenId) internal virtual override {
    super._burn(tokenId);

    if (bytes(_tokenURIs[tokenId]).length != 0) {
      delete _tokenURIs[tokenId];
    }
  }
}

contract SeriesTwo is ERC721, ERC721URIStorage, Ownable, Pausable {
  using Counters for Counters.Counter;
  using Strings for uint256;

  string public baseURI;
  uint40 public preMintStart = 1661331600; // 2:00 PM Wednesday, Coordinated Universal Time (UTC)
  uint40 public preMintEnd = 1661418000; // 2:00 PM Thursday, Coordinated Universal Time (UTC)
  uint256 public mintLimit = 10000;
  bool public salePaused = false;
  IERC721 public seriesOne;

  bytes32 private _root;
  Counters.Counter public mintCount;
  mapping(address => uint256) private count;

  constructor() ERC721("Ethnology Series 2: Gods and Demons", "Gods and Demons S2") {
    setBaseURI("ipfs://QmSRgQkKJ8rWMJxuHDSzaq1fT6PGvBpdkKmpktFE7qJ3p4/");
    setSeriesOne(0xA8D6Ab1e26d90De9837f2828545a0357967F6251);
    setRoot(0x1dfbc8daa0d5622674cf94465236b6e03e631c0e4f9d43ceb8b582f395dad4eb);
  }

  function mintSale(uint256 amount, bytes32[] memory _proof) external {
    require(!salePaused, "Sale is paused");
    require(amount > 0, "Invalid amount");
    require(preMintStart < getCurrentTime(), "Minting Not Started Yet");
    require(mintCount.current() <= mintLimit, "Max Mint Limit Reached");
    if (preMintStart <= getCurrentTime() && preMintEnd > getCurrentTime()) {
      uint8 mintingLimit = checkLimit(msg.sender, _proof);
      require(mintingLimit > 0, "MINT NOT ALLOWED");
      require(count[msg.sender] + amount < mintingLimit, "Limit exceeded");
      for (uint256 _iter = 0; _iter < amount; ) {
        _mintSale();
        unchecked {
          _iter++;
        }
      }
    } else {
      require(count[msg.sender] < 1, "You reached Max Minting limit");
      _mintSale();
    }
  }

  function _mintSale() private {
    mintCount.increment();
    mint(msg.sender, mintCount.current());
    count[msg.sender] += 1;
  }

  function getCurrentTime() private view returns (uint256) {
    return block.timestamp;
  }

  function seriesOneBal(address _owner) internal view returns (uint256) {
    return seriesOne.balanceOf(_owner);
  }

  // The following functions are overrides required by Solidity.

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function isWhiteListed(
    bytes32[] memory _prof,
    bytes32 _rot,
    bytes32 _leaf
  ) public pure returns (bool) {
    return MerkleProof.verify(_prof, _rot, _leaf);
  }

  function switchSale() public onlyOwner {
    salePaused = !salePaused;
  }

  function setSeriesOne(address _seriesOne) public onlyOwner {
    seriesOne = IERC721(_seriesOne);
  }

  function setRoot(bytes32 root) public onlyOwner {
    _root = root;
  }

  function setMintTimeStart(uint40 _preMint, uint40 _mainMint) public onlyOwner {
    preMintStart = _preMint;
    preMintEnd = _mainMint;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function mint(address to, uint256 _tokenId) internal {
    _safeMint(to, _tokenId);
  }

  function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
    require(_exists(tokenId), "Querying Nonexistent token");

    string memory currentBaseURI = baseURI;
    return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
  }

  function getMarkleLeaf(address _user) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_user));
  }

  function checkLimit(address _user, bytes32[] memory _proof) public view returns (uint8) {
    return (seriesOneBal(_user) >= 1) ? 5 : (isWhiteListed(_proof, _root, getMarkleLeaf(_user))) ? 3 : 0;
  }
}